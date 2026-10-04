# Brevo email and mobile OTP

Prepared 2026-10-04 for Firebase project `rental-app-ad355`.

## What is implemented

- Passwordless six-digit email OTP signup/sign-in.
- Six-digit mobile SMS OTP signup/sign-in for Indian numbers (`+91`).
- Explicit email/phone linking from Account security, preserving the same Firebase UID.
- Firebase custom-token sessions, persisted by the Firebase SDK; profile setup, protected destinations, and sign-out continue to use Firebase.
- Existing email/password repository methods and numeric verification endpoints remain compatible with older accounts. The primary email screen now uses OTP, without a password.
- An isolated in-memory demo for both OTP channels. It never sends messages, creates cloud users, or writes Firestore.

Brevo delivers messages. The backend generates and verifies codes, resolves users, and creates Firebase custom tokens. Flutter never contains the Brevo key or the OTP signing key. It does not call Brevo directly or request Firebase SMS.

## Current activation state

On 2026-10-04, the user approved computer IP authorization and Firebase email deployment. The computer IP was authorized in Brevo. Both backend secrets are stored in Firebase Secret Manager, all four callable functions are ACTIVE in Mumbai, the runtime has signing permission on its own service account, and the emulator App Check debug token is registered and exchanges successfully. Deployment image cleanup is configured after one day. The first live email request failed because Brevo blocked the Google Cloud outgoing IP `2600:1900:0:3900::a01`; delivery and end-to-end sign-in are not verified. A separate confirmation for the cloud IP/security setting is pending. No SMS credits were purchased; SMS remains disabled.

Activation switches (Flutter default remains off until live delivery is resolved):

| Setting | Default | Purpose |
| --- | --- | --- |
| Flutter `OTP_BACKEND_READY` | `false` | Stops calls to the prepared backend until deployment is ready |
| Server `OTP_DELIVERY_ENABLED` | `true` in deployed email configuration | Email delivery permitted; currently blocked by Brevo IP policy |
| Server `OTP_SMS_ENABLED` | `false` | Separately stops paid SMS delivery |

`USE_FIREBASE_AUTH` remains true by default. With the backend switch off, the app opens normally and reports that sign-in is unavailable when a code is requested.

## Preview without charges

From the project root:

```sh
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_AUTH=false
```

Use code **123456** for either email or phone in this explicit demo mode. The OTP screen labels the demo code. Profiles and sessions last only for the current demo process. Do not use this mode to claim real verification or ship a production build.

## Costs and approval boundary

Brevo's free plan currently includes 300 email sends/day. SMS credits are sold separately. Firebase Cloud Functions, Firestore operations, Secret Manager, and deployment artifacts can incur charges even when email delivery is within Brevo's free allowance. This implementation prepares the existing Firebase Functions backend; it is not a promise of free hosting.

The application caps sends at 250 email requests and 20 SMS requests per rolling 24-hour window per channel, with 10 requests per destination and 30 per IP. Failed delivery attempts count toward the caps. Other applications using the same Brevo account can consume its email allowance. These limits restrict this code's sends, not total cloud billing or account-wide spending. Firebase budget alerts do not enforce a spending stop.

Before live setup, obtain the user's approval for:

1. The backend host and its potential charges. The prepared host is Firebase Cloud Functions in Mumbai.
2. Brevo SMS credit purchase and the intended amount. Do not buy credits automatically.
3. The first real email/SMS delivery checks, including their destination and possible cost.
4. Production activation and deployment.

Email can be activated first while `OTP_SMS_ENABLED=false`.

## Brevo account preparation (after approval)

1. Use an account owned by the user and select the Free email plan unless a paid plan is separately approved.
2. Verify the sending email address/domain in Brevo. Complete the domain authentication requested by Brevo.
3. Create a Brevo API key. Enter it only into a hidden local/Secret Manager input, never into chat, Flutter, or Git.
4. For SMS, confirm the account is allowed to deliver authentication messages to Indian numbers and register the appropriate sender. Brevo's current documentation requires sender registration for new accounts; approval and carrier requirements can delay activation. Confirm any India-specific template/header requirements with Brevo before buying credits.
5. `OTP_SMS_SENDER` must match the approved sender. The placeholder `RentRide` is not evidence of registration. The current backend accepts an alphanumeric sender up to 11 characters and restricts recipients to Indian mobile numbers.

## Firebase preparation (after approval)

