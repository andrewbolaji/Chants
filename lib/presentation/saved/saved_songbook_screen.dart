import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:chants/presentation/saved/saved_songbook_widgets.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedSongbookScreen extends ConsumerWidget {
  final String uid;

  const SavedSongbookScreen({super.key, required this.uid});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset saved copy?'),
        content: const Text(
          'This removes every Matchday Songbook item saved by this account '
          'on this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('RESET LOCAL COPY'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(savedSongbookRepositoryProvider).resetLocalCopy(uid);
    ref.invalidate(savedSongbookProvider(uid));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('MATCHDAY SONGBOOK')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.valueOrNull?.uid != uid) {
      return Scaffold(
        appBar: AppBar(title: const Text('MATCHDAY SONGBOOK')),
        body: const EmptyState(
          headline: 'SAVED COPY LOCKED',
          message: 'Sign in with the account that saved this device copy.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final saved = ref.watch(savedSongbookProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('MATCHDAY SONGBOOK')),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is UnsupportedSavedSongbookVersion) {
            return const _SavedStorageError(
              headline: 'UPDATE CHANTS TO OPEN THIS COPY',
              message:
                  'This Matchday Songbook was written by a newer app version. Your saved file has not been changed.',
            );
          }
          return _SavedStorageError(
            headline: 'SAVED COPY NEEDS ATTENTION',
            message:
                'Chants could not safely read this device copy. The file has been preserved.',
            actionLabel: 'RESET LOCAL COPY',
            onAction: () => _reset(context, ref),
          );
        },
        data: (songbook) {
          final overview = projectSavedSongbook(songbook);
          if (overview.clubs.isEmpty && overview.individualChants.isEmpty) {
            return EmptyState(
              headline: 'PACK YOUR MATCHDAY SONGBOOK',
              message:
                  'Save a club Songbook or one chant before you head to the ground.',
              icon: Icons.bookmark_add_outlined,
              actionLabel: 'FIND A CLUB',
              onAction: () => Navigator.pop(context),
            );
          }

          final items = <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xs,
              ),
              child: SectionEyebrow(text: 'Saved on this device', gold: true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                'Ready when the signal drops. Refresh dates tell you how current each copy is.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ];
          if (overview.clubs.isNotEmpty) {
            items.add(const _SavedSectionHeader('CLUB SONGBOOKS'));
            for (final club in overview.clubs) {
              items.add(
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.library_music_outlined),
                    title: Text(
                      club.team.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${club.chants.length} ${club.chants.length == 1 ? 'chant' : 'chants'}  •  ${savedSongbookDate(club.refreshedAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.savedClub,
                      arguments: SavedClubRouteArguments(
                        uid: uid,
                        teamId: club.team.id,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
          if (overview.individualChants.isNotEmpty) {
            items.add(const _SavedSectionHeader('SAVED CHANTS'));
            for (final savedChant in overview.individualChants) {
              items.add(
                SavedChantCard(
                  chant: savedChant.chant,
                  teamName: savedChant.team.name,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.savedChant,
                    arguments: SavedChantRouteArguments(
                      uid: uid,
                      chantId: savedChant.chant.id,
                    ),
                  ),
                ),
              );
            }
          }
          items.add(const SizedBox(height: Spacing.xxxl));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        },
      ),
    );
  }
}

class _SavedSectionHeader extends StatelessWidget {
  final String text;

  const _SavedSectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xl,
        Spacing.lg,
        Spacing.sm,
      ),
      child: SectionEyebrow(text: text),
    );
  }
}

class _SavedStorageError extends StatelessWidget {
  final String headline;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SavedStorageError({
    required this.headline,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sd_storage_outlined,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: Spacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
