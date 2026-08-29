import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _createError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' =>
          'That email already has an account. Sign in instead.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' =>
          'Use a stronger password with at least 8 characters.',
        'network-request-failed' =>
          'You appear to be offline. Reconnect and try again.',
        'too-many-requests' =>
          'Too many attempts. Wait a moment before trying again.',
        _ => 'Your account could not be created. Try again.',
      };
    }
    return 'Your account could not be created. Try again.';
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      try {
        await ref.read(authRepositoryProvider).sendEmailVerification();
      } catch (_) {
        // The app gate now owns recovery. It shows a resend action without
        // deleting the successfully created Firebase account.
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _createError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CREATE ACCOUNT')),
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
                'JOIN THE TERRACE',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Spacing.sm),
              const Text(
                'Create your login first. We will verify your email, then '
                'set up your supporter profile.',
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
                  helperText: 'At least 8 characters.',
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.length < 8
                    ? 'At least 8 characters.'
                    : null,
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirm
                        ? 'Show confirmation password'
                        : 'Hide confirmation password',
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _loading ? null : _signUp(),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match.'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.lg),
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
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('CREATE ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
