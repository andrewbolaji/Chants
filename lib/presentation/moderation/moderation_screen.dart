import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/feedback_entry.dart';
import 'package:chants/presentation/shared/error_state.dart';

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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MODERATION'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Flagged'),
              Tab(text: 'Comments'),
              Tab(text: 'Promote'),
              Tab(text: 'Feedback'),
              Tab(text: 'Ban'),
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
                      message: 'Could not load flagged chants.');
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
                      message: 'Could not load flagged comments.');
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
            // Tab 3: promotion candidates
            StreamBuilder<List<Chant>>(
              stream: candidatesStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                      message: 'Could not load candidates.');
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
                          'No promotion candidates yet. Community chants need a score of 10 or more.'),
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
            // Tab 3: feedback
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: feedbackStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                      message: 'Could not load feedback.');
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
            // Tab 4: ban user
            const _BanUserTab(),
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
            Text(chant.title,
                style: Theme.of(context).textTheme.titleMedium),
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
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
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
        case 'hide':
          await modRepo.hideChant(chant.id);
        case 'unhide':
          await modRepo.unhideChant(chant.id);
        case 'remove':
          await modRepo.removeChant(chant.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Done. Chant ${action}d.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chant.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Score: ${chant.score} | Status: ${chant.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              chant.lyrics,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    try {
                      await ref
                          .read(moderationRepositoryProvider)
                          .promoteChant(chant.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Promoted to verified.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promotion failed.')),
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
            Text(comment.displayName,
                style: Theme.of(context).textTheme.titleSmall),
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
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
    }
  }
}

class _BanUserTab extends ConsumerStatefulWidget {
  const _BanUserTab();

  @override
  ConsumerState<_BanUserTab> createState() => _BanUserTabState();
}

class _BanUserTabState extends ConsumerState<_BanUserTab> {
  final _uidController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _ban() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(moderationRepositoryProvider).banUser(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User banned.')),
      );
      _uidController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ban failed. Check the user ID and try again.')),
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
          const Text('Enter the user ID to ban.'),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _uidController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _loading ? null : _ban,
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
        ],
      ),
    );
  }
}
