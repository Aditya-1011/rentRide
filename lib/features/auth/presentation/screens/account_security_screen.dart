import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../auth_providers.dart';

class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(authRepositoryProvider);
    final email = repository.currentEmail;
    final phone = repository.currentPhoneNumber;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/explore'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const BrandLogo(compact: true),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Account security',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect your email and phone to sign in with either method.',
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_android_rounded),
                title: const Text('Phone number'),
                subtitle: Text(phone ?? 'Not connected'),
                trailing: Icon(
                  phone != null
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline,
                  color: AppColors.blue,
                ),
              ),
              if (phone == null)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/phone-link?returnTo=%2Faccount%2Fsecurity'),
                  icon: const Icon(Icons.phone_android_rounded),
                  label: const Text('Connect phone with OTP'),
                ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text('Email address'),
                subtitle: Text(email ?? 'Not connected'),
                trailing: Icon(
                  email != null && repository.emailIsVerified
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline,
                  color: AppColors.blue,
                ),
              ),
              if (email == null)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/email-link?returnTo=%2Faccount%2Fsecurity'),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Connect email with OTP'),
                ),
              if (email != null && !repository.emailIsVerified)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/verify-email', extra: '/account/security'),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Verify your email'),
                ),
              const SizedBox(height: 24),
              const Text(
                'A code confirms each new sign-in method. If the email or phone belongs to another account, sign in to that account instead. Accounts are never merged automatically.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'For your security, connecting a method may require signing in again.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
