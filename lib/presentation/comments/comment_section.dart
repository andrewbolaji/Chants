import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/presentation/comments/comment_card.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String chantId;
  final int commentCount;
  final bool actionsEnabled;

  const CommentSection({
    super.key,
    required this.chantId,
    required this.commentCount,
    this.actionsEnabled = true,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _bodyController = TextEditingController();
  final _composerFocus = FocusNode();
  bool _posting = false;
  Comment? _replyingTo;

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
      _replyingTo = null;
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
          if (_replyingTo != null &&
              !comments.any((comment) => comment.id == _replyingTo!.id)) {
            _replyingTo = null;
          }
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
    _composerFocus.dispose();
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

    CommentLike? like;
    try {
      like = await ref
          .read(commentRepositoryProvider)
          .getUserLike(userId: userId, commentId: commentId);
    } catch (_) {
      _likeLoadedFor.remove(commentId);
      return;
    }

    if (!mounted) return;
    final persistedLike = like;
    if (persistedLike != null) {
      setState(() {
        final current = _likeStates[commentId];
        if (current != null) {
          _likeStates[commentId] = current.reconcileFromPersistedLike(
            persistedLike.appliedValue,
          );
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
    if (!widget.actionsEnabled) return;
    final current = _likeStates[commentId];
    if (current == null || current.busy) return;

    final toggled = current.toggle();
    setState(() => _likeStates[commentId] = toggled);

    try {
      if (toggled.liked) {
        await ref
            .read(commentRepositoryProvider)
            .likeComment(userId: userId, commentId: commentId);
      } else {
        await ref
            .read(commentRepositoryProvider)
            .unlikeComment(userId: userId, commentId: commentId);
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
    if (!widget.actionsEnabled) return;
    final body = _bodyController.text.trim();
    if (body.isEmpty || _posting) return;

    setState(() => _posting = true);

    final comment = Comment(
      id: '',
      chantId: widget.chantId,
      userId: userId,
      displayName: displayName,
      body: body,
      parentCommentId: _replyingTo?.id,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(commentRepositoryProvider).createComment(comment);
      if (!mounted) return;
      _bodyController.clear();
      setState(() {
        _posting = false;
        _replyingTo = null;
      });
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

  void _startReply(Comment comment) {
    if (!widget.actionsEnabled) return;
    setState(() => _replyingTo = comment);
    _composerFocus.requestFocus();
  }

  Future<void> _blockUser(Comment comment, String blockerId) async {
    if (!widget.actionsEnabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${comment.displayName}?'),
        content: const Text(
          'Their comments and replies will be hidden from you. You can '
          'unblock them later from Blocked users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(blockRepositoryProvider)
          .blockUser(
            blockerId: blockerId,
            blockedUserId: comment.userId,
            blockedDisplayName: comment.displayName,
          );
      if (!mounted) return;
      if (_replyingTo?.userId == comment.userId) {
        setState(() => _replyingTo = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${comment.displayName} blocked.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                _undoBlock(blockerId: blockerId, blockedUserId: comment.userId),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not block this user. Try again.')),
      );
    }
  }

  Future<void> _undoBlock({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      await ref
          .read(blockRepositoryProvider)
          .unblockUser(blockerId: blockerId, blockedUserId: blockedUserId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not unblock this user. Try again.'),
        ),
      );
    }
  }

  Future<void> _softDelete(String commentId) async {
    if (!widget.actionsEnabled) return;
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
  List<Comment> _sortedTopLevel(List<Comment> comments) {
    final sorted = List<Comment>.of(comments);
    sorted.sort((a, b) {
      final likeCmp = b.likeCount.compareTo(a.likeCount);
      if (likeCmp != 0) return likeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  List<Comment> _sortedReplies(List<Comment> comments) {
    final sorted = List<Comment>.of(comments);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final isSignedIn = user != null;
    final textTheme = Theme.of(context).textTheme;
    final blockedUserIds = user == null
        ? <String>{}
        : ref.watch(blockedUserIdsProvider(user.uid)).valueOrNull ?? <String>{};

    final comments = _comments
        .where((comment) => !blockedUserIds.contains(comment.userId))
        .toList();
    final topLevel = _sortedTopLevel(
      comments.where((comment) => comment.parentCommentId == null).toList(),
    );
    final repliesByParent = <String, List<Comment>>{};
    for (final reply in comments.where(
      (comment) => comment.parentCommentId != null,
    )) {
      repliesByParent.putIfAbsent(reply.parentCommentId!, () => []).add(reply);
    }
    final renderedCommentCount = topLevel.fold<int>(
      0,
      (count, parent) => count + 1 + (repliesByParent[parent.id]?.length ?? 0),
    );

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
            text: renderedCommentCount == 0
                ? 'Comments'
                : 'Comments ($renderedCommentCount)',
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
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),

        // Empty
        if (!_commentsLoading && !_commentsError && renderedCommentCount == 0)
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
                Flexible(
                  child: Text(
                    'No comments yet. Be the first.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Comment list
        ...topLevel.expand((comment) {
          final thread = <Widget>[];
          final likeState =
              _likeStates[comment.id] ?? CommentLikeState.initial(0);
          final isAuthor = isSignedIn && comment.userId == user.uid;

          thread.add(
            CommentCard(
              comment: comment,
              likeState: likeState,
              isAuthor: isAuthor,
              onReply: isSignedIn && widget.actionsEnabled
                  ? () => _startReply(comment)
                  : null,
              onToggleLike: isSignedIn && widget.actionsEnabled
                  ? () => _toggleLike(comment.id, user.uid)
                  : null,
              onReportComment: isSignedIn && widget.actionsEnabled
                  ? () => showReportSheet(
                      context: context,
                      target: ReportComment(comment.id),
                      ref: ref,
                    )
                  : null,
              onReportUser: isSignedIn && widget.actionsEnabled
                  ? () => showReportSheet(
                      context: context,
                      target: ReportUser(comment.userId),
                      ref: ref,
                    )
                  : null,
              onBlockUser: isSignedIn && !isAuthor && widget.actionsEnabled
                  ? () => _blockUser(comment, user.uid)
                  : null,
              onDelete: isAuthor && widget.actionsEnabled
                  ? () => _softDelete(comment.id)
                  : null,
            ),
          );

          final replies = _sortedReplies(repliesByParent[comment.id] ?? []);
          for (final reply in replies) {
            final replyLikeState =
                _likeStates[reply.id] ?? CommentLikeState.initial(0);
            final isReplyAuthor = isSignedIn && reply.userId == user.uid;
            thread.add(
              CommentCard(
                comment: reply,
                likeState: replyLikeState,
                isAuthor: isReplyAuthor,
                isReply: true,
                onToggleLike: isSignedIn && widget.actionsEnabled
                    ? () => _toggleLike(reply.id, user.uid)
                    : null,
                onReportComment: isSignedIn && widget.actionsEnabled
                    ? () => showReportSheet(
                        context: context,
                        target: ReportComment(reply.id),
                        ref: ref,
                      )
                    : null,
                onReportUser: isSignedIn && widget.actionsEnabled
                    ? () => showReportSheet(
                        context: context,
                        target: ReportUser(reply.userId),
                        ref: ref,
                      )
                    : null,
                onBlockUser:
                    isSignedIn && !isReplyAuthor && widget.actionsEnabled
                    ? () => _blockUser(reply, user.uid)
                    : null,
                onDelete: isReplyAuthor && widget.actionsEnabled
                    ? () => _softDelete(reply.id)
                    : null,
              ),
            );
          }
          return thread;
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
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          )
        else if (!widget.actionsEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Text(
              'Live updates are required to join the comments.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          )
        else
          _buildComposer(context, user.uid, textTheme),

        const SizedBox(height: Spacing.lg),
      ],
    );
  }

  Widget _buildComposer(
    BuildContext context,
    String userId,
    TextTheme textTheme,
  ) {
    // Check if the user is banned
    final profileStream = ref
        .watch(profileRepositoryProvider)
        .profileStream(userId);

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
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingTo != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingTo!.displayName}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancel reply',
                      onPressed: () => setState(() => _replyingTo = null),
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      focusNode: _composerFocus,
                      maxLength: 500,
                      maxLines: 3,
                      minLines: 1,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textBody,
                      ),
                      decoration: InputDecoration(
                        hintText: _replyingTo == null
                            ? 'Add a comment...'
                            : 'Write a reply...',
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
            ],
          ),
        );
      },
    );
  }
}
