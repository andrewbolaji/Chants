import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
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
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          'CHANTS',
          style: textTheme.headlineLarge?.copyWith(fontSize: 30),
        ),
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
            tooltip: 'Account and settings',
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
                color: AppColors.surface,
              ),
              child: const Icon(Icons.person_outline, size: 20),
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
                  _showDeleteAccountDialog(context, ref);
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
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text(
                'THE TERRACES, IN YOUR POCKET.',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: AppColors.textBody,
              ),
              decoration: InputDecoration(
                hintText: 'Search chants, clubs or players',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 20),
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
          const SizedBox(height: Spacing.md),

          if (_query.isEmpty && user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.72),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.md),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.savedSongbook,
                    arguments: user.uid,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bookmark_outline,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MATCHDAY SONGBOOK',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              const Text(
                                'Saved on this device • ready offline',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textFaint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],

          // Premier League entry
          if (_query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: AppColors.outline),
                ),
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
                      vertical: Spacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREMIER LEAGUE',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              const SectionEyebrow(text: '20 clubs'),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textFaint),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],

          DiscoverySection(searchQuery: _query, groupByTrust: true),
        ],
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (uid == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete your account?'),
      content: const Text(
        'This starts permanent deletion of your account, votes, likes, '
        'reports, feedback, and blocks. Your submitted chants, comments, and '
        'replies stay as community content with your name removed. Your '
        'Saved Matchday Songbook is locked immediately and removed once the '
        'request is confirmed. Safety records for reports you sent keep '
        'neither your account ID nor report text. Safety records about your '
        'account may retain its ID for moderation history. Cleanup may '
        'continue briefly in the background. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
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
