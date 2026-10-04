class AppConfig {
  AppConfig._();

  static const firestoreDatabaseId = 'rentride';
  static const functionsRegion = 'asia-south1';

  /// The approved email OTP backend is deployed and App Check is configured.
  static const otpBackendReady = bool.fromEnvironment(
    'OTP_BACKEND_READY',
    defaultValue: true,
  );

  /// Live Firebase is the default. Use USE_FIREBASE_AUTH=false for demo UI.
  static const useFirebaseAuth = bool.fromEnvironment(
    'USE_FIREBASE_AUTH',
    defaultValue: true,
  );
}
