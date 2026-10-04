import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_error_message.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_navigation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_providers.dart';
import '../otp_route_args.dart';
import '../widgets/auth_method_switch.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({
    this.returnTo,
    this.linkToCurrentAccount = false,
    super.key,
  });

  final String? returnTo;
  final bool linkToCurrentAccount;

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  late final AuthRepository _repository;
  final _phoneController = TextEditingController();
  bool _consent = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(authRepositoryProvider);
  }

  bool get _validPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text);

  Future<void> _sendCode() async {
    if (!_validPhone || !_consent || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final phoneNumber = '+91${_phoneController.text}';
    try {
      final verificationId = await ref
          .read(authRepositoryProvider)
          .sendOtp(
            phoneNumber,
            linkToCurrentAccount: widget.linkToCurrentAccount,
          );
      if (!mounted) return;
      if (verificationId == 'auto-verified') {
        if (widget.linkToCurrentAccount) {
          context.go(widget.returnTo ?? '/account/security');
        } else {
          await continueAfterSignIn(
            context,
            ref.read(authRepositoryProvider),
            returnTo: widget.returnTo,
          );
        }
      } else {
        context.push(
          '/otp',
          extra: OtpRouteArgs(
            destination: phoneNumber,
            verificationId: verificationId,
            returnTo: widget.returnTo,
            linkToCurrentAccount: widget.linkToCurrentAccount,
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 20 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom -
                    34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding'),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.ink,
                  ),
                  const SizedBox(height: 15),
                  const BrandLogo(),
                  const SizedBox(height: 44),
                  Text(
                    widget.linkToCurrentAccount
                        ? 'Connect your\nphone number'
                        : 'Welcome to\nRentRide',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 34,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.linkToCurrentAccount
                        ? 'Verify this phone number to add it to your signed-in account.'
                        : 'Sign in or create an account to find your next ride, or share a vehicle of your own.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 34),
                  if (!widget.linkToCurrentAccount) ...[
                    AuthMethodSwitch(
                      selected: OtpChannel.phone,
                      enabled: !_loading,
                      onChanged: (channel) {
                        if (channel == OtpChannel.phone) return;
                        FocusManager.instance.primaryFocus?.unfocus();
                        context.go(
                          Uri(
                            path: '/email',
                            queryParameters: {
                              if (widget.returnTo != null)
                                'returnTo': widget.returnTo,
                            },
                          ).toString(),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                  ],
                  const Text(
                    'Mobile number',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        height: 57,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Row(
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              '+91',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.muted,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {
                            _error = null;
                          }),
                          onSubmitted: (_) => _sendCode(),
                          decoration: const InputDecoration(
                            hintText: 'Mobile number',
                            counterText: '',
                            prefixIcon: Icon(Icons.phone_iphone_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    _InlineError(message: _error!),
                  ],
                  const SizedBox(height: 17),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _consent = !_consent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 23,
                            height: 23,
                            child: Checkbox(
                              value: _consent,
                              onChanged: (value) =>
                                  setState(() => _consent = value ?? false),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: const BorderSide(color: AppColors.muted),
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'I agree to receive a one-time verification code by SMS. Message and data rates may apply.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: widget.linkToCurrentAccount
                        ? 'Verify phone number'
                        : 'Continue with phone',
                    icon: Icons.arrow_forward_rounded,
                    loading: _loading,
                    onPressed: _validPhone && _consent ? _sendCode : null,
                  ),
                  const SizedBox(height: 19),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'SECURE PHONE VERIFICATION',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.green,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your number stays private and secure',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!widget.linkToCurrentAccount)
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/explore'),
                        child: const Text('Explore as guest'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repository.cancelPendingPhoneVerification();
    _phoneController.dispose();
    super.dispose();
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD92D20),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
