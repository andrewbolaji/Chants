import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/browse/discovery_section.dart';
import 'package:chants/presentation/settings/account_actions_menu.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final DateTime? risingEvaluationTime;
  final bool showAccountActions;

  const HomeScreen({
    super.key,
    this.risingEvaluationTime,
    this.showAccountActions = true,
  });

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
        actions: widget.showAccountActions
            ? const [AccountActionsMenu()]
            : null,
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

          DiscoverySection(
            searchQuery: _query,
            groupByTrust: true,
            risingEvaluationTime: widget.risingEvaluationTime,
          ),
        ],
      ),
    );
  }
}
