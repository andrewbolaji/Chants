import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/auth/auth_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MagicLinkScreen extends ConsumerStatefulWidget {
  final bool linkToCurrentUser;

  const MagicLinkScreen({super.key, required this.linkToCurrentUser});

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final config = ref.read(authFeatureConfigProvider);
    if (!config.magicLinkEnabled) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final uid = widget.linkToCurrentUser
        ? ref.read(authRepositoryProvider).currentUser?.uid
        : null;
    if (widget.linkToCurrentUser && uid == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in again before connecting this email.';
      });
      return;
    }
    try {
      await ref
          .read(magicLinkStoreProvider)
          .save(email: email, linkingUid: uid);
      await ref
          .read(authRepositoryProvider)
          .sendMagicLink(
            email: email,
            continueUrl: config.magicLinkContinueUrl,
            linkDomain: config.magicLinkDomain,
          );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EMAIL LINK')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 54),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      'LINK SENT',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: Spacing.md),
                    const Text(
                      'Open the link on this device within one hour. Chants '
                      'will finish automatically when you return.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textBody),
                    ),
                    const SizedBox(height: Spacing.xl),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('BACK'),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        widget.linkToCurrentUser
                            ? 'LINK AN EMAIL'
                            : 'NO PASSWORD NEEDED',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'We will send a one-time sign-in link. Your email is '
                        'kept on this device briefly so the link cannot choose '
                        'a different account.',
                        style: TextStyle(color: AppColors.textBody),
                      ),
                      const SizedBox(height: Spacing.xl),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: Spacing.md),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: Spacing.xl),
                      FilledButton(
                        onPressed: _loading ? null : _send,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('SEND SIGN-IN LINK'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
