import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';

class AccountDeletionPendingScreen extends StatefulWidget {
  final Future<void> Function() onSignOut;

  const AccountDeletionPendingScreen({super.key, required this.onSignOut});

  @override
  State<AccountDeletionPendingScreen> createState() =>
      _AccountDeletionPendingScreenState();
}

class _AccountDeletionPendingScreenState
    extends State<AccountDeletionPendingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign out. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    Icons.hourglass_top_rounded,
                    size: 44,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: Spacing.lg),
                  const Center(child: SectionEyebrow(text: 'ACCOUNT DELETION')),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'DELETION IN PROGRESS',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  const Text(
                    'Your request is safely queued. Chants is removing your '
                    'private activity and anonymizing the community posts '
                    'that stay. You can close the app while it finishes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
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
                    onPressed: _busy ? null : _signOut,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SIGN OUT'),
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
