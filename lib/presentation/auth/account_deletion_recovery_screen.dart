import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';

class AccountDeletionRecoveryScreen extends StatefulWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;
  final bool statusCheckFailed;

  const AccountDeletionRecoveryScreen({
    super.key,
    required this.onRetry,
    required this.onSignOut,
    this.statusCheckFailed = false,
  });

  @override
  State<AccountDeletionRecoveryScreen> createState() =>
      _AccountDeletionRecoveryScreenState();
}

class _AccountDeletionRecoveryScreenState
    extends State<AccountDeletionRecoveryScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(
    Future<void> Function() action, {
    required String fallbackError,
    bool classifyUnconfirmed = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AccountDeletionRequestUnconfirmedException {
      if (!mounted) return;
      setState(() {
        _error = classifyUnconfirmed
            ? 'We still could not confirm whether deletion started. '
                  'Your Saved Songbook remains locked. Try again when you '
                  'have a connection.'
            : fallbackError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = fallbackError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = widget.statusCheckFailed
        ? 'Chants could not safely resolve an earlier account deletion state '
              'on this device. Home will stay closed until recovery succeeds.'
        : 'We could not confirm whether deletion started. Your Saved Songbook '
              'is locked for safety. Retrying can confirm and continue the '
              'same permanent deletion request. It does not cancel it.';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 44,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: Spacing.lg),
                  const Center(child: SectionEyebrow(text: 'ACCOUNT DELETION')),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    widget.statusCheckFailed
                        ? 'RECOVERY NEEDED'
                        : 'REQUEST NOT CONFIRMED',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            widget.onRetry,
                            fallbackError: widget.statusCheckFailed
                                ? 'Could not recover this device state yet. '
                                      'Try again.'
                                : 'Could not retry the deletion request. Try again.',
                            classifyUnconfirmed: !widget.statusCheckFailed,
                          ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.statusCheckFailed
                                ? 'TRY RECOVERY'
                                : 'TRY DELETION AGAIN',
                          ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            widget.onSignOut,
                            fallbackError: 'Could not sign out. Try again.',
                          ),
                    child: const Text('SIGN OUT'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
