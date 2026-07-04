import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/presentation/comments/comment_card.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String chantId;
  final int commentCount;

  const CommentSection({
    super.key,
    required this.chantId,
    required this.commentCount,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _bodyController = TextEditingController();
  bool _posting = false;

  // Per-comment like state, keyed by comment ID.
  final Map<String, CommentLikeState> _likeStates = {};

  // Track which comments we have loaded likes for.
  final Set<String> _likeLoadedFor = {};

  // Stream subscription for comments (replaces StreamBuilder).
  StreamSubscription<List<Comment>>? _commentsSub;
  List<Comment> _comments = [];
  bool _commentsLoading = true;
  bool _commentsError = false;

  @override
  void initState() {
    super.initState();
    _subscribeToComments();
  }

  @override
  void didUpdateWidget(CommentSection old) {
    super.didUpdateWidget(old);
    if (old.chantId != widget.chantId) {
      _commentsSub?.cancel();
      _likeStates.clear();
      _likeLoadedFor.clear();
      _commentsLoading = true;
      _commentsError = false;
      _subscribeToComments();
    }
  }

  void _subscribeToComments() {
    final stream = ref
        .read(commentRepositoryProvider)
        .commentsForChantStream(chantId: widget.chantId);

    _commentsSub = stream.listen(
      (comments) {
        if (!mounted) return;

        // Reconcile like states outside of build.
        final authState = ref.read(authStateProvider);
        final user = authState.valueOrNull;
        for (final c in comments) {
          _initLikeState(c);
          _reconcileServerCount(c.id, c.likeCount);
          if (user != null) {
            _loadUserLike(c.id, user.uid);
          }
        }

        setState(() {
          _comments = comments;
          _commentsLoading = false;
          _commentsError = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _commentsError = true;
          _commentsLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _commentsSub?.cancel();
    _bodyController.dispose();
    super.dispose();
  }

  void _initLikeState(Comment comment) {
    _likeStates.putIfAbsent(
      comment.id,
      () => CommentLikeState.initial(comment.likeCount),
    );
  }

  Future<void> _loadUserLike(String commentId, String userId) async {
    if (_likeLoadedFor.contains(commentId)) return;
    _likeLoadedFor.add(commentId);

    final like = await ref.read(commentRepositoryProvider).getUserLike(
          userId: userId,
          commentId: commentId,
        );

    if (!mounted) return;
    if (like != null) {
      setState(() {
        final current = _likeStates[commentId];
        if (current != null) {
          _likeStates[commentId] =
              current.reconcileFromPersistedLike(like.appliedValue);
        }
      });
    }
  }

  /// Updates the cached like state from a new server count.
  /// Does NOT call setState; the caller is responsible for that.
  void _reconcileServerCount(String commentId, int newCount) {
    final current = _likeStates[commentId];
    if (current == null) return;
    final reconciled = current.reconcileServerCount(newCount);
    if (reconciled.serverLikeCount != current.serverLikeCount ||
        reconciled.optimisticDelta != current.optimisticDelta) {
      _likeStates[commentId] = reconciled;
    }
  }

  Future<void> _toggleLike(String commentId, String userId) async {
    final current = _likeStates[commentId];
    if (current == null || current.busy) return;

    final toggled = current.toggle();
    setState(() => _likeStates[commentId] = toggled);

    try {
      if (toggled.liked) {
        await ref.read(commentRepositoryProvider).likeComment(
              userId: userId,
              commentId: commentId,
            );
      } else {
        await ref.read(commentRepositoryProvider).unlikeComment(
              userId: userId,
              commentId: commentId,
            );
      }
      if (!mounted) return;
      setState(() {
        _likeStates[commentId] = _likeStates[commentId]!.confirmWrite();
      });
    } catch (_) {
      // Revert on failure
      if (!mounted) return;
      setState(() => _likeStates[commentId] = current);
    }
  }

  Future<void> _postComment(String userId, String displayName) async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _posting) return;

    setState(() => _posting = true);

    final comment = Comment(
      id: '',
      chantId: widget.chantId,
      userId: userId,
      displayName: displayName,
      body: body,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(commentRepositoryProvider).createComment(comment);
      if (!mounted) return;
      _bodyController.clear();
      setState(() => _posting = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post your comment. Try again.'),
        ),
      );
    }
  }

  Future<void> _softDelete(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(commentRepositoryProvider)
          .softDeleteComment(commentId: commentId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete your comment. Try again.'),
        ),
      );
    }
  }

  /// Sort: likeCount descending, then createdAt descending (newest first).
  List<Comment> _sorted(List<Comment> comments) {
    final sorted = List<Comment>.of(comments);
    sorted.sort((a, b) {
      final likeCmp = b.likeCount.compareTo(a.likeCount);
      if (likeCmp != 0) return likeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final isSignedIn = user != null;
    final textTheme = Theme.of(context).textTheme;

    final comments = _comments;
    final sorted = _sorted(comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(indent: Spacing.lg, endIndent: Spacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          child: SectionEyebrow(
            text: comments.isEmpty
                ? 'Comments'
                : 'Comments (${comments.length})',
          ),
        ),

        // Loading
        if (_commentsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Error
        if (_commentsError)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xl,
            ),
            child: Text(
              'Could not load comments. Try again.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),

        // Empty
        if (!_commentsLoading && !_commentsError && comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xl,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'No comments yet. Be the first.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

        // Comment list
        ...sorted.map((comment) {
          final likeState =
              _likeStates[comment.id] ?? CommentLikeState.initial(0);
          final isAuthor = isSignedIn && comment.userId == user.uid;

          return CommentCard(
            comment: comment,
            likeState: likeState,
            isAuthor: isAuthor,
            onToggleLike: isSignedIn
                ? () => _toggleLike(comment.id, user.uid)
                : null,
            onReport: isSignedIn
                ? () => showReportSheet(
                      context: context,
                      chantId: comment.chantId,
                      commentId: comment.id,
                      ref: ref,
                    )
                : null,
            onDelete: isAuthor
                ? () => _softDelete(comment.id)
                : null,
          );
        }),

        const SizedBox(height: Spacing.lg),

        // Composer
        if (!isSignedIn)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Text(
              'Sign in to comment.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          _buildComposer(context, user.uid, textTheme),

        const SizedBox(height: Spacing.lg),
      ],
    );
  }

  Widget _buildComposer(
      BuildContext context, String userId, TextTheme textTheme) {
    // Check if the user is banned
    final profileStream = ref.watch(profileRepositoryProvider).profileStream(userId);

    return StreamBuilder(
      stream: profileStream,
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        if (profile != null && profile.banned) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Text(
              'You cannot comment right now.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(
              top: BorderSide(color: AppColors.outline, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textBody,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      borderSide: const BorderSide(
                        color: AppColors.outline,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      borderSide: const BorderSide(
                        color: AppColors.outline,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed:
                      _bodyController.text.trim().isNotEmpty && !_posting
                          ? () => _postComment(
                                userId,
                                profile?.displayName ?? 'Anonymous',
                              )
                          : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color:
                        _bodyController.text.trim().isNotEmpty && !_posting
                            ? AppColors.gold
                            : AppColors.textMuted,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
