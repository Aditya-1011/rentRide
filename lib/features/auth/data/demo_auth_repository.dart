import 'dart:async';

import '../domain/repositories/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get sessionChanges => _changes.stream;

  @override
  void cancelPendingPhoneVerification() {
    _pendingPhone = null;
  }

  @override
  bool get hasVerifiedIdentity => _verified;

  @override
  bool get emailIsVerified => _email != null && _verified;

  String? _phoneNumber;
  String? _pendingPhone;
  bool _phoneLinking = false;
  String? _email;
  String? _pendingEmail;
  bool _emailLinking = false;
  bool _verified = false;
  bool _profileComplete = false;

  @override
  String? get currentEmail => _email;

  @override
  String? get currentPhoneNumber => _phoneNumber;

  @override
  Future<String> sendOtp(
    String phoneNumber, {
    bool linkToCurrentAccount = false,
  }) async {
    if (linkToCurrentAccount && !_verified) throw StateError('Sign in first.');
    _pendingPhone = phoneNumber;
    _phoneLinking = linkToCurrentAccount;
    return 'demo-code';
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    bool linkToCurrentAccount = false,
  }) async {
    if (_pendingPhone == null ||
        verificationId != 'demo-code' ||
        linkToCurrentAccount != _phoneLinking) {
      throw const FormatException('Please request a new verification code.');
    }
    if (smsCode != '123456') {
      throw const FormatException(
        'That code is incorrect. Try 123456 in demo mode.',
      );
    }
    if (!linkToCurrentAccount) {
      _email = null;
      _profileComplete = false;
    }
    _phoneNumber = _pendingPhone;
    _pendingPhone = null;
    _verified = true;
    _changes.add(null);
  }

  @override
  Future<String> sendEmailLoginOtp(
    String email, {
    bool linkToCurrentAccount = false,
  }) async {
    if (linkToCurrentAccount && !_verified) throw StateError('Sign in first.');
    _pendingEmail = email.trim().toLowerCase();
    _emailLinking = linkToCurrentAccount;
    return 'demo-email-code';
  }

  @override
  Future<void> verifyEmailLoginOtp({
    required String challengeId,
    required String code,
    bool linkToCurrentAccount = false,
  }) async {
    if (_pendingEmail == null ||
        challengeId != 'demo-email-code' ||
        linkToCurrentAccount != _emailLinking) {
      throw const FormatException('Request a new email code.');
    }
    if (code != '123456') {
      throw const FormatException(
        'That code is incorrect. Try 123456 in demo mode.',
      );
    }
    if (!linkToCurrentAccount) {
      _phoneNumber = null;
      _profileComplete = false;
    }
    _email = _pendingEmail;
    _pendingEmail = null;
    _verified = true;
    _changes.add(null);
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) => _emailUnavailable();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _emailUnavailable();

  @override
  Future<void> sendPasswordReset(String email) => _emailUnavailable();

  @override
  Future<void> sendEmailVerification() => _emailUnavailable();

  @override
  Future<bool> refreshEmailVerification() async => emailIsVerified;

  @override
  Future<void> verifyEmailCode(String code) => _emailUnavailable();

  @override
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) => _emailUnavailable();

  Future<T> _emailUnavailable<T>() => Future<T>.error(
    StateError(
      'Email authentication is available after connecting your Firebase project. Demo mode simulates OTP sign-in without creating a Firebase account.',
    ),
  );

  @override
  Future<bool> isSignedIn() async => _verified;

  @override
  Future<bool> isProfileComplete() async => _profileComplete;

  @override
  Future<void> saveProfile({required String displayName}) async {
    if (!_verified) {
      throw StateError(
        'Verify your email or phone before saving your profile.',
      );
    }
    _profileComplete = true;
  }

  @override
  Future<void> signOut() async {
    _phoneNumber = null;
    _email = null;
    _pendingPhone = null;
    _pendingEmail = null;
    _verified = false;
    _profileComplete = false;
    _changes.add(null);
  }
}
