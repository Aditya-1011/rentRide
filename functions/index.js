'use strict';

const {randomInt, randomUUID, randomBytes, createHmac, timingSafeEqual} = require('node:crypto');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret, defineString, defineBoolean} = require('firebase-functions/params');

initializeApp();
const db = getFirestore('rentride');
const auth = getAuth();
const apiKey = defineSecret('BREVO_API_KEY');
const hashKey = defineSecret('OTP_HASH_KEY');
const emailSender = defineString('OTP_EMAIL_SENDER', {default: ''});
const smsSender = defineString('OTP_SMS_SENDER', {default: 'RentRide'});
// Activation requires a separate approval. Neither deployment nor credit purchase
// is performed by this code. Keep delivery off until the account is ready.
const deliveryEnabled = defineBoolean('OTP_DELIVERY_ENABLED', {default: false});
const smsEnabled = defineBoolean('OTP_SMS_ENABLED', {default: false});
const options = {
  region: 'asia-south1', secrets: [apiKey, hashKey], enforceAppCheck: true,
  maxInstances: 2, minInstances: 0, cpu: 'gcf_gen1', concurrency: 1,
  memory: '256MiB', timeoutSeconds: 60,
};
const DAY = 86400000;
const EXPIRY = 600000;
const RESEND = 60000;
// Conservative application caps, not billing caps. Requests and Firestore access
// can still incur hosting charges. The email cap leaves room in Brevo's free plan.
const dailyCaps = {email: 250, phone: 20};
const hmac = value => createHmac('sha256', hashKey.value()).update(JSON.stringify(value)).digest('hex');
const codeHash = (id, challenge, code) => hmac([
  id, challenge.channel, challenge.target, challenge.mode, challenge.uid, code,
]);

function targetFor(channel, value) {
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', 'Enter an email address or mobile number.');
  const target = value.trim();
  if (channel === 'email') {
    if (target.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(target)) {
      throw new HttpsError('invalid-argument', 'Enter a valid email address.');
    }
    return target.toLowerCase();
  }
  // The current app supports Indian mobile numbers. Expand only after sender
  // registration and pricing have been reviewed for each additional country.
  if (channel !== 'phone' || !/^\+91[6-9]\d{9}$/.test(target)) {
    throw new HttpsError('invalid-argument', 'Enter a valid Indian mobile number.');
  }
  return target;
}

async function activeSession(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const header = request.rawRequest.headers.authorization;
  if (typeof header !== 'string' || !header.startsWith('Bearer ')) {
    throw new HttpsError('unauthenticated', 'Sign in again.');
  }
  try {
    const token = await auth.verifyIdToken(header.slice(7), true);
    if (token.uid !== request.auth.uid) throw new Error('Session mismatch.');
  } catch (_) {
    throw new HttpsError('unauthenticated', 'Your session has expired. Sign in again.');
  }
}

async function signedInUser(request) {
  await activeSession(request);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in before connecting a sign-in method.');
  const user = await auth.getUser(request.auth.uid);
  if (user.disabled) throw new HttpsError('permission-denied', 'This account is unavailable.');
  // Linking requires a recent sign-in, not just a refreshed ID token.
  const authTime = request.auth.token.auth_time;
  if (!Number.isFinite(authTime) || Date.now() / 1000 - authTime > 300) {
    throw new HttpsError('failed-precondition', 'Sign in again before connecting a sign-in method.');
  }
  return user;
}

async function emailUser(request) {
  await activeSession(request);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const user = await auth.getUser(request.auth.uid);
  if (user.disabled || !user.email) throw new HttpsError('failed-precondition', 'An active email account is required.');
  return user;
}

async function lookup(channel, target) {
  try {
    return channel === 'email' ? await auth.getUserByEmail(target) : await auth.getUserByPhoneNumber(target);
  } catch (error) {
    if (error.code === 'auth/user-not-found') return null;
    throw error;
  }
}

function deliveryConfig(channel) {
  if (!deliveryEnabled.value()) throw new HttpsError('unavailable', 'Code delivery is not active yet. Please try again later.');
  if (hashKey.value().length < 32 || !apiKey.value()) throw new HttpsError('unavailable', 'Code delivery is not configured yet.');
  if (channel === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailSender.value())) {
    throw new HttpsError('unavailable', 'Email delivery is not configured yet.');
  }
  if (channel === 'phone') {
    if (!smsEnabled.value()) throw new HttpsError('unavailable', 'SMS verification is not active yet. Please use email.');
    if (!/^[A-Za-z][A-Za-z0-9]{0,10}$/.test(smsSender.value())) {
      throw new HttpsError('unavailable', 'SMS delivery is not configured yet.');
    }
  }
}

