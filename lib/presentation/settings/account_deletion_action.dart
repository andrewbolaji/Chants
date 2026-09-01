import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (uid == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete your account?'),
      content: const Text(
        'This starts permanent deletion of your account, public creator '
        'profile, private activity, submitted chant text, comments, replies, '
        'drafts, and owned performance uploads. Comment and reply rows can '
        'remain only as non-identifying structural tombstones. Restricted '
        'safety records created by someone else may retain your account ID as '
        'their target until the record is deleted or de-identified under the '
        'Privacy Notice. Your Saved Matchday Songbook is locked immediately '
        'and removed once the request is confirmed. Media cleanup can '
        'continue after access is removed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('DELETE MY ACCOUNT'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(accountDeletionServiceProvider).deleteAccount(uid);
  } on AccountDeletionRequestUnconfirmedException {
    if (!context.mounted) return;
    ref.invalidate(savedSongbookDeletionStateProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'We could not confirm whether deletion started. Your Saved Songbook '
          'is locked for safety. Try again to confirm the request.',
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ref.invalidate(savedSongbookDeletionStateProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deletion could not start. Try again.')),
    );
  }
}
