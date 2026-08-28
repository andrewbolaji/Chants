import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _refreshing = false;
  bool _sending = false;
  int _cooldownSeconds = 0;
  String? _message;
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  String _verificationError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'network-request-failed' =>
          'You appear to be offline. Reconnect and try again.',
        'too-many-requests' =>
          'Too many requests. Wait a moment before trying again.',
        'user-disabled' ||
        'user-not-found' => 'This account is unavailable. Use another account.',
        _ => 'Verification could not be checked. Try again.',
      };
    }
    return 'Verification could not be checked. Try again.';
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing || !mounted) return;
    setState(() {
      _refreshing = true;
      if (!silent) _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _message =
              'Still waiting for verification. Check the link, then '
              'return here.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = _verificationError(error));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _resend() async {
    if (_sending || _cooldownSeconds > 0) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _message = 'Verification email sent. Check your inbox and spam folder.';
        _cooldownSeconds = 60;
      });
      _cooldown?.cancel();
      _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _cooldownSeconds <= 1) {
          timer.cancel();
          if (mounted) setState(() => _cooldownSeconds = 0);
          return;
        }
        setState(() => _cooldownSeconds -= 1);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = _verificationError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email?.trim();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.xxxl,
          ),
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 54),
            const SizedBox(height: Spacing.xl),
            Text(
              'VERIFY YOUR EMAIL',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              email == null || email.isEmpty
                  ? 'Open your verification link if it has arrived, or '
                        'resend it below.'
                  : 'Verify $email to continue. Open the link if it has '
                        'arrived, or resend it below.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              'We check again automatically when the app returns.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            if (_message != null) ...[
              const SizedBox(height: Spacing.xl),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textBody),
                ),
              ),
            ],
            const SizedBox(height: Spacing.xxxl),
            FilledButton(
              onPressed: _refreshing ? null : () => _refresh(),
              child: _refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("I'VE VERIFIED"),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton(
              onPressed: _sending || _cooldownSeconds > 0 ? null : _resend,
              child: Text(
                _cooldownSeconds > 0
                    ? 'RESEND IN ${_cooldownSeconds}s'
                    : 'RESEND EMAIL',
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('USE ANOTHER ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }
}
