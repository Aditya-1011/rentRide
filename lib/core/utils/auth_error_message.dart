import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'billing-not-enabled' => 'SMS is unavailable until billing is activated.',
      'app-not-authorized' ||
      'invalid-app-credential' ||
      'missing-client-identifier' =>
        'Phone verification is not configured for this app build yet.',
      'captcha-check-failed' => 'The security check failed. Please try again.',
      'configuration-not-found' => 'Authentication setup is not active yet.',
      'invalid-phone-number' =>
        'Enter a valid Indian mobile number and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a little and try again.',
      'quota-exceeded' =>
        'SMS verification is temporarily unavailable. Try again later.',
      'invalid-verification-code' =>
        'That code is incorrect. Check the SMS and try again.',
      'session-expired' =>
        'That code has expired. Request a new one to continue.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'invalid-email' => 'Enter a valid email address.',
      'email-already-in-use' =>
        'This email is already connected to an account. Sign in to that account instead.',
      'credential-already-in-use' =>
        'This sign-in method belongs to another account. Sign in to that account; RentRide will not merge accounts automatically.',
      'weak-password' =>
        'Choose a stronger password with at least 6 characters.',
      'user-not-found' => 'We could not find an account with those details.',
      'wrong-password' => 'That password is incorrect. Try again or reset it.',
      'invalid-credential' =>
        'Those sign-in details are not correct. Try again.',
      'user-disabled' => 'This account is disabled. Contact RentRide support.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase yet.',
      'provider-already-linked' =>
        'That sign-in method is already connected to this account.',
      'requires-recent-login' =>
        'Sign in again before changing this account setting.',
      _ =>
        error.message ??
            'We could not complete phone verification. Please try again.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'We could not access your profile. Please sign in again.',
      'unavailable' ||
      'deadline-exceeded' => 'Check your internet connection and try again.',
      _ => 'We could not save or load your profile. Please try again.',
    };
  }
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message;
  return 'Something went wrong. Please try again.';
}
