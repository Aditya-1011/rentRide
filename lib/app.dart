import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_navigation.dart';
import 'features/auth/presentation/auth_route_extra_codec.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/otp_route_args.dart';
import 'features/auth/presentation/screens/account_security_screen.dart';
import 'features/auth/presentation/screens/email_login_screen.dart';
import 'features/auth/presentation/screens/email_verification_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/phone_login_screen.dart';
import 'features/auth/presentation/screens/profile_setup_screen.dart';
import 'features/home/presentation/screens/explore_screen.dart';
import 'features/home/presentation/screens/protected_action_screen.dart';
import 'features/home/presentation/screens/setup_complete_screen.dart';

class RentRideApp extends ConsumerStatefulWidget {
  const RentRideApp({this.initialLocation = '/onboarding', super.key});

  final String initialLocation;

  @override
  ConsumerState<RentRideApp> createState() => _RentRideAppState();
}

class _RentRideAppState extends ConsumerState<RentRideApp> {
  late final AuthRepository _repository = ref.read(authRepositoryProvider);
  late final _SessionRefresh _sessionRefresh = _SessionRefresh(
    _repository.sessionChanges,
  );
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    extraCodec: const AuthRouteExtraCodec(),
    refreshListenable: _sessionRefresh,
    redirect: (context, state) async {
      final path = state.uri.path;
      const protected = {
        '/profile',
        '/home',
        '/account/security',
        '/phone-link',
        '/email-link',
        '/booking',
        '/list-vehicle',
      };
      const loginPages = {
        '/login',
        '/phone',
        '/email',
        '/otp',
        '/verify-email',
      };
      final args = state.extra;
      final linking = args is OtpRouteArgs && args.linkToCurrentAccount;
      if (loginPages.contains(path) &&
          !linking &&
          await _repository.isSignedIn() &&
          _repository.hasVerifiedIdentity) {
        final profileComplete = await profileCompleteForNavigation(_repository);
        if (!await _repository.isSignedIn()) return null;
        final requested = safeReturnTo(
          args is OtpRouteArgs
              ? args.returnTo
              : state.uri.queryParameters['returnTo'],
        );
        final destination =
            requested != null &&
                !loginPages.contains(Uri.tryParse(requested)?.path) &&
                Uri.tryParse(requested)?.path != '/profile'
            ? requested
            : '/home';
        return profileComplete
            ? destination
            : Uri(
                path: '/profile',
                queryParameters: {'returnTo': destination},
              ).toString();
      }
      if (!protected.contains(path) && path != '/verify-email') return null;
      if (!await _repository.isSignedIn()) {
        return path == '/verify-email'
            ? '/email'
            : loginLocation(returnTo: state.uri.toString());
      }
      if (protected.contains(path) && !_repository.hasVerifiedIdentity) {
        return Uri(
          path: '/verify-email',
          queryParameters: {'returnTo': state.uri.toString()},
        ).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/onboarding'),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => PhoneLoginScreen(
          returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/phone',
        builder: (context, state) => PhoneLoginScreen(
          returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/phone-link',
        builder: (context, state) => PhoneLoginScreen(
          linkToCurrentAccount: true,
          returnTo:
              safeReturnTo(state.uri.queryParameters['returnTo']) ??
              '/account/security',
        ),
      ),
      GoRoute(
        path: '/email',
        builder: (context, state) => EmailLoginScreen(
          returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/email-link',
        builder: (context, state) => EmailLoginScreen(
          linkToCurrentAccount: true,
          returnTo:
              safeReturnTo(state.uri.queryParameters['returnTo']) ??
              '/account/security',
        ),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final args = state.extra;
          if (args is! OtpRouteArgs) {
            return const Scaffold(
              body: SafeArea(
                child: Center(
                  child: Text(
                    'This code session has expired. Go back and request a new code.',
                  ),
                ),
              ),
            );
          }
          return OtpScreen(args: args);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => EmailVerificationScreen(
          returnTo: safeReturnTo(
            state.extra is String
                ? state.extra as String
                : state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileSetupScreen(
          returnTo: safeReturnTo(
            state.extra is String
                ? state.extra as String
                : state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SetupCompleteScreen(),
      ),
      GoRoute(
        path: '/account/security',
        builder: (context, state) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) =>
            const ProtectedActionScreen(action: '/booking'),
      ),
      GoRoute(
        path: '/list-vehicle',
        builder: (context, state) =>
            const ProtectedActionScreen(action: '/list-vehicle'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RentRide',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _sessionRefresh.dispose();
    super.dispose();
  }
}

class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Stream<void> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }
  late final StreamSubscription<void> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
