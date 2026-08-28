import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            error is FirebaseAuthException &&
                error.code == 'network-request-failed'
            ? 'You appear to be offline. Reconnect and try again.'
            : 'Wrong email or password. Check both and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(authFeatureConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('EMAIL')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.xl,
              Spacing.xl,
              Spacing.xxxl,
            ),
            children: [
              Text(
                'WELCOME BACK',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Spacing.sm),
              const Text(
                'Sign in to your Stage, clubs, and matchday Songbook.',
                style: TextStyle(color: AppColors.textBody),
              ),
              const SizedBox(height: Spacing.xl),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _loading ? null : _signIn(),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : null,
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
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SIGN IN'),
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.passwordReset),
                child: const Text('FORGOT PASSWORD?'),
              ),
              if (config.magicLinkEnabled)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRouter.magicLink,
                    arguments: false,
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('EMAIL ME A SIGN-IN LINK'),
                ),
              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.md),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.signUp),
                child: const Text('NEW HERE? CREATE AN ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
