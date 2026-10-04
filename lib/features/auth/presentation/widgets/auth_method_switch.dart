import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../otp_route_args.dart';

class AuthMethodSwitch extends StatelessWidget {
  const AuthMethodSwitch({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final OtpChannel selected;
  final ValueChanged<OtpChannel> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final channel in OtpChannel.values)
          Expanded(
            child: Semantics(
              selected: selected == channel,
              child: TextButton(
                onPressed: enabled ? () => onChanged(channel) : null,
                style: TextButton.styleFrom(
                  backgroundColor: selected == channel
                      ? AppColors.blue
                      : Colors.transparent,
                  foregroundColor: selected == channel
                      ? Colors.white
                      : AppColors.muted,
                  disabledBackgroundColor: selected == channel
                      ? AppColors.blue
                      : Colors.transparent,
                  disabledForegroundColor: selected == channel
                      ? Colors.white
                      : AppColors.muted,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: Text(channel == OtpChannel.phone ? 'Phone' : 'Email'),
              ),
            ),
          ),
      ],
    ),
  );
}
