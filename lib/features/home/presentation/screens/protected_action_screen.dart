import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_navigation.dart';
import '../../../auth/presentation/auth_providers.dart';

class ProtectedActionScreen extends ConsumerStatefulWidget {
  const ProtectedActionScreen({required this.action, super.key});

  final String action;

  @override
  ConsumerState<ProtectedActionScreen> createState() =>
      _ProtectedActionScreenState();
}

class _ProtectedActionScreenState extends ConsumerState<ProtectedActionScreen> {
  late Future<bool> _accessCheck;

  @override
  void initState() {
    super.initState();
    _accessCheck = _checkAccess();
  }

  Future<bool> _checkAccess() async {
    final repository = ref.read(authRepositoryProvider);
    final signedIn = await repository.isSignedIn();
    if (!mounted) return false;
    if (!signedIn) {
      context.go(loginLocation(returnTo: widget.action));
      return false;
    }
    if (!repository.hasVerifiedIdentity) {
      context.go('/verify-email', extra: widget.action);
      return false;
    }
    final profileComplete = await repository.isProfileComplete();
    if (!mounted) return false;
    if (!profileComplete) {
      context.go('/profile', extra: widget.action);
      return false;
    }
    return true;
  }

  void _retry() => setState(() => _accessCheck = _checkAccess());

  @override
  Widget build(BuildContext context) {
    final isListing = widget.action == '/list-vehicle';
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _accessCheck,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'We couldn’t check your account. Check your connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _retry,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data != true) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 17, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(compact: true),
                  const Spacer(),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.bluePale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isListing
                          ? Icons.key_rounded
                          : Icons.event_available_rounded,
                      color: AppColors.blue,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isListing ? 'Share your vehicle' : 'Ready to book?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isListing
                        ? 'Your RentRide account is ready. Vehicle listing setup is coming in the next Phase 2 step.'
                        : 'You’re signed in and ready. Vehicle discovery and booking are coming in the next Phase 2 steps.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Back to Explore',
                    icon: Icons.explore_rounded,
                    onPressed: () => context.go('/explore'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