function rateUpdate(previous, now, limit, cooldown = 0) {
  const active = previous && now - previous.windowStart < DAY;
  const count = active ? previous.count : 0;
  if (count >= limit || (previous && now - previous.lastAt < cooldown)) {
    throw new HttpsError('resource-exhausted', 'Too many code requests. Please wait and try again later.');
  }
  return {count: count + 1, windowStart: active ? previous.windowStart : now,
    lastAt: now, expiresAt: Timestamp.fromMillis(now + 2 * DAY)};
}

async function reserveChallenge(request, challenge) {
  const now = Date.now();
  const id = randomUUID();
  const code = String(randomInt(0, 1000000)).padStart(6, '0');
  const targetKey = hmac(['target', challenge.channel, challenge.target]);
  const targetRef = db.collection('_otpRates').doc(targetKey);
  const ipRef = db.collection('_otpRates').doc(hmac(['send-ip', request.rawRequest.ip || 'unknown']));
  const globalRef = db.collection('_otpRates').doc(`global-${challenge.channel}`);
  const ref = db.collection('_otpChallenges').doc(id);
  const pointer = challenge.mode === 'emailVerify' ? db.collection('_emailOtp').doc(challenge.uid) : null;
  const data = {...challenge, targetKey, hash: codeHash(id, challenge, code), attempts: 0,
    state: 'sending', sentAt: now, expiresAt: Timestamp.fromMillis(now + EXPIRY)};
  await db.runTransaction(async tx => {
    const [targetDoc, ipDoc, globalDoc] = await Promise.all([tx.get(targetRef), tx.get(ipRef), tx.get(globalRef)]);
    tx.set(targetRef, {...rateUpdate(targetDoc.data(), now, 10, RESEND), latestChallenge: id});
    tx.set(ipRef, rateUpdate(ipDoc.data(), now, 30));
    tx.set(globalRef, rateUpdate(globalDoc.data(), now, dailyCaps[challenge.channel]));
    tx.set(ref, data);
    if (pointer) tx.set(pointer, {challengeId: id, expiresAt: data.expiresAt});
  });
  return {id, code, ref, data};
}

async function deliver(channel, target, code) {
  const text = `Your RentRide code is ${code}. It expires in 10 minutes. Do not share this code.`;
  const payload = channel === 'email' ? {
    sender: {name: 'RentRide', email: emailSender.value()}, to: [{email: target}],
    subject: 'Your RentRide sign-in code', textContent: text,
  } : {
    sender: smsSender.value(), recipient: target.slice(1), type: 'transactional',
    content: text, tag: 'rentride-otp', unicodeEnabled: false,
  };
  const path = channel === 'email' ? 'smtp/email' : 'transactionalSMS/send';
  // No automatic retry: a timeout may still mean a message was sent and billed.
  const response = await fetch(`https://api.brevo.com/v3/${path}`, {
    method: 'POST', signal: AbortSignal.timeout(20000),
    headers: {'api-key': apiKey.value(), 'Content-Type': 'application/json', accept: 'application/json'},
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    // Provider responses may include addresses or credential details; don't log them.
    throw new Error(`Brevo delivery rejected (${response.status}).`);
  }
}

async function sendChallenge(request, challenge) {
  deliveryConfig(challenge.channel);
  const reserved = await reserveChallenge(request, challenge);
  try {
    await deliver(challenge.channel, challenge.target, reserved.code);
    await reserved.ref.update({state: 'ready'});
  } catch (_) {
    await reserved.ref.update({state: 'failed'});
    throw new HttpsError('unavailable', 'We could not send your code. Wait a minute and try again.');
  }
  return {challengeId: reserved.id, expiresInSeconds: EXPIRY / 1000, resendAfterSeconds: RESEND / 1000};
}

async function consumeChallenge(request, id, code, expectedMode) {
  if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/.test(id) || typeof code !== 'string' || !/^\d{6}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'Enter the six-digit code.');
  }
  const now = Date.now();
  const ref = db.collection('_otpChallenges').doc(id);
  const ipRef = db.collection('_otpRates').doc(hmac(['verify-ip', request.rawRequest.ip || 'unknown']));
  const outcome = await db.runTransaction(async tx => {
    const [snapshot, ipDoc] = await Promise.all([tx.get(ref), tx.get(ipRef)]);
    const challenge = snapshot.data();
    const rateRef = challenge ? db.collection('_otpRates').doc(challenge.targetKey) : null;
    const latest = rateRef ? await tx.get(rateRef) : null;
    // All reads precede writes. Invalid guesses commit their counters too.
    tx.set(ipRef, rateUpdate(ipDoc.data(), now, 100));
    if (!challenge || challenge.expiresAt.toMillis() <= now || latest?.data()?.latestChallenge !== id) {
      return {error: 'That code has expired. Request a new one.'};
    }
    const modes = expectedMode === 'emailVerify' ? ['emailVerify'] : ['login', 'link'];
    if (!modes.includes(challenge.mode)) return {error: 'Request a new code for this sign-in method.'};
    if (challenge.uid && challenge.uid !== request.auth?.uid) return {error: 'Sign in to the account that requested this code.'};
    if (challenge.state !== 'ready') return {error: 'This code is unavailable or already used. Request a new one.'};
    if (challenge.attempts >= 5) return {error: 'Too many incorrect attempts. Request a new code.'};
    const valid = timingSafeEqual(Buffer.from(challenge.hash, 'hex'), Buffer.from(codeHash(id, challenge, code), 'hex'));
    if (!valid) {
      tx.update(ref, {attempts: challenge.attempts + 1});
      return {error: 'That code is incorrect. Check your messages and try again.'};
    }
    tx.update(ref, {state: 'consumed', consumedAt: Timestamp.now()});
    return {challenge};
  });
  if (outcome.error) throw new HttpsError('failed-precondition', outcome.error);
  return outcome.challenge;
}

