import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/presentation/auth/auth_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  final bool linkToCurrentUser;

  const PhoneAuthScreen({super.key, required this.linkToCurrentUser});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  PhoneVerificationAttempt? _verificationAttempt;
  bool _consent = false;
  bool _loading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldown;
  String? _error;

  @override
  void dispose() {
    _verificationAttempt?.cancel();
    _cooldown?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _validPhone(String value) {
    return RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value.replaceAll(' ', ''));
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
        return;
      }
      setState(() => _cooldownSeconds -= 1);
    });
  }

  void _finishAuthentication() {
    if (!mounted) return;
    if (widget.linkToCurrentUser) {
      Navigator.pop(context, true);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _sendCode({bool resend = false}) async {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (!_validPhone(phone)) {
      setState(
        () => _error = 'Use international format, for example +447700900123.',
      );
      return;
    }
    if (!_consent) {
      setState(
        () => _error = 'Accept the phone verification disclosure to continue.',
      );
      return;
    }
    if (widget.linkToCurrentUser &&
        ref.read(authRepositoryProvider).currentUser == null) {
      setState(
        () => _error = 'Sign in again before connecting this phone number.',
      );
      return;
    }
    if (_loading || _cooldownSeconds > 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(
            phoneNumber: phone,
            linkToCurrentUser: widget.linkToCurrentUser,
            forceResendingToken: resend ? _resendToken : null,
            attempt: resend ? _verificationAttempt : null,
            onLateCredentialAccepted: _finishAuthentication,
          );
      if (!mounted) return;
      if (start.completedAutomatically) {
        _finishAuthentication();
        return;
      }
      setState(() {
        _verificationId = start.verificationId;
        _resendToken = start.resendToken;
        _verificationAttempt = start.attempt;
        _loading = false;
      });
      _startCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = authErrorMessage(error);
      });
    }
  }

  Future<void> _verifyCode() async {
    final verificationId = _verificationId;
    final code = _codeController.text.trim();
    if (verificationId == null || code.length < 6 || _loading) {
      setState(() => _error = 'Enter the 6-digit code from the message.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .completePhoneVerification(
            verificationId: verificationId,
            smsCode: code,
            linkToCurrentUser: widget.linkToCurrentUser,
            attempt: _verificationAttempt,
          );
      if (!mounted) return;
      _finishAuthentication();
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
    final codeSent = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('PHONE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.xl,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            Text(
              codeSent ? 'CHECK YOUR MESSAGES' : 'SIGN IN BY PHONE',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              codeSent
                  ? 'Enter the code we sent. It can expire, so use it soon.'
                  : 'Use a mobile number that can receive one verification message.',
              style: const TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: Spacing.xl),
            TextField(
              controller: _phoneController,
              enabled: !codeSent && !_loading,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '+44 7700 900123',
              ),
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            if (!codeSent) ...[
              const SizedBox(height: Spacing.md),
              CheckboxListTile(
                value: _consent,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _consent = value ?? false),
                title: const Text('I agree to phone verification.'),
                subtitle: const Text(
                  'Firebase sends and stores this number with Google for spam '
                  'and abuse prevention. SMS rates may apply.',
                ),
              ),
            ] else ...[
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '6-digit code'),
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                onSubmitted: (_) => _verifyCode(),
              ),
            ],
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
              onPressed: _loading || (!codeSent && _cooldownSeconds > 0)
                  ? null
                  : codeSent
                  ? _verifyCode
                  : _sendCode,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      codeSent
                          ? 'VERIFY CODE'
                          : _cooldownSeconds > 0
                          ? 'SEND AGAIN IN ${_cooldownSeconds}s'
                          : 'SEND CODE',
                    ),
            ),
            if (codeSent) ...[
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: _loading || _cooldownSeconds > 0
                    ? null
                    : () => _sendCode(resend: true),
                child: Text(
                  _cooldownSeconds > 0
                      ? 'RESEND IN ${_cooldownSeconds}s'
                      : 'RESEND CODE',
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _verificationAttempt?.cancel();
                        _verificationId = null;
                        _resendToken = null;
                        _verificationAttempt = null;
                        _codeController.clear();
                        _error = null;
                      }),
                child: const Text('CHANGE NUMBER'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
