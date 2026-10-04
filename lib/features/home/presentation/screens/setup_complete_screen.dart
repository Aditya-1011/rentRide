import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_providers.dart';

class SetupCompleteScreen extends ConsumerWidget {
  const SetupCompleteScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go('/explore');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 16, 23, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(compact: true),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bluePale,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.blue,
                  size: 38,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Welcome to RentRide',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 9),
              Text(
                'Your account is ready. Explore as a renter now, and list a vehicle later whenever you’re ready.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  children: [
                    _ReadyRow(
                      icon: Icons.verified_user_rounded,
                      title: 'Your sign-in method is verified',
                    ),
                    SizedBox(height: 13),
                    _ReadyRow(
                      icon: Icons.person_rounded,
                      title: 'Your profile is set up',
                    ),
                    SizedBox(height: 13),
                    _ReadyRow(
                      icon: Icons.directions_car_filled_rounded,
                      title: 'Vehicle discovery is coming next',
                      pending: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Explore RentRide',
                icon: Icons.explore_rounded,
                onPressed: () => context.go('/explore'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('/account/security'),
                icon: const Icon(Icons.security_rounded),
                label: const Text('Account security'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.blueDark,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: TextButton(
                  onPressed: () => _signOut(context, ref),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({
    required this.icon,
    required this.title,
    this.pending = false,
  });

  final IconData icon;
  final String title;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: pending ? AppColors.muted : AppColors.green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: pending ? AppColors.muted : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(
          pending ? Icons.schedule_rounded : Icons.check_rounded,
          size: 17,
          color: pending ? AppColors.muted : AppColors.green,
        ),
      ],
    );
  }
}
