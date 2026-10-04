import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_error_message.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_providers.dart';
import '../otp_route_args.dart';
import '../widgets/auth_method_switch.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({
    this.returnTo,
    this.linkToCurrentAccount = false,
    super.key,
  });

  final String? returnTo;
  final bool linkToCurrentAccount;

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim().toLowerCase();
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(authRepositoryProvider)
          .sendEmailLoginOtp(
            email,
            linkToCurrentAccount: widget.linkToCurrentAccount,
          );
      if (!mounted) return;
      context.push(
        '/otp',
        extra: OtpRouteArgs(
          destination: email,
          verificationId: id,
          channel: OtpChannel.email,
          returnTo: widget.returnTo,
          linkToCurrentAccount: widget.linkToCurrentAccount,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: _loading
                  ? null
                  : () => context.go(
                      widget.linkToCurrentAccount
                          ? '/account/security'
                          : '/onboarding',
                    ),
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 22),
            const BrandLogo(),
            const SizedBox(height: 44),
            Text(
              widget.linkToCurrentAccount
                  ? 'Connect your\nemail address'
                  : 'Sign in with\nyour email',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 14),
            Text(
              widget.linkToCurrentAccount
                  ? 'Verify your email to use it with this account.'
                  : 'We’ll send a six-digit code. No password needed. New to RentRide? Your account is created after verification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!widget.linkToCurrentAccount) ...[
              const SizedBox(height: 24),
              AuthMethodSwitch(
                selected: OtpChannel.email,
                enabled: !_loading,
                onChanged: (channel) {
                  if (channel == OtpChannel.email) return;
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.go(
                    Uri(
                      path: '/phone',
                      queryParameters: {
                        if (widget.returnTo != null)
                          'returnTo': widget.returnTo,
                      },
                    ).toString(),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              autocorrect: false,
              maxLength: 254,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                counterText: '',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Send email code',
              icon: Icons.arrow_forward_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            const Text(
              'Check your inbox and spam folder. Codes expire after 10 minutes.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (!widget.linkToCurrentAccount) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/explore'),
                  child: const Text('Explore as guest'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
