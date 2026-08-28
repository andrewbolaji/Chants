import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountActionsMenu extends ConsumerWidget {
  const AccountActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = user == null
        ? null
        : ref.watch(userProfileProvider(user.uid)).valueOrNull;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (profile?.isOperator == true)
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Moderation',
            onPressed: () => Navigator.pushNamed(context, AppRouter.moderation),
          ),
        PopupMenuButton<String>(
          tooltip: 'Account and settings',
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
              color: AppColors.surface,
            ),
            child: const Icon(Icons.more_horiz, size: 20),
          ),
          onSelected: (value) {
            switch (value) {
              case 'feedback':
                Navigator.pushNamed(context, AppRouter.feedback);
              case 'policy':
                Navigator.pushNamed(context, AppRouter.contentPolicy);
              case 'blocked':
                Navigator.pushNamed(context, AppRouter.blockedUsers);
              case 'signout':
                ref.read(authRepositoryProvider).signOut();
              case 'delete':
                showDeleteAccountDialog(context, ref);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'feedback',
              child: Text(
                'Send feedback',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHeadline,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'policy',
              child: Text(
                'Content policy',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHeadline,
                ),
              ),
            ),
            if (user != null)
              PopupMenuItem(
                value: 'blocked',
                child: Text(
                  'Blocked users',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
            PopupMenuItem(
              value: 'signout',
              child: Text(
                'Sign out',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHeadline,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete account',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
        'profile, votes, likes, reports, feedback, and blocks. Your submitted '
        'chants, comments, and replies stay as community content with your '
        'name removed. Your Saved Matchday Songbook is locked immediately '
        'and removed once the request is confirmed. Safety records for '
        'reports you sent keep neither your account ID nor report text. '
        'Safety records about your account may retain its ID for moderation '
        'history. Cleanup may continue briefly in the background. This cannot '
        'be undone.',
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
