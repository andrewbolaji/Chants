import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/presentation/auth/auth_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInMethodsScreen extends ConsumerStatefulWidget {
  const SignInMethodsScreen({super.key});

  @override
  ConsumerState<SignInMethodsScreen> createState() =>
      _SignInMethodsScreenState();
}

class _SignInMethodsScreenState extends ConsumerState<SignInMethodsScreen> {
  String? _activeMethod;
  String? _message;
  bool _messageIsError = false;

  Future<void> _run(
    String method,
    Future<void> Function() action, {
    String success = 'Sign-in method connected.',
  }) async {
    if (_activeMethod != null) return;
    setState(() {
      _activeMethod = method;
      _message = null;
    });
    try {
      await action();
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _message = success;
        _messageIsError = false;
      });
    } on AuthFlowCancelledException {
      if (mounted) setState(() => _activeMethod = null);
    } on LastSignInMethodException {
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _message = 'Connect another sign-in method before removing this one.';
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _message = authErrorMessage(error);
        _messageIsError = true;
      });
    }
  }

  Future<void> _linkApple() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Apple?'),
        content: const Text(
          'Apple will confirm the account you choose. Chants will connect it '
          'to this same profile and Firebase UID. Nothing is merged by email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('CONNECT APPLE'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _run('apple.com', () async {
        await ref.read(authRepositoryProvider).linkApple();
      });
    }
  }

  Future<void> _openLinkRoute(
    String route, {
    bool reload = true,
    String success = 'Sign-in method connected.',
  }) async {
    final result = await Navigator.pushNamed(context, route, arguments: true);
    if (result == true && mounted) {
      if (reload) {
        await ref.read(authRepositoryProvider).reloadCurrentUser();
      }
      if (!mounted) return;
      setState(() {
        _message = success;
        _messageIsError = false;
      });
    }
  }

  Future<void> _sendEmailVerification() async {
    if (_activeMethod != null) return;
    setState(() {
      _activeMethod = 'verify-email';
      _message = null;
    });
    try {
      final sent = await ref
          .read(authRepositoryProvider)
          .sendEmailVerification();
      if (!sent) {
        await ref.read(authRepositoryProvider).reloadCurrentUser();
      }
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _message = sent
            ? 'Verification email sent.'
            : 'Email is already verified. Account status refreshed.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activeMethod = null;
        _message = authErrorMessage(error);
        _messageIsError = true;
      });
    }
  }

  String _label(String providerId) {
    return switch (providerId) {
      'password' => 'Email',
      'google.com' => 'Google',
      'apple.com' => 'Apple',
      'facebook.com' => 'Facebook',
      'phone' => 'Phone',
      _ => 'Connected provider',
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(authFeatureConfigProvider);
    final repository = ref.read(authRepositoryProvider);
    final user = repository.currentUser;
    final linked =
        user?.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toSet() ??
        <String>{};
    final canRemove = linked.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('SIGN-IN METHODS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xxxl,
          ),
          children: [
            const Text(
              'Connect another way to get back into the same Chants account. '
              'We never merge accounts only because emails match.',
              style: TextStyle(color: AppColors.textBody),
            ),
            if (_message != null) ...[
              const SizedBox(height: Spacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ),
            ],
            const SizedBox(height: Spacing.xl),
            Text('CONNECTED', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            for (final providerId in linked)
              Card(
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                color: AppColors.surface,
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(_label(providerId)),
                  subtitle:
                      providerId == 'password' && user?.emailVerified == false
                      ? const Text('Email verification still needed')
                      : const Text('Connected to this account'),
                  trailing: TextButton(
                    onPressed: _activeMethod == null && canRemove
                        ? () => _run(
                            providerId,
                            () async => repository.unlinkProvider(providerId),
                            success: 'Sign-in method removed.',
                          )
                        : null,
                    child: const Text('REMOVE'),
                  ),
                ),
              ),
            if (linked.contains('password')) ...[
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.passwordReset),
                child: const Text('RESET EMAIL PASSWORD'),
              ),
              if (user?.emailVerified == false)
                TextButton(
                  onPressed: _activeMethod == null
                      ? _sendEmailVerification
                      : null,
                  child: const Text('RESEND EMAIL VERIFICATION'),
                ),
            ],
            const SizedBox(height: Spacing.xl),
            Text('ADD A METHOD', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            if (config.appleEnabled && !linked.contains('apple.com'))
              _ConnectButton(
                label: 'CONNECT APPLE',
                active: _activeMethod == 'apple.com',
                onPressed: _linkApple,
              ),
            if (config.googleEnabled && !linked.contains('google.com'))
              _ConnectButton(
                label: 'CONNECT GOOGLE',
                active: _activeMethod == 'google.com',
                onPressed: () => _run(
                  'google.com',
                  () async => repository.linkGoogle(
                    clientId: config.googleClientId,
                    serverClientId: config.googleServerClientId,
                  ),
                ),
              ),
            if (config.facebookEnabled && !linked.contains('facebook.com'))
              _ConnectButton(
                label: 'CONNECT FACEBOOK',
                active: _activeMethod == 'facebook.com',
                onPressed: () =>
                    _run('facebook.com', () async => repository.linkFacebook()),
              ),
            if (config.phoneEnabled && !linked.contains('phone'))
              _ConnectButton(
                label: 'CONNECT PHONE',
                active: false,
                onPressed: () => _openLinkRoute(AppRouter.phoneAuth),
              ),
            if (config.magicLinkEnabled && !linked.contains('password'))
              _ConnectButton(
                label: 'CONNECT EMAIL LINK',
                active: false,
                onPressed: () => _openLinkRoute(
                  AppRouter.magicLink,
                  reload: false,
                  success:
                      'Email link sent. Open it on this device to finish connecting.',
                ),
              ),
            if ((!config.appleEnabled || linked.contains('apple.com')) &&
                (!config.googleEnabled || linked.contains('google.com')) &&
                (!config.facebookEnabled || linked.contains('facebook.com')) &&
                (!config.phoneEnabled || linked.contains('phone')) &&
                (!config.magicLinkEnabled || linked.contains('password')))
              const Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: Text(
                    'No additional launch method is available right now.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _ConnectButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: active ? null : onPressed,
        child: active
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
