import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:dio/dio.dart';

import '../domain/repositories/auth_repository.dart';
import '../../../core/config/app_config.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: (auth ?? FirebaseAuth.instance).app,
            databaseId: AppConfig.firestoreDatabaseId,
          );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  int _phoneRequest = 0;

  @override
  Stream<void> get sessionChanges => _auth.userChanges().map((_) {});

  @override
  void cancelPendingPhoneVerification() => _phoneRequest++;

  @override
  bool get emailIsVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  bool get hasVerifiedIdentity {
    final user = _auth.currentUser;
    return user != null && (user.phoneNumber != null || user.emailVerified);
  }

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentPhoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Future<String> sendOtp(
    String phoneNumber, {
    bool linkToCurrentAccount = false,
  }) async {
    final request = ++_phoneRequest;
    final id = await _sendLoginCode(
      'phone',
      phoneNumber,
      linkToCurrentAccount: linkToCurrentAccount,
    );
    if (request != _phoneRequest) {
      throw StateError('This request was cancelled. Request a new code.');
    }
    return id;
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    bool linkToCurrentAccount = false,
  }) => _verifyLoginCode(verificationId, smsCode, linkToCurrentAccount);

  @override
  Future<String> sendEmailLoginOtp(
    String email, {
    bool linkToCurrentAccount = false,
  }) => _sendLoginCode(
    'email',
    email.trim(),
    linkToCurrentAccount: linkToCurrentAccount,
  );

  @override
  Future<void> verifyEmailLoginOtp({
    required String challengeId,
    required String code,
    bool linkToCurrentAccount = false,
  }) => _verifyLoginCode(challengeId, code, linkToCurrentAccount);

  Future<String> _sendLoginCode(
    String channel,
    String target, {
    required bool linkToCurrentAccount,
  }) async {
    if (linkToCurrentAccount && _auth.currentUser == null) {
      throw StateError('Sign in before connecting a sign-in method.');
    }
    final response = await _otpFunction('sendLoginCode', {
      'channel': channel,
      'target': target,
      'linkToCurrentAccount': linkToCurrentAccount,
    });
    final id = response['challengeId'];
    if (id is! String || id.isEmpty) {
      throw StateError('We could not request your code. Please try again.');
    }
    return id;
  }

  Future<void> _verifyLoginCode(String id, String code, bool linking) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const FormatException('Enter the six-digit code.');
    }
    final request = _phoneRequest;
    final accountUid = _auth.currentUser?.uid;
    final response = await _otpFunction('verifyLoginCode', {
      'challengeId': id,
      'code': code,
    });
    if (request != _phoneRequest) {
      throw StateError('This request was cancelled. Request a new code.');
    }
    if (linking) {
      if (accountUid == null ||
          _auth.currentUser?.uid != accountUid ||
          response['linked'] != true) {
        throw StateError(
          'Your account changed. Sign in and request a new code.',
        );
      }
      await _auth.currentUser?.reload();
      await _auth.currentUser?.getIdToken(true);
      await _syncPhoneNumber();
      return;
    }
    final token = response['customToken'];
    if (token is! String || token.isEmpty) {
      throw StateError('We could not sign you in. Request a new code.');
    }
    // Custom-token sign-in already returns a fresh user and ID token.
    // Waiting for additional reload/refresh calls here can stall navigation.
    await _auth
        .signInWithCustomToken(token)
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Sign in with an email address first.');
    }
    await _otpFunction('sendEmailCode', {});
  }

  Future<Map<String, dynamic>> _otpFunction(
    String name,
    Map<String, Object?> data,
  ) async {
    if (!AppConfig.otpBackendReady) {
      throw StateError('Sign-in is not available yet. Please try again later.');
    }
    final token = await _auth.currentUser?.getIdToken();
    String? appCheckToken;
    try {
      appCheckToken = await FirebaseAppCheck.instance.getToken();
    } catch (_) {
      throw StateError('We could not verify this device. Please try again.');
    }
    if (appCheckToken == null || appCheckToken.isEmpty) {
      throw StateError('We could not verify this device. Please try again.');
    }
    final project = _auth.app.options.projectId;
    try {
      final response =
          await Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          ).post(
            'https://${AppConfig.functionsRegion}-$project.cloudfunctions.net/$name',
            data: {'data': data},
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
                'X-Firebase-AppCheck': appCheckToken,
              },
            ),
          );
      final body = response.data;
      final result = body is Map ? body['result'] ?? body['data'] : null;
      if (result is Map) return Map<String, dynamic>.from(result);
      throw StateError(
        'We could not complete verification. Request a new code.',
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      final detail = body is Map ? body['error'] : null;
      throw StateError(
        detail is Map && detail['message'] is String
            ? detail['message'] as String
            : 'Verification is unavailable. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> verifyEmailCode(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const FormatException('Enter the six-digit email code.');
    }
    await _otpFunction('verifyEmailCode', {'code': code});
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) await _auth.currentUser?.getIdToken(true);
    return verified;
  }

  @override
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before connecting an email.');
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.linkWithCredential(credential);
  }

  @override
  Future<bool> isSignedIn() async => _auth.currentUser != null;

  @override
  Future<bool> isProfileComplete() async {
    final user = _auth.currentUser;
    if (user == null || !hasVerifiedIdentity) return false;
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data()?['onboardingCompleted'] == true &&
        (snapshot.data()?['displayName'] as String?)?.trim().isNotEmpty == true;
  }

  @override
  Future<void> saveProfile({required String displayName}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before saving your profile.');

    if (user.email != null && user.phoneNumber == null && !user.emailVerified) {
      throw StateError('Verify your email before saving your profile.');
    }
    final reference = _firestore.collection('users').doc(user.uid);
    final existing = await reference.get();
    final existingRoles = existing.data()?['roles'];
    final roles = existingRoles is List
        ? existingRoles.whereType<String>().toSet().toList()
        : <String>[];
    if (roles.isEmpty) roles.add('customer');

    final name = displayName.trim();
    if (name.length < 2 || name.length > 60) {
      throw const FormatException('Enter a name between 2 and 60 characters.');
    }
    await user.updateDisplayName(name);
    final profile = <String, Object?>{
      'uid': user.uid,
      'phoneNumber': user.phoneNumber,
      'displayName': name,
      'roles': roles,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) profile['createdAt'] = FieldValue.serverTimestamp();
    await reference.set(profile, SetOptions(merge: true));
  }

  Future<void> _syncPhoneNumber() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final reference = _firestore.collection('users').doc(user.uid);
    final profile = await reference.get();
    if (!profile.exists) return;
    await reference.update({
      'phoneNumber': user.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> signOut() {
    _phoneRequest++;
    return _auth.signOut();
  }
}
