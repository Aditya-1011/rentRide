import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_error_message.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_navigation.dart';
import '../auth_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 60 || _loading) {
      setState(
        () => _error =
            'Enter your name so people know who they are booking with.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.saveProfile(displayName: name);
      if (!mounted) return;
      await continueAfterSignIn(context, repository, returnTo: widget.returnTo);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(compact: true),
              const SizedBox(height: 38),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bluePale,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'A QUICK INTRO',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Let’s make it\nyours',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 12),
              Text(
                'Add your name to finish setting up your account. You can rent now and list a vehicle later from your profile.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14.5),
              ),
              const SizedBox(height: 30),
              const Text(
                'Your name',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 60,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _continue(),
                decoration: const InputDecoration(
                  hintText: 'e.g. Ananya Rao',
                  counterText: '',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _continue,
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'You can update your details any time.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 7),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/explore');
                  },
                  child: const Text('Continue browsing as guest'),
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
    _nameController.dispose();
    super.dispose();
  }
}
