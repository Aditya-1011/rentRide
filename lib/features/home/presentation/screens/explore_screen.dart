import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_navigation.dart';
import '../../../auth/presentation/auth_providers.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.read(authRepositoryProvider).isSignedIn();
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: isSignedIn,
          builder: (context, snapshot) {
            final signedIn = snapshot.data ?? false;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(23, 17, 23, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: BrandLogo(compact: true)),
                      if (signedIn)
                        IconButton(
                          onPressed: () => context.go('/account/security'),
                          tooltip: 'Account security',
                          icon: const Icon(Icons.person_outline_rounded),
                        )
                      else
                        TextButton(
                          onPressed: () => context.go(loginLocation()),
                          child: const Text('Sign in'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Explore RentRide',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 31),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Cars, bikes and scooters shared by people in your city.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEAF3FF), Color(0xFFD8E6FF)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 51,
                          height: 51,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.blue,
                            size: 27,
                          ),
                        ),
                        const SizedBox(height: 19),
                        Text(
                          'Your next ride starts here',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontSize: 23),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Browse as a guest. Sign in when you’re ready to book.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),
                  const _SectionTitle('Choose your ride'),
                  const SizedBox(height: 11),
                  const Row(
                    children: [
                      Expanded(
                        child: _RideTypeCard(
                          icon: Icons.directions_car_rounded,
                          title: 'Cars',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _RideTypeCard(
                          icon: Icons.two_wheeler_rounded,
                          title: 'Bikes',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _RideTypeCard(
                          icon: Icons.electric_scooter_rounded,
                          title: 'Scooters',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.explore_outlined, color: AppColors.blue),
                        SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle discovery is coming next',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'You can explore RentRide now. Vehicle listings and booking will be added in the next Phase 2 steps.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: signedIn ? 'Continue to booking' : 'Sign in to book',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => signedIn
                        ? context.go('/booking')
                        : context.go(loginLocation(returnTo: '/booking')),
                  ),
                  const SizedBox(height: 11),
                  OutlinedButton.icon(
                    onPressed: () => signedIn
                        ? context.go('/list-vehicle')
                        : context.go(loginLocation(returnTo: '/list-vehicle')),
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('List your vehicle'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(53),
                      foregroundColor: AppColors.blueDark,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _RideTypeCard extends StatelessWidget {
  const _RideTypeCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blue, size: 23),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
