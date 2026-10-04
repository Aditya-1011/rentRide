import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/repositories/auth_repository.dart';

String loginLocation({String? returnTo}) => Uri(
  path: '/login',
  queryParameters: {if (returnTo != null) 'returnTo': returnTo},
).toString();

String? safeReturnTo(String? destination) {
  if (destination == null ||
      !destination.startsWith('/') ||
      destination.startsWith('//')) {
    return null;
  }
  final uri = Uri.tryParse(destination);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  return destination;
}

Future<void> continueAfterSignIn(
  BuildContext context,
  AuthRepository repository, {
  String? returnTo,
}) async {
  final requestedDestination = safeReturnTo(returnTo);
  const signInPaths = {
    '/login',
    '/phone',
    '/email',
    '/otp',
    '/verify-email',
    '/profile',
  };
  final destination =
      signInPaths.contains(Uri.tryParse(requestedDestination ?? '')?.path)
      ? null
      : requestedDestination;
  if (repository.currentEmail != null &&
      repository.currentPhoneNumber == null &&
      !repository.emailIsVerified &&
      !await repository.refreshEmailVerification().timeout(
        const Duration(seconds: 10),
      )) {
    if (context.mounted) context.go('/verify-email', extra: destination);
    return;
  }
  // A slow profile read must not leave a verified user on the OTP screen.
  final profileComplete = await profileCompleteForNavigation(repository);
  if (!profileComplete) {
    if (context.mounted) context.go('/profile', extra: destination);
    return;
  }
  if (context.mounted) context.go(destination ?? '/home');
}

/// Profile availability controls onboarding, never whether a verified session
/// remains signed in. Profile writes still enforce the server security rules.
Future<bool> profileCompleteForNavigation(AuthRepository repository) async {
  try {
    return await repository.isProfileComplete().timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
  } on FirebaseException {
    return false;
  }
}