Keep project `rental-app-ad355`, database `rentride`, and region `asia-south1`. Confirm that Firebase Authentication is initialized and custom-token sign-in is available. Brevo-based phone login does not require enabling Firebase's SMS provider. Enable Email/Password only if keeping legacy password-based account access.

The runtime service account needs access to Firebase Authentication users and the existing Firestore database. Custom-token signing requires the IAM Service Account Credentials API and signing permissions; Firebase Admin may need `iam.serviceAccounts.signBlob`. Grant `roles/iam.serviceAccountTokenCreator` on the signing service account to the actual function runtime identity when needed, not broadly at project level. Inspect the deployed runtime service account instead of guessing its identity. Do not download a service-account private key for the app.

Existing Firestore rules deny all client access to `_otpChallenges`, `_otpRates`, and `_emailOtp`. User profiles remain private to their verified Firebase owner. The code uses no new client-accessible OTP collections.

## Secure local preparation (no deployment)

On 2026-10-04, the user approved computer IP authorization and Firebase email deployment. The computer IP was authorized in Brevo. Both backend secrets are stored in Firebase Secret Manager, all four callable functions are ACTIVE in Mumbai, the runtime has signing permission on its own service account, and the emulator App Check debug token is registered and exchanges successfully. Deployment image cleanup is configured after one day. The first live email request failed because Brevo blocked the Google Cloud outgoing IP `2600:1900:0:3900::a01`; delivery and end-to-end sign-in are not verified. A separate confirmation for the cloud IP/security setting is pending. No SMS credits were purchased; SMS remains disabled. Sender `adityarawat946@gmail.com` is Verified in the Brevo dashboard and transactional relay is enabled. Account API access succeeded, while sender-list API access returned HTTP 403; sender verification was confirmed through the signed-in dashboard. Local credentials are saved with owner-only permissions.

In your own Android Studio or macOS terminal, from the project root, run:

```sh
python3 scripts/configure_brevo.py
```

Enter the verified sender email and paste the API key only at the hidden prompt. The helper reads Brevo's account and sender endpoints, confirms the email is active, and saves the key and a random OTP signing secret in Git-ignored `functions/.secret.local` with owner-only permissions. It writes sender configuration to Git-ignored `functions/.env.rental-app-ad355`, keeping delivery and SMS off. It never sends messages, creates cloud resources, purchases credits, or deploys. Do not share either local configuration file. The local secret file is for local emulator/setup preparation only; it is not automatically a production Secret Manager secret.

To report sanitized local status:

```sh
python3 scripts/configure_brevo.py --status
# Optionally repeat read-only provider checks:
python3 scripts/configure_brevo.py --status --check
```

Cloud Secret Manager upload and deployment remain separate steps requiring approval.

## Secrets and server settings (after approval)

The backend is Node 22. Install its dependencies with Node 22 in `functions` using `npm ci`. Node 20/24 on a development machine can perform syntax checks, but deployment uses the configured Node 22 runtime.

From the root, these commands write cloud secrets and must wait for approval:

```sh
firebase functions:secrets:set BREVO_API_KEY --project rental-app-ad355
firebase functions:secrets:set OTP_HASH_KEY --project rental-app-ad355
```

Use the hidden prompts. `OTP_HASH_KEY` must be a randomly generated secret of at least 32 characters. Keep it stable across function instances. Rotating it invalidates outstanding OTPs and resets the derived rate-limit identifiers, so rotate only with a controlled rollout. Never print or commit either secret.

Copy `functions/.env.example` to the Git-ignored `functions/.env.rental-app-ad355`, replace the sender with the verified email, and keep both activation flags false until approved:

```dotenv
OTP_EMAIL_SENDER=your-verified-sender@example.com
OTP_SMS_SENDER=YourSender
OTP_DELIVERY_ENABLED=false
OTP_SMS_ENABLED=false
```

Firebase binds `BREVO_API_KEY` and `OTP_HASH_KEY` from Secret Manager. Do not put those secrets in the dotenv file. `.secret.local` is also ignored, but local emulator secrets must not be committed.

## App Check

All four callable endpoints enforce App Check. Flutter includes the token in the `X-Firebase-AppCheck` header even before user sign-in.

- Register Android App Check with Play Integrity and the proper SHA-256/release signing configuration.
- For emulator/debug builds, the code selects the debug provider. Register its debug token in Firebase App Check using the local console/log flow. Treat that token as a secret; do not post it in chat or commit it.
- Release builds use Play Integrity on Android and App Attest with DeviceCheck fallback on Apple platforms. Apple App Check entitlement/platform setup still requires verification on a physical device.
- Do not disable server enforcement just to make an unregistered emulator work.

