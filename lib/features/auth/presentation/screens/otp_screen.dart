import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_error_message.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_navigation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_providers.dart';
import '../otp_route_args.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.args, super.key});

  final OtpRouteArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final AuthRepository _repository;
  final _codeController = TextEditingController();
  Timer? _timer;
  late String _verificationId;
  int _resendSeconds = 60;
  bool _loading = false;
  bool _resending = false;
  bool _finishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(authRepositoryProvider);
    _verificationId = widget.args.verificationId;
    _startResendTimer();
  }

  Future<void> _finishFlow() async {
    if (_finishing || !mounted) return;
    _finishing = true;
    try {
      if (widget.args.linkToCurrentAccount) {
        context.go(widget.args.returnTo ?? '/account/security');
        return;
      }
      await continueAfterSignIn(
        context,
        ref.read(authRepositoryProvider),
        returnTo: widget.args.returnTo,
      );
    } catch (error) {
      _finishing = false;
      if (mounted) setState(() => _error = authErrorMessage(error));
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6 || _loading || _resending) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.args.isEmail) {
        await _repository.verifyEmailLoginOtp(
          challengeId: _verificationId,
          code: _codeController.text,
          linkToCurrentAccount: widget.args.linkToCurrentAccount,
        );
      } else {
        await _repository.verifyOtp(
          verificationId: _verificationId,
          smsCode: _codeController.text,
          linkToCurrentAccount: widget.args.linkToCurrentAccount,
        );
      }
      if (!mounted) return;
      await _finishFlow();
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0 || _resending || _loading) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      _verificationId = widget.args.isEmail
          ? await _repository.sendEmailLoginOtp(
              widget.args.destination,
              linkToCurrentAccount: widget.args.linkToCurrentAccount,
            )
          : await _repository.sendOtp(
              widget.args.destination,
              linkToCurrentAccount: widget.args.linkToCurrentAccount,
            );
      if (!mounted) return;
      if (_verificationId == 'auto-verified') {
        await _finishFlow();
      } else {
        _codeController.clear();
        _startResendTimer();
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.args.destination;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(
                      widget.args.linkToCurrentAccount
                          ? '/account/security'
                          : widget.args.isEmail
                          ? '/email'
                          : '/phone',
                    );
                  }
                },
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.ink,
              ),
              const SizedBox(height: 22),
              const BrandLogo(),
              const SizedBox(height: 47),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.bluePale,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.blue,
                  size: 27,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                widget.args.isEmail
                    ? 'Check your\nemail'
                    : 'Check your\nmessages',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 13),
              Text(
                'Enter the 6-digit code we sent to $phone. It expires in 10 minutes.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 30),
              const Text(
                'VERIFICATION CODE',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                enabled: !_loading && !_resending,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 17,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (code) {
                  setState(() => _error = null);
                  if (code.length == 6) unawaited(_verify());
                },
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(
                  hintText: '• • • • • •',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFD92D20),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!AppConfig.useFirebaseAuth) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bluePale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Demo mode code: 123456',
                        style: TextStyle(
                          color: AppColors.blueDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 25),
              PrimaryButton(
                label: 'Verify and continue',
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _codeController.text.length == 6 ? _verify : null,
              ),
              const SizedBox(height: 23),
              Center(
                child: _resending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _resendSeconds == 0 ? _resend : null,
                        child: Text(
                          _resendSeconds == 0
                              ? 'Resend code'
                              : 'Resend code in ${_resendSeconds}s',
                          style: TextStyle(
                            color: _resendSeconds == 0
                                ? AppColors.blue
                                : AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 21),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go(
                    widget.args.linkToCurrentAccount
                        ? '/account/security'
                        : widget.args.isEmail
                        ? Uri(
                            path: '/email',
                            queryParameters: {
                              if (widget.args.returnTo != null)
                                'returnTo': widget.args.returnTo,
                            },
                          ).toString()
                        : loginLocation(returnTo: widget.args.returnTo),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: Text(
                    widget.args.isEmail
                        ? 'Change email address'
                        : 'Change phone number',
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
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
    _repository.cancelPendingPhoneVerification();
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }
}
