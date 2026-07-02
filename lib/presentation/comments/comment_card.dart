import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/comment.dart';

/// A clean per-user toggle: liked (true) or not liked (false).
/// Not a vote clone. A like is a simpler thing: a binary toggle whose display
/// count is serverLikeCount + optimisticDelta, where delta is 0 or +1.
///
/// appliedValue reconciliation on cold load:
///   - If the user has a like doc with appliedValue == 1, the server likeCount
///     already includes the like. confirmedLiked = true, delta = 0.
///   - If the user has a like doc with appliedValue absent or != 1, the server
///     likeCount does NOT yet include the like. confirmedLiked = false,
///     delta = +1 (so display shows the expected count).
///   - If no like doc exists, the user has not liked. confirmedLiked = false,
///     delta = 0.
class CommentLikeState {
  final int serverLikeCount;
  final bool liked; // the user's current intent
  final bool confirmedLiked; // what the server has processed
  final bool busy; // write in flight
  final int optimisticDelta;

  const CommentLikeState({
    required this.serverLikeCount,
    required this.liked,
    required this.confirmedLiked,
    required this.busy,
    required this.optimisticDelta,
  });

  int get displayCount => serverLikeCount + optimisticDelta;

  /// Initial state before any user interaction or cold-load reconciliation.
  factory CommentLikeState.initial(int serverLikeCount) {
    return CommentLikeState(
      serverLikeCount: serverLikeCount,
      liked: false,
      confirmedLiked: false,
      busy: false,
      optimisticDelta: 0,
    );
  }

  /// Cold-load reconciliation: set liked state from a persisted like doc.
  /// appliedValue tells us whether the server count already includes the like.
  CommentLikeState reconcileFromPersistedLike(int? appliedValue) {
    if (appliedValue == 1) {
      // Server has processed this like: count includes it.
      return CommentLikeState(
        serverLikeCount: serverLikeCount,
        liked: true,
        confirmedLiked: true,
        busy: false,
        optimisticDelta: 0,
      );
    } else {
      // Like doc exists but CF has not yet processed it.
      // Show the expected count (+1) until the server stream catches up.
      return CommentLikeState(
        serverLikeCount: serverLikeCount,
        liked: true,
        confirmedLiked: false,
        busy: false,
        optimisticDelta: 1,
      );
    }
  }

  /// User taps the like toggle.
  CommentLikeState toggle() {
    final newLiked = !liked;
    final newDelta = newLiked
        ? (confirmedLiked ? 0 : 1)
        : (confirmedLiked ? -1 : 0);
    return CommentLikeState(
      serverLikeCount: serverLikeCount,
      liked: newLiked,
      confirmedLiked: confirmedLiked,
      busy: true,
      optimisticDelta: newDelta,
    );
  }

  /// Write finished. Clear busy but keep delta until server stream arrives.
  CommentLikeState confirmWrite() {
    return CommentLikeState(
      serverLikeCount: serverLikeCount,
      liked: liked,
      confirmedLiked: confirmedLiked,
      busy: false,
      optimisticDelta: optimisticDelta,
    );
  }

  /// Server stream delivered a new likeCount. Collapse optimistic state.
  CommentLikeState reconcileServerCount(int newServerCount) {
    if (busy) {
      // Write in flight: keep the delta relative to what we think
      final newDelta = liked
          ? (confirmedLiked ? 0 : 1)
          : (confirmedLiked ? -1 : 0);
      return CommentLikeState(
        serverLikeCount: newServerCount,
        liked: liked,
        confirmedLiked: confirmedLiked,
        busy: true,
        optimisticDelta: newDelta,
      );
    }
    // Not busy: the server count is the truth. Collapse everything.
    return CommentLikeState(
      serverLikeCount: newServerCount,
      liked: liked,
      confirmedLiked: liked,
      busy: false,
      optimisticDelta: 0,
    );
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;
  final CommentLikeState likeState;
  final bool isAuthor;
  final VoidCallback? onToggleLike;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.likeState,
    required this.isAuthor,
    this.onToggleLike,
    this.onReport,
    this.onDelete,
  });

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: displayName + relative time
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHeadline,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _relativeTime(comment.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),

          // Body: calm readable text
          Text(
            comment.body,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Footer: like toggle (left), report or delete (right)
          Row(
            children: [
              // Like toggle
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      likeState.liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: likeState.liked
                          ? AppColors.gold
                          : AppColors.textMuted,
                    ),
                    if (likeState.displayCount > 0) ...[
                      const SizedBox(width: Spacing.xs),
                      Text(
                        '${likeState.displayCount}',
                        style: textTheme.bodySmall?.copyWith(
                          color: likeState.liked
                              ? AppColors.gold
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              // Report (if not author) or delete (if author)
              if (isAuthor)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                )
              else
                GestureDetector(
                  onTap: onReport,
                  child: Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
