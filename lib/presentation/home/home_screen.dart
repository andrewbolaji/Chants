import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/browse/discovery_section.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHANTS'),
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
                child: Text('Send feedback',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textHeadline)),
              ),
              PopupMenuItem(
                value: 'policy',
                child: Text('Content policy',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textHeadline)),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Text('Sign out',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textHeadline)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete account',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // Search bar (compact, ~78% of original footprint)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search chants...',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.textFaint,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.smMd,
                ),
                prefixIcon: const Icon(Icons.search, size: 16),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Premier League entry
          if (_query.isEmpty) ...[
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
                              'PREMIER LEAGUE',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: Spacing.xs),
                            const SectionEyebrow(text: 'All 20 clubs'),
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
          ],

          // Discovery shuffle (or search results)
          DiscoverySection(searchQuery: _query),
        ],
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(
    BuildContext context, WidgetRef ref) async {
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
          child: const Text('DELETE MY ACCOUNT'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(moderationRepositoryProvider).deleteAccount();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Could not delete your account. Try again or contact us via feedback.'),
      ),
    );
  }
}
