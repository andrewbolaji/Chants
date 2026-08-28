import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/creator_notification.dart';
import 'package:chants/presentation/feed/performance_comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorNotificationsScreen extends ConsumerWidget {
  const CreatorNotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    CreatorNotification notification,
  ) async {
    if (!notification.read) {
      try {
        await ref
            .read(creatorNotificationRepositoryProvider)
            .markRead(notification.id);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark this activity as read.'),
          ),
        );
      }
    }
    if (!context.mounted) return;
    if (notification.type == CreatorNotificationType.creatorFollow) {
      await Navigator.pushNamed(
        context,
        AppRouter.creatorProfile,
        arguments: notification.actorId,
      );
      return;
    }
    final performanceId = notification.performanceId;
    if (performanceId == null) return;
    try {
      final performance = await ref
          .read(performanceRepositoryProvider)
          .fetchVisibleById(performanceId);
      if (!context.mounted) return;
      if (performance == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This conversation is unavailable.')),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PerformanceCommentsSheet(
          performanceId: performance.id,
          chantTitle: performance.chantTitle,
          highlightedCommentId: notification.commentId,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This conversation is unavailable.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('ACTIVITY')),
      body: user == null
          ? const Center(child: Text('Sign in to see activity.'))
          : StreamBuilder<List<CreatorNotification>>(
              stream: ref
                  .watch(creatorNotificationRepositoryProvider)
                  .notifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: Text('Activity could not be loaded.'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifications = snapshot.data!;
                if (notifications.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: Text(
                        'No activity yet. Follows, mentions, and replies will show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      key: ValueKey<String>(
                        'creator-notification-${notification.id}',
                      ),
                      minTileHeight: 72,
                      tileColor: notification.read
                          ? null
                          : AppColors.chantLab.withValues(alpha: 0.08),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.chantLab,
                        child: Text(
                          notification.actorDisplayName.isEmpty
                              ? '?'
                              : notification.actorDisplayName[0].toUpperCase(),
                        ),
                      ),
                      title: Text(_message(notification)),
                      subtitle: Text('@${notification.actorHandle}'),
                      trailing: notification.read
                          ? null
                          : Semantics(
                              key: ValueKey<String>(
                                'unread-notification-${notification.id}',
                              ),
                              container: true,
                              label: 'Unread',
                              child: const CircleAvatar(
                                radius: 5,
                                backgroundColor: AppColors.gold,
                              ),
                            ),
                      onTap: () => _open(context, ref, notification),
                    );
                  },
                );
              },
            ),
    );
  }

  String _message(CreatorNotification notification) {
    return switch (notification.type) {
      CreatorNotificationType.creatorFollow =>
        '${notification.actorDisplayName} followed you',
      CreatorNotificationType.performanceMention =>
        '${notification.actorDisplayName} mentioned you',
      CreatorNotificationType.performanceReply =>
        '${notification.actorDisplayName} replied to you',
    };
  }
}
