import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('BLOCKED USERS')),
      body: user == null
          ? const Center(child: Text('Sign in to manage blocked users.'))
          : ref
                .watch(blockedUsersProvider(user.uid))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Could not load blocked users. Try again.'),
                  ),
                  data: (blockedUsers) {
                    if (blockedUsers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Text(
                            'You have not blocked anyone.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      itemCount: blockedUsers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final blockedUser = blockedUsers[index];
                        return ListTile(
                          title: Text(blockedUser.blockedDisplayName),
                          trailing: TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(blockRepositoryProvider)
                                    .unblockUser(
                                      blockerId: user.uid,
                                      blockedUserId: blockedUser.blockedUserId,
                                    );
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not unblock this user. Try again.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Unblock'),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
