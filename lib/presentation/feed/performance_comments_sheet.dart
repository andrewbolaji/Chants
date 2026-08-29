import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/performance_comment.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerformanceCommentsSheet extends ConsumerStatefulWidget {
  final String performanceId;
  final String chantTitle;
  final String? highlightedCommentId;

  const PerformanceCommentsSheet({
    super.key,
    required this.performanceId,
    required this.chantTitle,
    this.highlightedCommentId,
  });

  @override
  ConsumerState<PerformanceCommentsSheet> createState() =>
      _PerformanceCommentsSheetState();
}

class _PerformanceCommentsSheetState
    extends ConsumerState<PerformanceCommentsSheet> {
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  StreamSubscription<List<PerformanceComment>>? _subscription;
  List<PerformanceComment> _comments = const [];
  Object? _error;
  bool _loading = true;
  bool _posting = false;
  String? _pendingActionId;
  String? _pendingBody;
  String? _pendingParentId;
  PerformanceComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _subscription = ref
        .read(performanceInteractionRepositoryProvider)
        .commentsForPerformance(widget.performanceId)
        .listen(
          (comments) {
            if (!mounted) return;
            setState(() {
              _comments = comments;
              _loading = false;
              _error = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _error = error;
              _loading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _posting) return;
    final actionId =
        _pendingBody == body &&
            _pendingActionId != null &&
            _pendingParentId == _replyingTo?.id
        ? _pendingActionId!
        : PerformanceInteractionRepository.newClientActionId();
    setState(() {
      _posting = true;
      _pendingActionId = actionId;
      _pendingBody = body;
      _pendingParentId = _replyingTo?.id;
    });
    try {
      await ref
          .read(performanceInteractionRepositoryProvider)
          .createComment(
            performanceId: widget.performanceId,
            body: body,
            clientActionId: actionId,
            parentCommentId: _replyingTo?.id,
          );
      if (!mounted) return;
      _bodyController.clear();
      setState(() {
        _posting = false;
        _pendingActionId = null;
        _pendingBody = null;
        _pendingParentId = null;
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

  void _beginReply(PerformanceComment comment) {
    setState(() {
      _replyingTo = comment;
      _pendingActionId = null;
      _pendingBody = null;
      _pendingParentId = null;
    });
    _bodyFocusNode.requestFocus();
  }

  Future<void> _openThread(PerformanceComment comment) async {
    final selected = await showModalBottomSheet<PerformanceComment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FocusedPerformanceThread(
        performanceId: widget.performanceId,
        rootCommentId: comment.rootCommentId,
        knownRoot: _comments
            .where((item) => item.id == comment.rootCommentId)
            .firstOrNull,
      ),
    );
    if (selected != null && mounted) _beginReply(selected);
  }

  Future<void> _delete(PerformanceComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(performanceInteractionRepositoryProvider)
          .deleteComment(comment.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this comment.')),
      );
    }
  }

  Future<void> _block(PerformanceComment comment, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${comment.creatorDisplayName}?'),
        content: const Text(
          'Their comments will be hidden from you. You can unblock them from '
          'Blocked users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
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
            blockerId: userId,
            blockedUserId: comment.userId,
            blockedDisplayName: comment.creatorDisplayName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${comment.creatorDisplayName} blocked.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not block this creator.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final blockedIds = user == null
        ? <String>{}
        : ref.watch(blockedUserIdsProvider(user.uid)).valueOrNull ?? <String>{};
    final visibleComments = _comments
        .where((comment) => !blockedIds.contains(comment.userId))
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Material(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: Spacing.sm),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textFaint,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.sm,
                  Spacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMENTS',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.chantTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close comments',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(Spacing.xl),
                          child: Text('Comments could not be loaded.'),
                        ),
                      )
                    : visibleComments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(Spacing.xl),
                          child: Text(
                            'No comments yet. Be the first voice in the stand.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        itemCount: visibleComments.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final comment = visibleComments[index];
                          final ownsComment = user?.uid == comment.userId;
                          final hasThread =
                              comment.depth >= 2 ||
                              _comments.any(
                                (item) =>
                                    item.id != comment.id &&
                                    item.rootCommentId == comment.rootCommentId,
                              );
                          final highlighted =
                              comment.id == widget.highlightedCommentId;
                          return Container(
                            key: ValueKey<String>(
                              'performance-comment-${comment.id}',
                            ),
                            padding: EdgeInsets.only(
                              left: comment.displayDepth * 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: highlighted
                                  ? AppColors.chantLab.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              border: highlighted
                                  ? const Border(
                                      left: BorderSide(
                                        color: AppColors.chantLab,
                                        width: 3,
                                      ),
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.chantLab,
                                child: Text(
                                  comment.creatorDisplayName.isEmpty
                                      ? '?'
                                      : comment.creatorDisplayName[0]
                                            .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                '${comment.creatorDisplayName}  '
                                '@${comment.creatorHandle}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: Spacing.xs),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.body),
                                    if (hasThread)
                                      TextButton(
                                        onPressed: () => _openThread(comment),
                                        child: const Text('OPEN THREAD'),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: user == null
                                  ? null
                                  : PopupMenuButton<String>(
                                      tooltip: 'Comment actions',
                                      onSelected: (value) {
                                        if (value == 'reply') {
                                          _beginReply(comment);
                                        } else if (value == 'delete') {
                                          _delete(comment);
                                        } else if (value == 'block') {
                                          _block(comment, user.uid);
                                        } else if (value == 'report-comment') {
                                          showReportSheet(
                                            context: context,
                                            target: ReportPerformanceComment(
                                              comment.id,
                                            ),
                                            ref: ref,
                                          );
                                        } else if (value == 'report-creator') {
                                          showReportSheet(
                                            context: context,
                                            target: ReportUser(comment.userId),
                                            ref: ref,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'reply',
                                          child: Text('Reply'),
                                        ),
                                        if (ownsComment)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          )
                                        else ...const [
                                          PopupMenuItem(
                                            value: 'report-comment',
                                            child: Text('Report comment'),
                                          ),
                                          PopupMenuItem(
                                            value: 'report-creator',
                                            child: Text('Report creator'),
                                          ),
                                          PopupMenuItem(
                                            value: 'block',
                                            child: Text('Block creator'),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              if (_replyingTo != null)
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.sm,
                    Spacing.sm,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to @${_replyingTo!.creatorHandle}',
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel reply',
                        onPressed: () => setState(() => _replyingTo = null),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        enabled: user != null && !_posting,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: user == null
                              ? 'Sign in to comment'
                              : 'Add to the conversation',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    IconButton.filled(
                      tooltip: 'Post comment',
                      onPressed: user == null || _posting ? null : _post,
                      icon: _posting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedPerformanceThread extends ConsumerWidget {
  final String performanceId;
  final String rootCommentId;
  final PerformanceComment? knownRoot;

  const _FocusedPerformanceThread({
    required this.performanceId,
    required this.rootCommentId,
    required this.knownRoot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Material(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.sm,
                  Spacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'THREAD',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close thread',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<PerformanceComment>>(
                  stream: ref
                      .watch(performanceInteractionRepositoryProvider)
                      .commentsForThread(
                        performanceId: performanceId,
                        rootCommentId: rootCommentId,
                      ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Thread unavailable.'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = <PerformanceComment>[
                      if (knownRoot != null &&
                          !snapshot.data!.any(
                            (comment) => comment.id == knownRoot!.id,
                          ))
                        knownRoot!,
                      ...snapshot.data!,
                    ];
                    return ListView.separated(
                      padding: const EdgeInsets.all(Spacing.lg),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: comment.displayDepth * 16.0,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${comment.creatorDisplayName}  '
                              '@${comment.creatorHandle}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(comment.body),
                            trailing: TextButton(
                              onPressed: () => Navigator.pop(context, comment),
                              child: const Text('REPLY'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
