abstract interface class AuthRepository {
  Stream<void> get sessionChanges;

  void cancelPendingPhoneVerification();

  bool get hasVerifiedIdentity;

  bool get emailIsVerified;

  Future<String> sendOtp(
    String phoneNumber, {
    bool linkToCurrentAccount = false,
  });

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    bool linkToCurrentAccount = false,
  });

  Future<String> sendEmailLoginOtp(
    String email, {
    bool linkToCurrentAccount = false,
  });

  Future<void> verifyEmailLoginOtp({
    required String challengeId,
    required String code,
    bool linkToCurrentAccount = false,
  });

  Future<void> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> sendEmailVerification();

  Future<bool> refreshEmailVerification();

  Future<void> verifyEmailCode(String code);

  Future<void> linkEmailPassword({
    required String email,
    required String password,
  });

  Future<bool> isSignedIn();

  Future<bool> isProfileComplete();

  String? get currentEmail;

  String? get currentPhoneNumber;

  Future<void> saveProfile({required String displayName});

  Future<void> signOut();
}
