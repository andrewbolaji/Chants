import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/presentation/auth/auth_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String? _activeMethod;
  String? _error;
  bool _showMore = false;

  Future<void> _run(String method, Future<void> Function() action) async {
    if (_activeMethod != null) return;
    setState(() {
      _activeMethod = method;
      _error = null;
    });
    try {
      await action();
    } on AuthFlowCancelledException {
      if (mounted) setState(() => _activeMethod = null);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(authFeatureConfigProvider);
    final repository = ref.read(authRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.xl,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            const _WelcomeMark(),
            const SizedBox(height: Spacing.xl),
            Text(
              'LEARN THE SONGS.\nBACK WHAT COMES NEXT.\nTAKE THE STAGE.',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(height: 1.12, fontSize: 34),
            ),
            const SizedBox(height: Spacing.md),
            const Text(
              'The matchday songbook and creator stage for football chants.',
              style: TextStyle(color: AppColors.textBody, fontSize: 16),
            ),
            const SizedBox(height: Spacing.xl),
            const _PromiseStrip(),
            const SizedBox(height: Spacing.xl),
            if (config.appleEnabled) ...[
              _MethodButton(
                label: 'CONTINUE WITH APPLE',
                icon: Icons.apple,
                loading: _activeMethod == 'apple',
                enabled: _activeMethod == null,
                onPressed: () =>
                    _run('apple', () async => repository.signInWithApple()),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            if (config.googleEnabled) ...[
              _MethodButton(
                label: 'CONTINUE WITH GOOGLE',
                textIcon: 'G',
                loading: _activeMethod == 'google',
                enabled: _activeMethod == null,
                onPressed: () => _run(
                  'google',
                  () async => repository.signInWithGoogle(
                    clientId: config.googleClientId,
                    serverClientId: config.googleServerClientId,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            FilledButton.icon(
              onPressed: _activeMethod == null
                  ? () => Navigator.pushNamed(context, AppRouter.emailSignIn)
                  : null,
              icon: const Icon(Icons.mail_outline),
              label: const Text('CONTINUE WITH EMAIL'),
            ),
            if (config.hasSecondaryMethods) ...[
              const SizedBox(height: Spacing.sm),
              TextButton.icon(
                onPressed: _activeMethod == null
                    ? () => setState(() => _showMore = !_showMore)
                    : null,
                icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
                label: const Text('MORE WAYS TO SIGN IN'),
              ),
              if (_showMore) ...[
                if (config.facebookEnabled)
                  _MethodButton(
                    label: 'CONTINUE WITH FACEBOOK',
                    textIcon: 'f',
                    loading: _activeMethod == 'facebook',
                    enabled: _activeMethod == null,
                    onPressed: () => _run(
                      'facebook',
                      () async => repository.signInWithFacebook(),
                    ),
                  ),
                if (config.facebookEnabled && config.phoneEnabled)
                  const SizedBox(height: Spacing.sm),
                if (config.phoneEnabled)
                  _MethodButton(
                    label: 'CONTINUE WITH PHONE',
                    icon: Icons.sms_outlined,
                    loading: false,
                    enabled: _activeMethod == null,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.phoneAuth,
                      arguments: false,
                    ),
                  ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: Spacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'New to Chants?',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                TextButton(
                  onPressed: _activeMethod == null
                      ? () => Navigator.pushNamed(context, AppRouter.signUp)
                      : null,
                  child: const Text('CREATE ACCOUNT'),
                ),
              ],
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.contentPolicy),
              child: const Text('CONTENT POLICY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.md,
      runSpacing: Spacing.sm,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: const Icon(
            Icons.graphic_eq,
            color: AppColors.goldOnDark,
            size: 30,
          ),
        ),
        const Text(
          'CHANTS',
          style: TextStyle(
            fontFamily: 'Anton',
            fontSize: 30,
            color: AppColors.textHeadline,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PromiseStrip extends StatelessWidget {
  const _PromiseStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _Promise(icon: Icons.play_circle_outline, text: 'WATCH'),
          ),
          Expanded(
            child: _Promise(icon: Icons.menu_book_outlined, text: 'LEARN'),
          ),
          Expanded(
            child: _Promise(icon: Icons.mic_none_outlined, text: 'CREATE'),
          ),
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Promise({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold),
        const SizedBox(height: Spacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: AppColors.textBody,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? textIcon;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _MethodButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
    this.icon,
    this.textIcon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: AppColors.textHeadline,
        side: const BorderSide(color: AppColors.outline),
      ),
      onPressed: enabled ? onPressed : null,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
          ? Icon(icon)
          : SizedBox(
              width: 24,
              child: Text(
                textIcon ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      label: Text(label),
    );
  }
}
