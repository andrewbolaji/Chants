import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:chants/presentation/saved/saved_songbook_widgets.dart';
import 'package:chants/presentation/shared/club_signal.dart';
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
    final signalTheme = ClubSignalTheme.from(Theme.of(context));
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      return Theme(
        data: signalTheme,
        child: Scaffold(
          appBar: _appBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (auth.valueOrNull?.uid != uid) {
      return Theme(
        data: signalTheme,
        child: Scaffold(
          appBar: _appBar(),
          body: const ClubSignalState(
            headline: 'Saved copy locked',
            message: 'Sign in with the account that saved this device copy.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }
    final saved = ref.watch(savedSongbookProvider(uid));
    return Theme(
      data: signalTheme,
      child: Scaffold(
        appBar: _appBar(),
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
              return ClubSignalState(
                headline: 'Pack your Matchday Songbook',
                message:
                    'Save a club Songbook or one chant before you head to the ground.',
                icon: Icons.bookmark_add_outlined,
                actionLabel: 'FIND A CLUB',
                onAction: () => Navigator.pop(context),
              );
            }

            final items = <Widget>[
              const ClubSignalHeader(
                eyebrow: 'Saved on this device',
                title: 'Ready for the ground',
                message:
                    'Refresh dates show how current each copy is. Your saved chants remain available when the signal drops.',
              ),
            ];
            if (overview.clubs.isNotEmpty) {
              items.add(const _SavedSectionHeader('CLUB SONGBOOKS'));
              for (final club in overview.clubs) {
                items.add(
                  Card(
                    child: ListTile(
                      minTileHeight: 72,
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.signalForest,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          club.team.name.trim().isEmpty
                              ? '?'
                              : club.team.name.trim()[0].toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Anton',
                            fontSize: 17,
                            color: AppColors.signalPaper,
                          ),
                        ),
                      ),
                      title: Text(
                        club.team.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Anton',
                          fontSize: 17,
                          color: AppColors.signalInk,
                          letterSpacing: 0.3,
                        ),
                      ),
                      subtitle: Text(
                        '${club.chants.length} ${club.chants.length == 1 ? 'chant' : 'chants'}  •  ${savedSongbookDate(club.refreshedAt)}',
                        style: const TextStyle(
                          color: AppColors.signalTextMuted,
                        ),
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
                    signalAppearance: true,
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
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      toolbarHeight: 68,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CLUB SIGNAL',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.signalGold,
              letterSpacing: 1.1,
            ),
          ),
          Text('MATCHDAY SONGBOOK'),
        ],
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
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.signalForestMuted,
          letterSpacing: 1.0,
        ),
      ),
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
