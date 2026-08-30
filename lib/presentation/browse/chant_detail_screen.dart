import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:chants/presentation/comments/comment_section.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:chants/presentation/shared/chant_reading_content.dart';
import 'package:chants/presentation/shared/vote_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChantDetailScreen extends ConsumerStatefulWidget {
  final Chant chant;
  final Team? team;

  const ChantDetailScreen({super.key, required this.chant, this.team});

  @override
  ConsumerState<ChantDetailScreen> createState() => _ChantDetailScreenState();
}

class _ChantDetailScreenState extends ConsumerState<ChantDetailScreen> {
  bool _saving = false;
  bool _sharing = false;

  Future<void> _shareChant({
    required Chant chant,
    required BuildContext shareButtonContext,
  }) async {
    if (_sharing || chant.hidden || chant.removed) return;
    final renderObject = shareButtonContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _showShareError();
      return;
    }
    final sharePositionOrigin =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (!isValidSharePositionOrigin(sharePositionOrigin)) {
      _showShareError();
      return;
    }

    setState(() => _sharing = true);
    try {
      final publicUrl = await ref
          .read(publicShareRepositoryProvider)
          .resolve(PublicShareTarget.chant, chant.id);
      if (!mounted) return;
      final payload = ChantSharePayload.fromChant(
        chant: chant,
        teamName: widget.team?.name,
        publicUrl: publicUrl,
      );
      await ref
          .read(chantShareGatewayProvider)
          .share(payload, sharePositionOrigin: sharePositionOrigin);
    } catch (_) {
      if (mounted) _showShareError();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showShareError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open sharing. Try again.')),
    );
  }

  Future<void> _toggleSaved({
    required String uid,
    required Chant chant,
    required SavedSongbook songbook,
  }) async {
    if (_saving) return;
    final isIndividual = songbook.individualSnapshots.containsKey(chant.id);
    final club = _clubContaining(songbook, chant.id);

    if (!isIndividual && club != null) {
      await Navigator.pushNamed(
        context,
        AppRouter.savedClub,
        arguments: SavedClubRouteArguments(uid: uid, teamId: club.team.id),
      );
      return;
    }

    if (isIndividual) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove saved chant?'),
          content: Text(
            club == null
                ? 'This removes the chant from this device.'
                : 'This removes the individual save. The chant will still be '
                      'available through ${club.team.name}.',
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
    }

    setState(() => _saving = true);
    try {
      if (isIndividual) {
        await ref
            .read(savedSongbookRepositoryProvider)
            .removeIndividual(uid: uid, chantId: chant.id);
      } else {
        await ref
            .read(savedSongbookServiceProvider)
            .saveIndividual(
              uid: uid,
              chantId: chant.id,
              teamId: chant.teamId,
              knownTeam: widget.team,
            );
      }
      ref.invalidate(savedSongbookProvider(uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndividual
                ? 'Removed the individual save from this device.'
                : 'Saved for matchday on this device.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndividual
                ? 'Could not remove the saved chant. Try again.'
                : 'Could not save a fresh copy. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final saved = user == null
        ? null
        : ref.watch(savedSongbookProvider(user.uid));
    final chantStream = ref
        .watch(chantRepositoryProvider)
        .chantStream(widget.chant.id);

    return StreamBuilder<LiveChantSnapshot>(
      stream: chantStream,
      initialData: LiveChantSnapshot(chant: widget.chant, isFromCache: true),
      builder: (context, snapshot) {
        final current = snapshot.data;
        final live = current?.chant ?? widget.chant;
        final actionsEnabled =
            snapshot.connectionState == ConnectionState.active &&
            !snapshot.hasError &&
            current != null &&
            !current.isFromCache &&
            current.chant != null &&
            !current.chant!.hidden &&
            !current.chant!.removed;
        final songbook = saved?.valueOrNull;
        final isIndividual =
            songbook?.individualSnapshots.containsKey(live.id) ?? false;
        final club = songbook == null
            ? null
            : _clubContaining(songbook, live.id);
        final isSaved = isIndividual || club != null;
        final saveActionEnabled = isSaved || actionsEnabled;
        final savedTooltip = _saving
            ? 'Saving for matchday'
            : club != null && !isIndividual
            ? 'Saved with club'
            : isIndividual
            ? 'Saved individually'
            : 'Save for matchday';

        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            actions: [
              if (user != null)
                Semantics(
                  label: savedTooltip,
                  button: true,
                  child: IconButton(
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                          ),
                    tooltip: savedTooltip,
                    onPressed: _saving || songbook == null || !saveActionEnabled
                        ? null
                        : () => _toggleSaved(
                            uid: user.uid,
                            chant: live,
                            songbook: songbook,
                          ),
                  ),
                ),
              Builder(
                builder: (shareButtonContext) => Semantics(
                  label: 'Share this chant',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: 'Share this chant',
                    onPressed: _sharing || !actionsEnabled
                        ? null
                        : () => _shareChant(
                            chant: live,
                            shareButtonContext: shareButtonContext,
                          ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Report this chant',
                onPressed: !actionsEnabled
                    ? null
                    : () {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign in to report this chant.'),
                            ),
                          );
                          return;
                        }
                        showReportSheet(
                          context: context,
                          target: ReportChant(live.id),
                          ref: ref,
                        );
                      },
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VoteControls(
                    key: ValueKey(live.id),
                    chant: live,
                    large: true,
                    enabled: actionsEnabled,
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChantReadingContent(
                  title: live.title,
                  lyrics: live.lyrics,
                  tuneName: live.tuneName,
                  contextNotes: live.contextNotes,
                  variations: live.variations,
                  provenanceLabel: ChantProvenanceLabel(chant: live),
                  evidence: live.evidence,
                  showMediaPlaceholder: live.mediaType != 'none',
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      0,
                      Spacing.lg,
                      Spacing.xl,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: actionsEnabled
                            ? () => Navigator.pushNamed(
                                context,
                                AppRouter.performChant,
                                arguments: live,
                              )
                            : null,
                        icon: const Icon(Icons.videocam_outlined),
                        label: const Text('PERFORM THIS CHANT'),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('suggest-chant-update'),
                        onPressed: actionsEnabled
                            ? () {
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sign in to suggest a chant update.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.suggestChantUpdate,
                                  arguments: live,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('SUGGEST AN EDIT'),
                      ),
                      const SizedBox(height: Spacing.xs),
                      const Text(
                        'Wrong, dated, or another version? Tell us here. '
                        'Use Report for abuse or unsafe content.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CommentSection(
                  chantId: live.id,
                  commentCount: live.commentCount,
                  actionsEnabled: actionsEnabled,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SavedClubSongbook? _clubContaining(SavedSongbook songbook, String chantId) {
    for (final club in songbook.clubSnapshots.values) {
      if (club.chants.any((chant) => chant.id == chantId)) return club;
    }
    return null;
  }
}
