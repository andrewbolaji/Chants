import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/browse/discovery_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chants'),
        actions: [
          // Operator-only moderation link
          StreamBuilder(
            stream: ref.watch(authStateProvider).whenData((user) {
              if (user == null) return const Stream.empty();
              return ref
                  .watch(profileRepositoryProvider)
                  .profileStream(user.uid);
            }).value,
            builder: (context, snap) {
              final profile = snap.data;
              if (profile != null && profile.isOperator) {
                return IconButton(
                  icon: const Icon(Icons.shield_outlined),
                  tooltip: 'Moderation',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.moderation),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'feedback':
                  Navigator.pushNamed(context, AppRouter.feedback);
                case 'policy':
                  Navigator.pushNamed(context, AppRouter.contentPolicy);
                case 'signout':
                  ref.read(authRepositoryProvider).signOut();
                case 'delete':
                  _showDeleteAccountDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'feedback',
                child: Text('Send feedback', style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ),
              PopupMenuItem(
                value: 'policy',
                child: Text('Content policy', style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Text('Sign out', style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete account', style: textTheme.bodyMedium?.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: Spacing.sm),
          // Premier League entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.competition,
                arguments: {
                  'id': 'premier-league',
                  'name': 'Premier League',
                },
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premier League',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'All 20 clubs',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textFaint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(indent: Spacing.lg, endIndent: Spacing.lg),
          const SizedBox(height: Spacing.sm),

          // Discovery shuffle
          const DiscoverySection(),
        ],
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete your account?'),
      content: const Text(
        'This will permanently delete your account, your votes, your reports, '
        'and your feedback. Your submitted chants will stay as community '
        'content with your name removed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete my account'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(moderationRepositoryProvider).deleteAccount();
    // Auth state change will redirect to sign-in
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not delete your account. Try again or contact us via feedback.'),
      ),
    );
  }
}
