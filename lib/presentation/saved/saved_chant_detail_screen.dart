import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/presentation/saved/saved_songbook_widgets.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:chants/presentation/shared/chant_reading_content.dart';
import 'package:chants/presentation/shared/club_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedChantDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  final String chantId;
  final String? teamId;

  const SavedChantDetailScreen({
    super.key,
    required this.uid,
    required this.chantId,
    this.teamId,
  });

  @override
  ConsumerState<SavedChantDetailScreen> createState() =>
      _SavedChantDetailScreenState();
}

class _SavedChantDetailScreenState
    extends ConsumerState<SavedChantDetailScreen> {
  bool _busy = false;
  String? _refreshError;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _refreshError = null;
    });
    try {
      if (widget.teamId != null) {
        await ref
            .read(savedSongbookServiceProvider)
            .refreshClub(uid: widget.uid, teamId: widget.teamId!);
      } else {
        await ref
            .read(savedSongbookServiceProvider)
            .refreshIndividual(uid: widget.uid, chantId: widget.chantId);
      }
      ref.invalidate(savedSongbookProvider(widget.uid));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved copy refreshed.')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _refreshError = 'Could not refresh. Your saved copy is still here.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(SavedSongbook songbook) async {
    final isClubCopy = widget.teamId != null;
    final alsoInClub =
        !isClubCopy &&
        songbook.clubSnapshots.values.any(
          (club) => club.chants.any((chant) => chant.id == widget.chantId),
        );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isClubCopy ? 'Remove club Songbook?' : 'Remove saved chant?',
        ),
        content: Text(
          isClubCopy
              ? 'This removes the whole club copy from this device. Individually saved chants will stay.'
              : alsoInClub
              ? 'This removes the individual save. The chant will still be available through its saved club.'
              : 'This removes the chant from this device.',
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
      if (isClubCopy) {
        await ref
            .read(savedSongbookRepositoryProvider)
            .removeClub(uid: widget.uid, teamId: widget.teamId!);
      } else {
        await ref
            .read(savedSongbookRepositoryProvider)
            .removeIndividual(uid: widget.uid, chantId: widget.chantId);
      }
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
          appBar: _appBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (auth.valueOrNull?.uid != widget.uid) {
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
    final saved = ref.watch(savedSongbookProvider(widget.uid));
    return Theme(
      data: signalTheme,
      child: Scaffold(
        appBar: _appBar(),
        body: saved.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const ClubSignalState(
            headline: 'Saved copy unavailable',
            message: 'Return to Matchday Songbook and try again.',
            icon: Icons.sd_storage_outlined,
          ),
          data: (songbook) {
            late final SavedChantSnapshot? chant;
            late final String teamName;
            late final DateTime refreshedAt;
            if (widget.teamId != null) {
              final club = songbook.clubSnapshots[widget.teamId];
              chant = club == null
                  ? null
                  : _findChant(club.chants, widget.chantId);
              teamName = club?.team.name ?? '';
              refreshedAt =
                  club?.refreshedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            } else {
              final individual = songbook.individualSnapshots[widget.chantId];
              chant = individual?.chant;
              teamName = individual?.team.name ?? '';
              refreshedAt =
                  individual?.refreshedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
            }
            if (chant == null) {
              return ClubSignalState(
                headline: 'Saved chant removed',
                message: 'This chant is no longer in the local copy.',
                icon: Icons.bookmark_remove_outlined,
                actionLabel: 'GO BACK',
                onAction: () => Navigator.pop(context),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SavedFreshnessNotice(
                    refreshedAt: refreshedAt,
                    message:
                        '$teamName saved on this device. Live votes and comments are not included.',
                    signalAppearance: true,
                  ),
                  if (_refreshError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                      ),
                      child: Text(
                        _refreshError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ChantReadingContent(
                    title: chant.title,
                    lyrics: chant.lyrics,
                    tuneName: chant.tuneName,
                    contextNotes: chant.contextNotes,
                    variations: chant.variations,
                    provenanceLabel: ChantProvenanceLabel.fromValues(
                      status: chant.status,
                      origin: chant.origin,
                      signalAppearance: true,
                    ),
                    signalAppearance: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _refresh,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        widget.teamId == null
                            ? 'REFRESH SAVED CHANT'
                            : 'REFRESH CLUB COPY',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _remove(songbook),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      label: Text(
                        widget.teamId == null
                            ? 'REMOVE SAVED CHANT'
                            : 'REMOVE CLUB FROM DEVICE',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
              ),
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
            'MATCHDAY COPY',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.signalGold,
              letterSpacing: 1.1,
            ),
          ),
          Text('SAVED CHANT'),
        ],
      ),
    );
  }

  SavedChantSnapshot? _findChant(
    Iterable<SavedChantSnapshot> chants,
    String id,
  ) {
    for (final chant in chants) {
      if (chant.id == id) return chant;
    }
    return null;
  }
}
