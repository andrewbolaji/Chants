import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/magic_link_store.dart';
import 'package:chants/presentation/auth/auth_error_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MagicLinkGate extends ConsumerStatefulWidget {
  final Widget child;

  const MagicLinkGate({super.key, required this.child});

  @override
  ConsumerState<MagicLinkGate> createState() => _MagicLinkGateState();
}

class _MagicLinkGateState extends ConsumerState<MagicLinkGate> {
  StreamSubscription<Uri>? _subscription;
  Uri? _link;

  @override
  void initState() {
    super.initState();
    final config = ref.read(authFeatureConfigProvider);
    if (config.magicLinkEnabled) {
      _subscription = ref
          .read(magicLinkCoordinatorProvider)
          .links()
          .listen(_considerLink, onError: (_) {});
    }
  }

  void _considerLink(Uri link) {
    if (!mounted) return;
    if (ref.read(authRepositoryProvider).isMagicLink(link.toString())) {
      setState(() => _link = link);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    if (link == null) return widget.child;
    return MagicLinkCompletionScreen(
      link: link,
      onDone: () {
        if (mounted) setState(() => _link = null);
      },
    );
  }
}

class MagicLinkCompletionScreen extends ConsumerStatefulWidget {
  final Uri link;
  final VoidCallback onDone;

  const MagicLinkCompletionScreen({
    super.key,
    required this.link,
    required this.onDone,
  });

  @override
  ConsumerState<MagicLinkCompletionScreen> createState() =>
      _MagicLinkCompletionScreenState();
}

class _MagicLinkCompletionScreenState
    extends ConsumerState<MagicLinkCompletionScreen> {
  final _emailController = TextEditingController();
  PendingMagicLink? _pending;
  bool _loadingState = true;
  bool _completing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pending = await ref.read(magicLinkStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _loadingState = false;
      if (pending != null) _emailController.text = pending.email;
    });
    if (pending != null) await _complete();
  }

  Future<void> _complete() async {
    if (_completing) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error = 'Enter the email address that received the link.',
      );
      return;
    }
    final repository = ref.read(authRepositoryProvider);
    final pending = _pending;
    final currentUid = repository.currentUser?.uid;
    final linkingUid = pending?.linkingUid;
    if (linkingUid != null && linkingUid != currentUid) {
      setState(() {
        _error =
            'This link was requested by another signed-in account. '
            'Return to that account and request a new link.';
      });
      return;
    }
    if (linkingUid == null && currentUid != null) {
      setState(() {
        _error =
            'This is a sign-in link, but another account is open. '
            'Use Sign-in methods from You to connect an email safely.';
      });
      return;
    }

    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      await repository.completeMagicLink(
        email: email,
        link: widget.link.toString(),
        linkToCurrentUser: linkingUid != null,
      );
      await ref.read(magicLinkStoreProvider).clear();
      if (mounted) widget.onDone();
    } catch (error) {
      final terminal =
          error is FirebaseAuthException &&
          (error.code == 'invalid-action-code' ||
              error.code == 'expired-action-code');
      if (terminal) await ref.read(magicLinkStoreProvider).clear();
      if (!mounted) return;
      setState(() {
        _completing = false;
        _error = terminal
            ? 'That link is invalid or expired. Request a new one.'
            : authErrorMessage(error);
      });
    }
  }

  Future<void> _cancel() async {
    await ref.read(magicLinkStoreProvider).clear();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingState) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('EMAIL LINK')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.xl),
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 54),
            const SizedBox(height: Spacing.xl),
            Text(
              'FINISH SIGNING IN',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              _pending == null
                  ? 'For safety, enter the email address that received this link.'
                  : 'Chants is checking your one-time link.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: Spacing.xl),
            if (_pending == null)
              TextField(
                controller: _emailController,
                enabled: !_completing,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
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
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _completing ? null : _complete,
              child: _completing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('FINISH SIGNING IN'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: _completing ? null : _cancel,
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
  }
}
