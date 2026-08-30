import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:chants/presentation/shared/evidence_link_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChantUpdateModerationTab extends ConsumerWidget {
  const ChantUpdateModerationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ChantUpdateSuggestion>>(
      stream: ref.watch(chantUpdateRepositoryProvider).operatorQueue(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Text('Chant updates could not be loaded.'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final open = snapshot.data!
            .where((suggestion) => !suggestion.isTerminal)
            .toList();
        if (open.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Text('No open chant updates.'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.sm),
          itemCount: open.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, index) =>
              _ChantUpdateCard(suggestion: open[index]),
        );
      },
    );
  }
}

class _ChantUpdateCard extends ConsumerStatefulWidget {
  final ChantUpdateSuggestion suggestion;

  const _ChantUpdateCard({required this.suggestion});

  @override
  ConsumerState<_ChantUpdateCard> createState() => _ChantUpdateCardState();
}

class _ChantUpdateCardState extends ConsumerState<_ChantUpdateCard> {
  bool _working = false;

  Future<void> _apply({
    required String action,
    required ChantUpdateResolution? resolution,
    required String? note,
    required bool stale,
    bool acknowledgeEvidenceReplacement = false,
  }) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await ref
          .read(chantUpdateRepositoryProvider)
          .moderate(
            suggestionId: widget.suggestion.id,
            action: action,
            resolutionKind: resolution,
            resolutionNote: note,
            acknowledgeStale: stale,
            acknowledgeEvidenceReplacement: acknowledgeEvidenceReplacement,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'acceptAndPromote'
                ? 'Evidence accepted. Chant is Terrace Proven.'
                : 'Chant update review saved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        ChantUpdateException(failure: ChantUpdateFailure.deletionInProgress) =>
          'Account deletion is in progress. This review cannot continue.',
        ChantUpdateException(failure: ChantUpdateFailure.chantUnavailable) =>
          'The chant is unavailable. Close the request with Not changed.',
        ChantUpdateException(failure: ChantUpdateFailure.stale) =>
          'The chant changed. Review the current version before continuing.',
        ChantUpdateException(failure: ChantUpdateFailure.evidenceConflict) =>
          'The chant already has different proof. Confirm replacement to continue.',
        ChantUpdateException(failure: ChantUpdateFailure.alreadyClosed) =>
          'This request was already closed.',
        ChantUpdateException(failure: ChantUpdateFailure.actionMismatch) =>
          'That action does not match this request.',
        _ => 'Could not save this review. Refresh the chant and try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _planOrResolve({
    required String action,
    required bool stale,
  }) async {
    var resolution =
        widget.suggestion.resolutionKind ??
        (widget.suggestion.kind == ChantUpdateKind.variation
            ? ChantUpdateResolution.variation
            : widget.suggestion.category == ChantUpdateCategory.era
            ? ChantUpdateResolution.era
            : ChantUpdateResolution.primary);
    var note = widget.suggestion.resolutionNote ?? '';
    var acknowledged = !stale;
    final input = await showDialog<_ReviewInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(action == 'plan' ? 'Plan this update' : 'Mark updated'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ChantUpdateResolution>(
                  initialValue: resolution,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Canonical path',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ChantUpdateResolution.primary,
                      child: Text('Primary wording'),
                    ),
                    DropdownMenuItem(
                      value: ChantUpdateResolution.variation,
                      child: Text('Add as a variation'),
                    ),
                    DropdownMenuItem(
                      value: ChantUpdateResolution.era,
                      child: Text('Current or historic state'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => resolution = value);
                    }
                  },
                ),
                const SizedBox(height: Spacing.md),
                TextFormField(
                  initialValue: note,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note for the submitter',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setDialogState(() => note = value),
                ),
                if (stale)
                  CheckboxListTile(
                    value: acknowledged,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I reviewed the current chant, which changed after submission.',
                    ),
                    onChanged: (value) =>
                        setDialogState(() => acknowledged = value ?? false),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: !acknowledged
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      _ReviewInput(
                        resolution: resolution,
                        note: note.trim().isEmpty ? null : note.trim(),
                        acknowledgeStale: stale,
                      ),
                    ),
              child: Text(action == 'plan' ? 'MARK PLANNED' : 'MARK UPDATED'),
            ),
          ],
        ),
      ),
    );
    if (input == null) return;
    await _apply(
      action: action,
      resolution: input.resolution,
      note: input.note,
      stale: input.acknowledgeStale,
    );
  }

  Future<void> _closeWithoutChange({required bool stale}) async {
    var note = '';
    var acknowledged = !stale;
    final input = await showDialog<_ReviewInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Close without change'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: note,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason shown to the submitter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setDialogState(() => note = value),
              ),
              if (stale)
                CheckboxListTile(
                  value: acknowledged,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I reviewed the current chant, which changed after submission.',
                  ),
                  onChanged: (value) =>
                      setDialogState(() => acknowledged = value ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: note.trim().isEmpty || !acknowledged
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      _ReviewInput(
                        resolution: null,
                        note: note.trim(),
                        acknowledgeStale: stale,
                      ),
                    ),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
    if (input == null) return;
    await _apply(
      action: 'notChanged',
      resolution: null,
      note: input.note,
      stale: input.acknowledgeStale,
    );
  }

  Future<void> _acceptEvidence({
    required bool promote,
    required bool replacesEvidence,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          replacesEvidence
              ? 'Replace current proof?'
              : promote
              ? 'Accept proof and promote?'
              : 'Accept proof?',
        ),
        content: Text(
          replacesEvidence
              ? 'This replaces the chant\'s current public proof with the '
                    'reviewed proposal. The prior link remains only in the '
                    'private operator audit.'
              : promote
              ? 'This attaches the reviewed link and marks the chant Terrace '
                    'Proven. The creator will receive a private activity update.'
              : 'This attaches the reviewed link without changing the chant\'s '
                    'current trust status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              replacesEvidence
                  ? 'REPLACE EVIDENCE'
                  : promote
                  ? 'ACCEPT & PROMOTE'
                  : 'ACCEPT EVIDENCE',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _apply(
      action: promote ? 'acceptAndPromote' : 'acceptEvidence',
      resolution: ChantUpdateResolution.evidence,
      note: 'Evidence reviewed and accepted.',
      stale: false,
      acknowledgeEvidenceReplacement: replacesEvidence,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveChantSnapshot>(
      stream: ref
          .watch(chantRepositoryProvider)
          .chantStream(widget.suggestion.chantId),
      builder: (context, snapshot) {
        final chant = snapshot.data?.chant;
        final authoritative =
            snapshot.connectionState == ConnectionState.active &&
            !snapshot.hasError &&
            snapshot.hasData &&
            snapshot.data?.isFromCache == false;
        final current =
            authoritative && chant != null && !chant.hidden && !chant.removed;
        final stale = current && widget.suggestion.isStaleAgainst(chant);
        final canAcceptEvidence =
            current &&
            !stale &&
            chant.status == 'community' &&
            chant.createdBy != 'system' &&
            widget.suggestion.kind == ChantUpdateKind.evidence &&
            widget.suggestion.evidence != null;
        final canAttachEvidence =
            current &&
            !stale &&
            (chant.status == 'canonical' || chant.createdBy == 'system') &&
            widget.suggestion.kind == ChantUpdateKind.evidence &&
            widget.suggestion.evidence != null;
        final currentEvidence = current ? chant.evidence : null;
        final proposedEvidence = widget.suggestion.evidence;
        final replacesEvidence =
            currentEvidence != null &&
            proposedEvidence != null &&
            !_sameEvidence(currentEvidence, proposedEvidence);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.suggestion.chantTitleSnapshot,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(label: Text(widget.suggestion.status.name)),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _kindCopy(widget.suggestion),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: Spacing.sm),
                Text(widget.suggestion.message),
                if (currentEvidence case final evidence?) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'CURRENT PROOF',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: Spacing.xs),
                  EvidenceLinkAction(
                    evidence: evidence,
                    showSupportingCopy: false,
                  ),
                ],
                if (proposedEvidence case final evidence?) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'PROPOSED PROOF',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: Spacing.xs),
                  EvidenceLinkAction(
                    evidence: evidence,
                    showSupportingCopy: false,
                  ),
                ],
                const SizedBox(height: Spacing.sm),
                Text(
                  'Submitted against ${widget.suggestion.chantUpdatedAt.toUtc().toIso8601String()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (current)
                  Text(
                    'Current version ${chant.updatedAt.toUtc().toIso8601String()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (stale) ...[
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'STALE: the chant changed after this was submitted.',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (authoritative && !current) ...[
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'The source chant is unavailable. Only Not changed can close this request.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ] else if (!authoritative) ...[
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'Current live chant authority is unavailable. Actions are disabled.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
                if (widget.suggestion.kind == ChantUpdateKind.evidence) ...[
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'Another accepted proof can make this request stale. If that happens, close it with a note asking the supporter to resubmit against the current version.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    if (widget.suggestion.kind != ChantUpdateKind.evidence) ...[
                      OutlinedButton(
                        onPressed: !current || _working
                            ? null
                            : () =>
                                  _planOrResolve(action: 'plan', stale: stale),
                        child: const Text('MARK PLANNED'),
                      ),
                      OutlinedButton(
                        onPressed: !current || _working
                            ? null
                            : () => _planOrResolve(
                                action: 'updated',
                                stale: stale,
                              ),
                        child: const Text('MARK UPDATED'),
                      ),
                    ],
                    if (widget.suggestion.kind == ChantUpdateKind.evidence)
                      FilledButton(
                        onPressed:
                            (!canAcceptEvidence && !canAttachEvidence) ||
                                _working
                            ? null
                            : () => _acceptEvidence(
                                promote: canAcceptEvidence,
                                replacesEvidence: replacesEvidence,
                              ),
                        child: Text(
                          replacesEvidence
                              ? 'REPLACE EVIDENCE'
                              : canAttachEvidence
                              ? 'ACCEPT EVIDENCE'
                              : 'ACCEPT & PROMOTE',
                        ),
                      ),
                    TextButton(
                      onPressed: !authoritative || _working
                          ? null
                          : () => _closeWithoutChange(stale: stale),
                      child: const Text('NOT CHANGED'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

bool _sameEvidence(ChantEvidence left, ChantEvidence right) {
  return left.provider == right.provider && left.url == right.url;
}

class _ReviewInput {
  final ChantUpdateResolution? resolution;
  final String? note;
  final bool acknowledgeStale;

  const _ReviewInput({
    required this.resolution,
    required this.note,
    required this.acknowledgeStale,
  });
}

String _kindCopy(ChantUpdateSuggestion suggestion) {
  return switch (suggestion.kind) {
    ChantUpdateKind.correction =>
      'Correction: ${suggestion.category?.name ?? 'other'}',
    ChantUpdateKind.variation => 'Another version',
    ChantUpdateKind.evidence => 'Proof it is being sung',
  };
}
