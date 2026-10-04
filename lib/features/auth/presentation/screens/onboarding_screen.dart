import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _IntroSlide(
      eyebrow: 'YOUR CITY, YOUR WAY',
      title: 'Find your ride',
      description:
          'Discover cars, bikes and scooters nearby, shared by people in your community.',
      icon: Icons.directions_car_filled_rounded,
      iconLabel: 'A good day starts with a great drive',
    ),
    _IntroSlide(
      eyebrow: 'SIMPLE FROM THE START',
      title: 'Book easily',
      description:
          'Choose a vehicle, pick your dates and make the plan yours. It only takes a few taps.',
      icon: Icons.two_wheeler_rounded,
      iconLabel: 'The keys to a little more freedom',
    ),
    _IntroSlide(
      eyebrow: 'MORE THAN A RIDE',
      title: 'Ride anywhere',
      description:
          'Make a quick city trip or take the long way home. Your next journey is waiting.',
      icon: Icons.route_rounded,
      iconLabel: 'Take the scenic route',
    ),
  ];

  void _continue() {
    if (_page == _slides.length - 1) {
      context.go('/login');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(compact: true),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => _RideIllustration(
                    slide: _slides[index],
                    number: index + 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final selected = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 24 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue
                          : const Color(0xFFD9DFEA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 19),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Column(
                  key: ValueKey(_page),
                  children: [
                    Text(
                      _slides[_page].title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 9),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        _slides[_page].description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _page == _slides.length - 1 ? 'Get started' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'I already have an account',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text(
                  'Explore as guest',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconLabel,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String iconLabel;
}

class _RideIllustration extends StatelessWidget {
  const _RideIllustration({required this.slide, required this.number});

  final _IntroSlide slide;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFC4DCFF), Color(0xFFB8D0FB)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -40,
            right: -22,
            child: Container(
              width: 205,
              height: 205,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x45FFFFFF),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    slide.eyebrow,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: AppColors.blueDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${number.toString().padLeft(2, '0')} / 03',
                  style: const TextStyle(
                    color: AppColors.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 74,
            left: 14,
            right: 14,
            height: 180,
            child: Center(
              child: Container(
                width: 178,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18264C91),
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(slide.icon, size: 91, color: AppColors.blueDark),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 112,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FloatingTag(
                  icon: Icons.verified_user_rounded,
                  text: 'Trusted hosts',
                ),
                _FloatingTag(icon: Icons.bolt_rounded, text: 'Easy booking'),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 128,
            child: CustomPaint(painter: _RoadPainter()),
          ),
          Positioned(
            left: 20,
            bottom: 23,
            right: 20,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    slide.iconLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14233556),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.blue),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Path()
      ..moveTo(size.width * 0.33, 0)
      ..lineTo(size.width * 0.67, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF35435D));

    final lane = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.23 + i * 0.22);
      final width = 2.5 + i * 1.7;
      final height = 8.0 + i * 5.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y),
            width: width,
            height: height,
          ),
          const Radius.circular(4),
        ),
        lane,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