async function finishIdentity(challenge, request) {
  const {channel, target, mode, uid} = challenge;
  let user;
  if (mode === 'link') {
    user = await signedInUser(request);
    if (user.uid !== uid) throw new HttpsError('permission-denied', 'Your account changed. Request a new code.');
    const existingValue = channel === 'email' ? user.email : user.phoneNumber;
    if (existingValue && existingValue.toLowerCase() !== target.toLowerCase()) {
      throw new HttpsError('failed-precondition', 'This account already has that sign-in method.');
    }
    const owner = await lookup(channel, target);
    if (owner && owner.uid !== uid) throw new HttpsError('already-exists', 'This sign-in method belongs to another account. Sign in to that account instead.');
  } else {
    user = await lookup(channel, target);
    if (!user) {
      try {
        user = await auth.createUser(channel === 'email' ? {email: target, emailVerified: true} : {phoneNumber: target});
      } catch (error) {
        if (!['auth/email-already-exists', 'auth/phone-number-already-exists'].includes(error.code)) throw error;
        user = await lookup(channel, target);
      }
    }
  }
  // Prevent an unverified password signup from retaining an attacker's password
  // after the actual email owner completes passwordless sign-in.
  if (mode === 'login' && channel === 'email' && user && !user.emailVerified) {
    if (user.phoneNumber || user.providerData.some(provider => provider.providerId !== 'password')) {
      throw new HttpsError('failed-precondition', 'Verify this email from the account it is connected to, or contact support.');
    }
    await auth.updateUser(user.uid, {password: randomBytes(32).toString('base64url')});
    await auth.revokeRefreshTokens(user.uid);
  }
  if (!user || user.disabled) throw new HttpsError('permission-denied', 'This account is unavailable.');
  try {
    user = await auth.updateUser(user.uid, channel === 'email' ? {email: target, emailVerified: true} : {phoneNumber: target});
  } catch (error) {
    if (['auth/email-already-exists', 'auth/phone-number-already-exists'].includes(error.code)) {
      throw new HttpsError('already-exists', 'This sign-in method belongs to another account.');
    }
    throw error;
  }
  if (mode === 'link') return {linked: true};
  // Never accept a uid from the client. Firebase's server-created ID token will
  // include the verified email/phone fields used by the existing profile rules.
  return {customToken: await auth.createCustomToken(user.uid)};
}

exports.sendLoginCode = onCall(options, async request => {
  const channel = request.data?.channel;
  if (!['email', 'phone'].includes(channel)) throw new HttpsError('invalid-argument', 'Choose email or phone.');
  const target = targetFor(channel, request.data?.target);
  const link = request.data?.linkToCurrentAccount === true;
  const user = link ? await signedInUser(request) : null;
  return sendChallenge(request, {channel, target, mode: link ? 'link' : 'login', uid: user?.uid || null});
});

exports.verifyLoginCode = onCall(options, async request => {
  const challenge = await consumeChallenge(request, request.data?.challengeId, request.data?.code);
  if (!['login', 'link'].includes(challenge.mode)) throw new HttpsError('invalid-argument', 'Request a new sign-in code.');
  return finishIdentity(challenge, request);
});

// Preserve the existing password signup/linked-email verification flow.
exports.sendEmailCode = onCall(options, async request => {
  const user = await emailUser(request);
  if (user.emailVerified) return {verified: true};
  return sendChallenge(request, {channel: 'email', target: targetFor('email', user.email), mode: 'emailVerify', uid: user.uid});
});

exports.verifyEmailCode = onCall(options, async request => {
  const user = await emailUser(request);
  const pointer = await db.collection('_emailOtp').doc(user.uid).get();
  const challenge = await consumeChallenge(request, pointer.data()?.challengeId, request.data?.code, 'emailVerify');
  const current = await auth.getUser(user.uid);
  if (current.disabled || current.email?.toLowerCase() !== challenge.target) {
    throw new HttpsError('failed-precondition', 'Your email changed. Request a new code.');
  }
  await auth.updateUser(user.uid, {emailVerified: true});
  return {verified: true};
});
