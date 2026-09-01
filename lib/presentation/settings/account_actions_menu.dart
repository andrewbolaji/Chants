import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/presentation/settings/account_deletion_action.dart';
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
                Navigator.pushNamed(context, AppRouter.policyHub);
              case 'blocked':
                Navigator.pushNamed(context, AppRouter.blockedUsers);
              case 'chant-updates':
                Navigator.pushNamed(context, AppRouter.myChantUpdates);
              case 'signin':
                Navigator.pushNamed(context, AppRouter.signInMethods);
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
                'Help and policies',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHeadline,
                ),
              ),
            ),
            if (user != null)
              PopupMenuItem(
                value: 'signin',
                child: Text(
                  'Sign-in methods',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
            if (user != null)
              PopupMenuItem(
                value: 'chant-updates',
                child: Text(
                  'My chant updates',
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
