import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_error_message.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_navigation.dart';
import '../auth_providers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _resendSeconds = 0;
  bool _loading = false;
  bool _resending = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resend();
    });
  }

  void _startCooldown() {
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

  Future<void> _checkVerification() async {
    if (_loading || _resending) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.verifyEmailCode(_codeController.text.trim());
      if (!await repository.refreshEmailVerification()) {
        if (mounted) {
          setState(
            () => _message = 'Verification is still pending. Please try again.',
          );
        }
        return;
      }
      if (!mounted) return;
      await continueAfterSignIn(context, repository, returnTo: widget.returnTo);
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _loading || _resendSeconds > 0) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      if (await repository.refreshEmailVerification()) {
        if (!mounted) return;
        await continueAfterSignIn(
          context,
          repository,
          returnTo: widget.returnTo,
        );
        return;
      }
      await repository.sendEmailVerification();
      if (!mounted) return;
      setState(
        () => _message =
            'Verification email sent. Check your inbox and spam folder.',
      );
      _startCooldown();
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        ref.watch(authRepositoryProvider).currentEmail ?? 'your email address';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => context.go(
                            loginLocation(returnTo: widget.returnTo),
                          ),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.ink,
                        ),
                        const SizedBox(height: 22),
                        const BrandLogo(),
                        const Spacer(),
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
                          'Verify your\nemail address',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          'Verify $email with a six-digit email code. Each code expires in 10 minutes.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 6,
                          enabled: !_loading,
                          decoration: const InputDecoration(
                            labelText: 'Email verification code',
                          ),
                          onSubmitted: (_) => _checkVerification(),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bluePale,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _message!,
                              style: const TextStyle(
                                color: AppColors.blueDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        PrimaryButton(
                          label: 'Verify email',
                          icon: Icons.arrow_forward_rounded,
                          loading: _loading,
                          onPressed: _resending ? null : _checkVerification,
                        ),
                        const SizedBox(height: 9),
                        Center(
                          child: TextButton(
                            onPressed: _resendSeconds > 0 || _resending
                                ? null
                                : _resend,
                            child: Text(
                              _resending
                                  ? 'Sending…'
                                  : _resendSeconds > 0
                                  ? 'Resend email in ${_resendSeconds}s'
                                  : 'Resend verification email',
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) {
                                context.go(
                                  loginLocation(returnTo: widget.returnTo),
                                );
                              }
                            },
                            child: const Text('Use a different account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }
}
