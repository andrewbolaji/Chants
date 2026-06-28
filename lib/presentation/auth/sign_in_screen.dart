import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
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
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      debugPrint('[SignIn] Error: $e');
      if (e is FirebaseAuthException) {
        debugPrint('[SignIn] code=${e.code} message=${e.message}');
      }
      if (!mounted) return;
      setState(() {
        _error = 'Wrong email or password. Check both and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Anton hero title
                const Text(
                  'CHANTS',
                  style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 40,
                    color: AppColors.textHeadline,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Know the words.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textBody,
                      ),
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
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your password.' : null,
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
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SIGN IN'),
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
