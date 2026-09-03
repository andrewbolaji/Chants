import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/saved/saved_songbook_widgets.dart';
import 'package:chants/presentation/shared/club_signal.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedClubScreen extends ConsumerStatefulWidget {
  final String uid;
  final String teamId;

  const SavedClubScreen({super.key, required this.uid, required this.teamId});

  @override
  ConsumerState<SavedClubScreen> createState() => _SavedClubScreenState();
}

class _SavedClubScreenState extends ConsumerState<SavedClubScreen> {
  bool _busy = false;
  String? _refreshError;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _refreshError = null;
    });
    try {
      final result = await ref
          .read(savedSongbookServiceProvider)
          .refreshClub(uid: widget.uid, teamId: widget.teamId);
      ref.invalidate(savedSongbookProvider(widget.uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved copy refreshed with ${result.chantCount} chants.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshError = 'Could not refresh. Your saved copy is still here.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove club Songbook?'),
        content: const Text(
          'This removes the club copy from this device. Chants you saved '
          'individually will stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVE FROM DEVICE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(savedSongbookRepositoryProvider)
          .removeClub(uid: widget.uid, teamId: widget.teamId);
      ref.invalidate(savedSongbookProvider(widget.uid));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signalTheme = ClubSignalTheme.from(Theme.of(context));
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      return Theme(
        data: signalTheme,
        child: Scaffold(
          appBar: _appBar('SAVED CLUB'),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (auth.valueOrNull?.uid != widget.uid) {
      return Theme(
        data: signalTheme,
        child: Scaffold(
          appBar: _appBar('SAVED CLUB'),
          body: const ClubSignalState(
            headline: 'Saved copy locked',
            message: 'Sign in with the account that saved this device copy.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }
    final saved = ref.watch(savedSongbookProvider(widget.uid));
    final club = saved.valueOrNull?.clubSnapshots[widget.teamId];
    return Theme(
      data: signalTheme,
      child: Scaffold(
        appBar: _appBar(club?.team.name ?? 'SAVED CLUB'),
        body: saved.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const ClubSignalState(
            headline: 'Saved copy unavailable',
            message: 'Return to Matchday Songbook and try again.',
            icon: Icons.sd_storage_outlined,
          ),
          data: (songbook) {
            final current = songbook.clubSnapshots[widget.teamId];
            if (current == null) {
              return ClubSignalState(
                headline: 'Club copy removed',
                message: 'This club is no longer saved on this device.',
                icon: Icons.bookmark_remove_outlined,
                actionLabel: 'BACK TO SAVED',
                onAction: () => Navigator.pop(context),
              );
            }
            final items = <Widget>[
              SavedFreshnessNotice(
                refreshedAt: current.refreshedAt,
                message:
                    'This is a read-only device copy. Refresh when you have a connection.',
                signalAppearance: true,
              ),
              if (_refreshError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Text(
                    _refreshError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_busy ? 'REFRESHING' : 'REFRESH SAVED COPY'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.sm,
                  Spacing.lg,
                  Spacing.xs,
                ),
                child: SectionEyebrow(
                  text: 'Terrace Proven',
                  gold: true,
                  signalAppearance: true,
                ),
              ),
            ];
            if (current.chants.isEmpty) {
              items.add(
                const ClubSignalState(
                  headline: 'No saved chants remain',
                  message:
                      'The refresh completed, but this club has no visible Terrace Proven chants right now.',
                  icon: Icons.library_music_outlined,
                ),
              );
            } else {
              for (final chant in current.chants) {
                items.add(
                  SavedChantCard(
                    chant: chant,
                    teamName: current.team.name,
                    signalAppearance: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.savedChant,
                      arguments: SavedChantRouteArguments(
                        uid: widget.uid,
                        chantId: chant.id,
                        teamId: current.team.id,
                      ),
                    ),
                  ),
                );
              }
            }
            items.add(
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'REMOVE FROM DEVICE',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            );
            items.add(const SizedBox(height: Spacing.xl));
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => items[index],
            );
          },
        ),
      ),
    );
  }

  AppBar _appBar(String title) {
    return AppBar(
      toolbarHeight: 68,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MATCHDAY COPY',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.signalGold,
              letterSpacing: 1.1,
            ),
          ),
          Text(title.toUpperCase()),
        ],
      ),
    );
  }
}
