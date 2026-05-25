import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
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
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Wrong email or password. Check both and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chants',
                  style: textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Know the words.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xxxl),
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
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your password.' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: Spacing.md),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.signUp),
                  child: const Text('No account yet? Sign up.'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.passwordReset),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
