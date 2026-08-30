import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/feedback_entry.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/user_report.dart';
import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/services/chant_evidence.dart';
import 'package:chants/presentation/moderation/user_ban_button.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:chants/presentation/shared/evidence_link_action.dart';
import 'package:chants/presentation/shared/error_state.dart';
import 'package:chants/presentation/feed/performance_video_player.dart';
import 'package:chants/presentation/moderation/chant_update_moderation_tab.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Query chants with flagCount > 0 or hidden or removed
    final chantsStream = FirebaseFirestore.instance
        .collection('chants')
        .where('hidden', isEqualTo: true)
        .snapshots();

    final candidatesStream = ref
        .watch(chantRepositoryProvider)
        .promotionCandidatesStream();

    final feedbackStream = FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final flaggedCommentsStream = FirebaseFirestore.instance
        .collection('comments')
        .where('hidden', isEqualTo: true)
        .snapshots();

    // No orderBy on a different field: equality/range-only queries avoid
    // needing a composite index (same tradeoff as the rest of the app,
    // see docs/DECISIONS.md). Sorted client-side in the builder instead.
    final reportedUsersStream = FirebaseFirestore.instance
        .collection('profiles')
        .where('userReportCount', isGreaterThan: 0)
        .snapshots();

    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MODERATION'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Flagged'),
              Tab(text: 'Comments'),
              Tab(text: 'Performances'),
              Tab(text: 'Reported media'),
              Tab(text: 'Promote'),
              Tab(text: 'Updates'),
              Tab(text: 'Feedback'),
              Tab(text: 'Reported users'),
              Tab(text: 'User access'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: flagged/hidden chants
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chantsStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                    message: 'Could not load flagged chants.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xxl),
                      child: Text('No flagged or hidden chants. All clear.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(Spacing.sm),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final chant = Chant.fromFirestore(docs[index]);
                    return _ModerationCard(chant: chant, ref: ref);
                  },
                );
              },
            ),
            // Tab 2: flagged/hidden comments
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: flaggedCommentsStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                    message: 'Could not load flagged comments.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xxl),
                      child: Text('No flagged or hidden comments. All clear.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(Spacing.sm),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final comment = Comment.fromFirestore(docs[index]);
                    return _CommentModerationCard(comment: comment, ref: ref);
                  },
                );
              },
            ),
            // Tab 3: pending performance media
            const _PerformanceReviewTab(),
            // Tab 4: reports against published performances and comments
            const _PublishedPerformanceReportsTab(),
            // Tab 5: promotion candidates
            StreamBuilder<List<Chant>>(
              stream: candidatesStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                    message: 'Could not load candidates.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final candidates = snap.data!;
                if (candidates.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xxl),
                      child: Text(
                        'No promotion candidates yet. Community chants need a score of 10 or more.',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(Spacing.sm),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final chant = candidates[index];
                    return _PromotionCard(chant: chant, ref: ref);
                  },
                );
              },
            ),
            // Tab 6: feedback
            const ChantUpdateModerationTab(),
            // Tab 7: feedback
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: feedbackStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(message: 'Could not load feedback.');
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xxl),
                      child: Text('No feedback yet.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(Spacing.sm),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final fb = FeedbackEntry.fromFirestore(docs[index]);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(label: Text(fb.category)),
                                const Spacer(),
                                if (fb.followUpOk)
                                  const Chip(label: Text('Follow-up OK')),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(fb.message),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'User: ${fb.userId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Tab 7: reported users
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: reportedUsersStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                    message: 'Could not load reported users.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profiles =
                    snap.data!.docs.map(UserProfile.fromFirestore).toList()
                      ..sort(
                        (a, b) =>
                            b.userReportCount.compareTo(a.userReportCount),
                      );
                if (profiles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xxl),
                      child: Text('No reported users. All clear.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(Spacing.sm),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    return _ReportedUserCard(
                      profile: profiles[index],
                      ref: ref,
                    );
                  },
                );
              },
            ),
            // Tab 8: ban or unban by user ID
            const _UserAccessTab(),
          ],
        ),
      ),
    );
  }
}

