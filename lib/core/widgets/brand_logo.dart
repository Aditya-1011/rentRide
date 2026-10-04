import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(compact ? 11 : 13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x242864F0),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.white,
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'RentRide',
          style: TextStyle(
            color: light ? Colors.white : AppColors.ink,
            fontSize: compact ? 19 : 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}
