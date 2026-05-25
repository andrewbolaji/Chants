import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (cred.user != null) {
        await ref.read(profileRepositoryProvider).createProfile(
              userId: cred.user!.uid,
              displayName: _displayNameController.text.trim(),
            );
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not create your account. '
            'Try a different email or a stronger password.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: Spacing.xl),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display name'),
                autofillHints: const [AutofillHints.username],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pick a display name.';
                  if (v.trim().length > 50) return '50 characters max.';
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email.' : null,
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => v == null || v.length < 6
                    ? 'At least 6 characters.'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ],
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