class _PerformanceReviewTab extends ConsumerWidget {
  const _PerformanceReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<PerformanceDraft>>(
      stream: ref
          .watch(performanceDraftRepositoryProvider)
          .pendingReviewQueue(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorState(
            message: 'Could not load performance review queue.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final drafts = snapshot.data!;
        if (drafts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacing.xxl),
              child: Text('No performances are waiting for review.'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.sm),
          itemCount: drafts.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, index) =>
              _PerformanceReviewCard(draft: drafts[index], ref: ref),
        );
      },
    );
  }
}

class _PublishedPerformanceReportsTab extends StatelessWidget {
  const _PublishedPerformanceReportsTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Material(
            color: Colors.transparent,
            child: TabBar(
              tabs: [
                Tab(text: 'Videos'),
                Tab(text: 'Comments'),
                Tab(text: 'Hidden'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PublishedReportList(
                  collection: 'performanceReports',
                  targetField: 'performanceId',
                  targetType: 'performance',
                  emptyCopy: 'No published performance reports.',
                ),
                _PublishedReportList(
                  collection: 'performanceCommentReports',
                  targetField: 'performanceCommentId',
                  targetType: 'performanceComment',
                  emptyCopy: 'No performance comment reports.',
                ),
                _HiddenPublishedContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishedReportList extends StatelessWidget {
  final String collection;
  final String targetField;
  final String targetType;
  final String emptyCopy;

  const _PublishedReportList({
    required this.collection,
    required this.targetField,
    required this.targetType,
    required this.emptyCopy,
  });

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection(collection)
        .where('status', isEqualTo: 'pending')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorState(message: 'Could not load media reports.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!.docs.toList();
        if (reports.isEmpty) return Center(child: Text(emptyCopy));
        reports.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
            aTime?.millisecondsSinceEpoch ?? 0,
          );
        });
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.sm),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, index) {
            final data = reports[index].data();
            final targetId = data[targetField];
            if (targetId is! String) {
              return const Card(
                child: ListTile(title: Text('Malformed report record')),
              );
            }
            return _PublishedReportCard(
              targetType: targetType,
              targetId: targetId,
              reason: data['reason'] as String? ?? 'No reason supplied',
              reportedBy: data['reportedBy'] as String? ?? 'unknown',
            );
          },
        );
      },
    );
  }
}

class _PublishedReportCard extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;
  final String reason;
  final String reportedBy;

  const _PublishedReportCard({
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.reportedBy,
  });

  @override
  ConsumerState<_PublishedReportCard> createState() =>
      _PublishedReportCardState();
}

class _PublishedReportCardState extends ConsumerState<_PublishedReportCard> {
  bool _working = false;