## Approved deployment and activation

Only after the user's final approval and the preceding setup:

```sh
firebase deploy --only functions:authentication --project rental-app-ad355
```

The exports are `sendLoginCode`, `verifyLoginCode`, `sendEmailCode`, and `verifyEmailCode`. All run in `asia-south1`. Start with delivery disabled; when the sender/account is ready and activation is approved, set `OTP_DELIVERY_ENABLED=true`, leave SMS off until its purchase/sender approval, and redeploy. Deploying or activating functions may incur cloud costs. No deployment command has been run as part of preparing this code.

Run the connected client only after deployment and App Check registration:

```sh
flutter run -d emulator-5554 --dart-define=OTP_BACKEND_READY=true
```

For Android Studio, add `--dart-define=OTP_BACKEND_READY=true` to the main.dart Flutter run configuration's additional arguments after activation. For releases, pass the same define to the build command. Never pass provider keys as Dart defines.

## API contract

All endpoints use Firebase callable JSON framing (`{"data": {...}}`). Firebase validates the App Check and optional Firebase ID token headers.

| Endpoint | Request | Result |
| --- | --- | --- |
| `sendLoginCode` | `channel: email/phone`, `target`, optional `linkToCurrentAccount: true` | opaque `challengeId`, expiry and resend seconds |
| `verifyLoginCode` | `challengeId`, six-digit `code` | `customToken` for login, or `linked: true` for authenticated linking |
| `sendEmailCode` | signed-in user, empty data | challenge metadata for legacy email verification |
| `verifyEmailCode` | signed-in user, `code` | `verified: true` |

A new user is created only after a valid login code. Linking requires a Firebase session with a sign-in in the last five minutes and binds the challenge to that UID. A credential owned by another user is rejected; accounts are not merged. An unverified password-only email account has its old password randomized and refresh tokens revoked before passwordless verification, preventing a pre-created account's password from retaining access. Unverified email accounts with another connected provider require verification from that account or support, rather than automatic takeover.

## Security and failure behavior

Codes are randomly generated, HMAC hashed, single-use, expire after 10 minutes, and allow five incorrect guesses. Resends require 60 seconds and invalidate earlier challenges for the same destination. All counters and challenge consumption use Firestore transactions. App Check and per-IP limits protect public pre-login requests. No plaintext OTPs or provider keys are logged or returned to the app.

Brevo API acceptance is not confirmation of delivery. No automatic provider retry is performed, since a timed-out send may already have been accepted and billed. A failed identity update/token signing after code consumption requires requesting a new code. Failed sends also leave the destination cooldown in place.

Expiry is enforced in the verifier. Old challenge/rate documents are not automatically deleted yet. Before production, approve and configure Firestore TTL for `expiresAt` in `_otpChallenges`, `_otpRates`, and `_emailOtp`, or another controlled cleanup method. TTL deletions may incur charges; they are not enabled by this implementation.

## Validation scope

Dart analysis passed with no issues, JavaScript syntax checks passed, and the updated Android debug APK compiled successfully (103 seconds). These checks cover the prepared source. They do not prove live Brevo delivery, Firebase custom-token signing, App Check registration, cloud account creation, profile writes, or iOS behavior. End-to-end checks require the approved cloud setup and delivery authorization.

## Official references

- [Brevo transactional email API](https://developers.brevo.com/reference/send-transac-email)
- [Brevo transactional SMS API](https://developers.brevo.com/docs/transactional-sms-endpoints)
- [Brevo sender registration](https://help.brevo.com/hc/en-us/articles/28255350696466-Register-a-Sender-ID-to-send-SMS-messages)
- [Brevo email plan and separate SMS credits](https://www.brevo.com/products/transactional-email/)
- [Firebase custom tokens](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Flutter App Check](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [Firebase pricing](https://firebase.google.com/pricing)

## Email delivery activation (2026-10-04)

The user disabled Brevo API IP blocking; SMTP IP blocking remains active. The deployed backend accepted a live email OTP request to the user's verified sender address. Brevo API acceptance confirms submission, not inbox delivery. Flutter OTP_BACKEND_READY now defaults true so normal app runs use the deployed backend. The local Pixel 6 App Check debug token is registered. End-to-end code verification and sign-in still await entering the delivered code through the app. SMS remains disabled with zero credits. This status supersedes earlier pending cloud-IP and client-disabled notes.