  Future<void> _preview() async {
    if (widget.targetType == 'performance') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reported performance'),
          content: SizedBox(
            width: 320,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: PerformanceVideoPlayer(
                resolveMediaUri: () => ref
                    .read(performanceRepositoryProvider)
                    .resolvePlayback(widget.targetId),
                semanticLabel: 'Preview reported performance',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('performanceComments')
        .doc(widget.targetId)
        .get();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reported comment'),
        content: Text(
          snapshot.data()?['body'] as String? ?? 'Comment unavailable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _act(String action) async {
    if (_working) return;
    if (action == 'hide' || action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${action == 'hide' ? 'Hide' : 'Remove'} this content?'),
          content: Text(
            action == 'hide'
                ? 'It will stop being public until an operator restores it.'
                : 'Removal is the terminal moderation state.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action.toUpperCase()),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _working = true);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .moderatePublishedPerformance(
            targetType: widget.targetType,
            targetId: widget.targetId,
            action: action,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report ${action == 'dismiss' ? 'dismissed' : 'reviewed'}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not apply this moderation action.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetType == 'performance'
                  ? 'REPORTED PERFORMANCE'
                  : 'REPORTED COMMENT',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.xs),
            Text(widget.reason),
            const SizedBox(height: Spacing.xs),
            Text(
              'Target: ${widget.targetId} · Reporter: ${widget.reportedBy}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton(
                  onPressed: _working ? null : _preview,
                  child: const Text('PREVIEW'),
                ),
                OutlinedButton(
                  onPressed: _working ? null : () => _act('dismiss'),
                  child: const Text('DISMISS'),
                ),
                FilledButton(
                  onPressed: _working ? null : () => _act('hide'),
                  child: const Text('HIDE'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _working ? null : () => _act('remove'),
                  child: const Text('REMOVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenPublishedContent extends ConsumerWidget {
  const _HiddenPublishedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performances = FirebaseFirestore.instance
        .collection('performances')
        .where('hidden', isEqualTo: true)
        .where('removed', isEqualTo: false)
        .snapshots();
    final comments = FirebaseFirestore.instance
        .collection('performanceComments')
        .where('hidden', isEqualTo: true)
        .where('removed', isEqualTo: false)
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: performances,
      builder: (context, performanceSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: comments,
          builder: (context, commentSnapshot) {
            if (performanceSnapshot.hasError || commentSnapshot.hasError) {
              return const ErrorState(message: 'Could not load hidden media.');
            }
            if (!performanceSnapshot.hasData || !commentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = <({String type, String id, String label})>[
              for (final document in performanceSnapshot.data!.docs)
                (
                  type: 'performance',
                  id: document.id,
                  label:
                      document.data()['chantTitle'] as String? ?? document.id,
                ),
              for (final document in commentSnapshot.data!.docs)
                (
                  type: 'performanceComment',
                  id: document.id,
                  label: document.data()['body'] as String? ?? document.id,
                ),
            ];
            if (items.isEmpty) {
              return const Center(child: Text('No hidden published content.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(Spacing.sm),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                return HiddenPublishedContentCard(
                  targetType: item.type,
                  targetId: item.id,
                  label: item.label,
                );
              },
            );
          },
        );
      },
    );
  }
}

class HiddenPublishedContentCard extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;
  final String label;

  const HiddenPublishedContentCard({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.label,
  });

  @override
  ConsumerState<HiddenPublishedContentCard> createState() =>
      _HiddenPublishedContentCardState();
}

class _HiddenPublishedContentCardState
    extends ConsumerState<HiddenPublishedContentCard> {
  bool _working = false;

  Future<void> _preview() async {
    if (widget.targetType == 'performance') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(widget.label),
          content: SizedBox(
            width: 320,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: PerformanceVideoPlayer(
                resolveMediaUri: () => ref
                    .read(performanceRepositoryProvider)
                    .resolvePlayback(widget.targetId),
                semanticLabel: 'Preview hidden performance',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('performanceComments')
        .doc(widget.targetId)
        .get();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hidden comment'),
        content: Text(
          snapshot.data()?['body'] as String? ?? 'Comment unavailable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _act(String action) async {
    if (_working) return;
    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove this content?'),
          content: const Text(
            'Removal is terminal. Performance media will be deleted by the '
            'durable cleanup worker.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('REMOVE'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _working = true);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .moderatePublishedPerformance(
            targetType: widget.targetType,
            targetId: widget.targetId,
            action: action,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this hidden content.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.xs),
            Text(widget.targetType),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton(
                  onPressed: _working ? null : _preview,
                  child: const Text('PREVIEW'),
                ),
                FilledButton(
                  onPressed: _working ? null : () => _act('unhide'),
                  child: const Text('RESTORE'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _working ? null : () => _act('remove'),
                  child: const Text('REMOVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceReviewCard extends StatefulWidget {
  final PerformanceDraft draft;
  final WidgetRef ref;

  const _PerformanceReviewCard({required this.draft, required this.ref});

  @override
  State<_PerformanceReviewCard> createState() => _PerformanceReviewCardState();
}

class _PerformanceReviewCardState extends State<_PerformanceReviewCard> {
  bool _working = false;

  Future<void> _preview() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.draft.chantTitle),
        content: SizedBox(
          width: 320,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: PerformanceVideoPlayer(
              resolveMediaUri: () => widget.ref
                  .read(performanceDraftRepositoryProvider)
                  .resolveDraftPlayback(widget.draft.id),
              semanticLabel: 'Preview ${widget.draft.chantTitle}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve performance?'),
        content: const Text(
          'Confirm you watched the whole video, verified it is 30 seconds or '
          'shorter, and found no policy violation. Approval publishes it to '
          'Chant Stage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _moderate(approve: true);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Do not approve'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason shown to the creator',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await _moderate(approve: false, reason: reason);
  }

  Future<void> _moderate({required bool approve, String reason = ''}) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await widget.ref
          .read(performanceDraftRepositoryProvider)
          .moderate(draftId: widget.draft.id, approve: approve, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Performance approved.' : 'Performance rejected.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moderation action failed. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.draft.chantTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${widget.draft.teamName} | '
              '${(widget.draft.durationMs / 1000).toStringAsFixed(1)} seconds',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.draft.caption.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(widget.draft.caption),
            ],
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _working ? null : _preview,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('PREVIEW VIDEO'),
                ),
                FilledButton(
                  onPressed: _working ? null : _approve,
                  child: const Text('APPROVE'),
                ),
                TextButton(
                  onPressed: _working ? null : _reject,
                  child: const Text('REJECT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  final Chant chant;
  final WidgetRef ref;

  const _ModerationCard({required this.chant, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chant.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Flags: ${chant.flagCount} | '
              'Hidden: ${chant.hidden} | '
              'Removed: ${chant.removed}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              chant.lyrics,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.sm),
            ChantProvenanceLabel(chant: chant),
            if (ChantEvidenceParser.isCanonical(chant.evidence)) ...[
              const SizedBox(height: Spacing.sm),
              EvidenceLinkAction(
                evidence: chant.evidence!,
                showSupportingCopy: false,
              ),
            ],
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: 8,
              children: [
                if (!chant.hidden && !chant.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'hide'),
                    child: const Text('Hide'),
                  ),
                if (chant.hidden && !chant.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'unhide'),
                    child: const Text('Unhide'),
                  ),
                if (!chant.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'remove'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                    child: const Text('Remove'),
                  ),
                if (ChantEvidenceParser.isCanonical(chant.evidence))
                  FilledButton.tonal(
                    onPressed: () => _confirmEvidenceRemoval(context),
                    child: const Text('Remove evidence'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _action(BuildContext context, String action) async {
    try {
      final modRepo = ref.read(moderationRepositoryProvider);
      switch (action) {
        case 'hide':
          await modRepo.hideChant(chant.id);
        case 'unhide':
          await modRepo.unhideChant(chant.id);
        case 'remove':
          await modRepo.removeChant(chant.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Done. Chant ${action}d.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
    }
  }

  Future<void> _confirmEvidenceRemoval(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove evidence?'),
        content: Text(
          chant.status == 'canonical' && chant.createdBy != 'system'
              ? 'This also returns the chant to Chant Lab.'
              : 'The external link will no longer appear on this chant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVE EVIDENCE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(moderationRepositoryProvider)
          .removeChantEvidence(chant.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chant.status == 'canonical' && chant.createdBy != 'system'
                ? 'Evidence removed. Chant returned to Chant Lab.'
                : 'Evidence removed.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove evidence.')),
      );
    }
  }
}

class _PromotionCard extends StatelessWidget {
  final Chant chant;
  final WidgetRef ref;

  const _PromotionCard({required this.chant, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasEvidence = ChantEvidenceParser.isCanonical(chant.evidence);
    final canPromote = chant.createdBy == 'system' || hasEvidence;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chant.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Score: ${chant.score} | Status: ${chant.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.xs),
            ChantProvenanceLabel(chant: chant),
            const SizedBox(height: Spacing.xs),
            Text(chant.lyrics, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (hasEvidence) ...[
              const SizedBox(height: Spacing.sm),
              EvidenceLinkAction(
                evidence: chant.evidence!,
                showSupportingCopy: false,
              ),
            ] else if (chant.createdBy == 'system') ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'Seed source is covered by the operator sourcing ledger.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'Valid YouTube or X evidence is required before Terrace Proven.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: !canPromote
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(moderationRepositoryProvider)
                                .promoteChant(chant.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Promoted to Terrace Proven.'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Promotion failed.'),
                              ),
                            );
                          }
                        },
                  child: const Text('Promote'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentModerationCard extends StatelessWidget {
  final Comment comment;
  final WidgetRef ref;

  const _CommentModerationCard({required this.comment, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.displayName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Flags: ${comment.flagCount} | '
              'Hidden: ${comment.hidden} | '
              'Removed: ${comment.removed}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              comment.body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: 8,
              children: [
                if (!comment.hidden && !comment.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'hide-comment'),
                    child: const Text('Hide'),
                  ),
                if (comment.hidden && !comment.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'unhide-comment'),
                    child: const Text('Unhide'),
                  ),
                if (!comment.removed)
                  FilledButton.tonal(
                    onPressed: () => _action(context, 'remove-comment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _action(BuildContext context, String action) async {
    try {
      final modRepo = ref.read(moderationRepositoryProvider);
      switch (action) {
        case 'hide-comment':
          await modRepo.hideComment(comment.id);
        case 'unhide-comment':
          await modRepo.unhideComment(comment.id);
        case 'remove-comment':
          await modRepo.removeComment(comment.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Done.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
    }
  }
}

class _ReportedUserCard extends StatelessWidget {
  final UserProfile profile;
  final WidgetRef ref;

  const _ReportedUserCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    final reportsStream = FirebaseFirestore.instance
        .collection('userReports')
        .where('reportedUserId', isEqualTo: profile.id)
        .snapshots();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Reports: ${profile.userReportCount} | '
              'Banned: ${profile.banned}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.sm),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: reportsStream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final reports =
                    snap.data!.docs.map(UserReport.fromFirestore).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reports
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.xs),
                          child: Text(
                            '${r.reason} (reported by ${r.reportedBy})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: Spacing.sm),
            UserBanButton(
              banned: profile.banned,
              onBan: () => _ban(context),
              onUnban: () => _unban(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ban(BuildContext context) async {
    try {
      await ref.read(moderationRepositoryProvider).banUser(profile.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User banned.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ban failed. Try again.')));
    }
  }

  Future<void> _unban(BuildContext context) async {
    try {
      await ref.read(moderationRepositoryProvider).unbanUser(profile.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User unbanned.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unban failed. Try again.')));
    }
  }
}

class _UserAccessTab extends ConsumerStatefulWidget {
  const _UserAccessTab();

  @override
  ConsumerState<_UserAccessTab> createState() => _UserAccessTabState();
}

class _UserAccessTabState extends ConsumerState<_UserAccessTab> {
  final _uidController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _setBanned(bool banned) async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repository = ref.read(moderationRepositoryProvider);
      if (banned) {
        await repository.banUser(uid);
      } else {
        await repository.unbanUser(uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(banned ? 'User banned.' : 'User unbanned.')),
      );
      _uidController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${banned ? 'Ban' : 'Unban'} failed. Check the user ID and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter a user ID to change account access.'),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _uidController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => _setBanned(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ban user'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _setBanned(false),
                  child: const Text('Unban user'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
