import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/presentation/settings/account_actions_menu.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorProfileScreen extends ConsumerWidget {
  final String uid;

  const CreatorProfileScreen({super.key, required this.uid});

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(userProfileProvider(uid));
    final accountProfile = account.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOU'),
        actions: const [AccountActionsMenu()],
      ),
      body: switch ((accountProfile, account.hasError)) {
        (null, false) => const Center(child: CircularProgressIndicator()),
        (null, true) => _ProfileUnavailable(
          onRetry: () => ref.invalidate(userProfileProvider(uid)),
        ),
        (final profile?, _) => _CreatorProfileBody(
          uid: uid,
          accountName: profile.displayName,
          initials: _initials(profile.displayName),
        ),
      },
    );
  }
}

class _CreatorProfileBody extends ConsumerWidget {
  final String uid;
  final String accountName;
  final String initials;

  const _CreatorProfileBody({
    required this.uid,
    required this.accountName,
    required this.initials,
  });

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRouter.editCreatorProfile,
      arguments: uid,
    );
    if (changed == true) {
      ref.invalidate(creatorProfileProvider(uid));
      ref.invalidate(userProfileProvider(uid));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(creatorProfileProvider(uid));
    if (creator.isLoading && !creator.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (creator.hasError && !creator.hasValue) {
      return _ProfileUnavailable(
        onRetry: () => ref.invalidate(creatorProfileProvider(uid)),
      );
    }
    final publicProfile = creator.valueOrNull;

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xxxl),
      children: [
        _CreatorHeader(
          accountName: accountName,
          initials: initials,
          profile: publicProfile,
          onEdit: () => _edit(context, ref),
          onPublicView: publicProfile == null
              ? null
              : () => Navigator.pushNamed(
                  context,
                  AppRouter.creatorProfile,
                  arguments: uid,
                ),
        ),
        const SizedBox(height: Spacing.xl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: SectionEyebrow(text: 'Creator activity'),
        ),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: _PerformanceDraftActivity(
            uid: uid,
            hasCreatorProfile: publicProfile != null,
          ),
        ),
      ],
    );
  }
}

class _PerformanceDraftActivity extends ConsumerWidget {
  final String uid;
  final bool hasCreatorProfile;

  const _PerformanceDraftActivity({
    required this.uid,
    required this.hasCreatorProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<PerformanceDraft>>(
      stream: ref.watch(performanceDraftRepositoryProvider).draftsForOwner(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ActivityMessage(
            message: 'Performance status is unavailable. Try again later.',
          );
        }
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final drafts = snapshot.data!;
        if (drafts.isEmpty) {
          return _ActivityMessage(
            message: hasCreatorProfile
                ? 'Open a chant and tap Perform this chant to record a take '
                      'or choose an edited video.'
                : 'Set up your public profile before your first performance. '
                      'Your words-only chants still work now.',
          );
        }
        return Column(
          children: [
            for (var index = 0; index < drafts.length; index++) ...[
              _PerformanceDraftCard(draft: drafts[index]),
              if (index != drafts.length - 1)
                const SizedBox(height: Spacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  final String message;

  const _ActivityMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xl,
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _PerformanceDraftCard extends StatelessWidget {
  final PerformanceDraft draft;

  const _PerformanceDraftCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, description) = switch (draft.state) {
      PerformanceDraftState.awaitingUpload => (
        'UPLOAD INCOMPLETE',
        Icons.cloud_off_outlined,
        AppColors.error,
        'This draft never reached review. Start a fresh take from the chant.',
      ),
      PerformanceDraftState.pendingReview => (
        'PENDING REVIEW',
        Icons.hourglass_top,
        AppColors.gold,
        'Private while a moderator checks the video.',
      ),
      PerformanceDraftState.approved => (
        'LIVE ON CHANT STAGE',
        Icons.check_circle_outline,
        AppColors.success,
        'Approved and eligible for the Stage feed.',
      ),
      PerformanceDraftState.rejected => (
        'NOT APPROVED',
        Icons.cancel_outlined,
        AppColors.error,
        draft.moderationReason?.isNotEmpty == true
            ? draft.moderationReason!
            : 'The moderator did not approve this video.',
      ),
      PerformanceDraftState.cancelled => (
        'CANCELLED',
        Icons.delete_outline,
        AppColors.textMuted,
        'Nothing was published.',
      ),
    };
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    draft.chantTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  final String accountName;
  final String initials;
  final CreatorProfile? profile;
  final VoidCallback onEdit;
  final VoidCallback? onPublicView;

  const _CreatorHeader({
    required this.accountName,
    required this.initials,
    required this.profile,
    required this.onEdit,
    required this.onPublicView,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? accountName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '$name creator avatar',
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.chantLab,
                  foregroundColor: AppColors.textHeadline,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      profile == null
                          ? 'CREATOR PROFILE NOT PUBLIC YET'
                          : '@${profile!.handle}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile?.bio.isNotEmpty == true) ...[
            const SizedBox(height: Spacing.lg),
            Text(profile!.bio, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (profile?.hidden == true || profile?.removed == true) ...[
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                profile!.removed
                    ? 'This creator profile was removed and is not public.'
                    : 'This creator profile is hidden while it is reviewed.',
                style: const TextStyle(color: AppColors.textBody),
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          if (profile != null) _CreatorStats(profile: profile!),
          if (profile != null) const SizedBox(height: Spacing.lg),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: profile?.removed == true ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              profile == null
                  ? 'SET UP CREATOR PROFILE'
                  : 'EDIT CREATOR PROFILE',
            ),
          ),
          if (onPublicView != null) ...[
            const SizedBox(height: Spacing.sm),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: onPublicView,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('VIEW PUBLIC PROFILE'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatorStats extends StatelessWidget {
  final CreatorProfile profile;

  const _CreatorStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${profile.followerCount} followers, ${profile.followingCount} following, ${profile.performanceCount} performances',
      child: Row(
        children: [
          _Stat(value: profile.followerCount, label: 'FOLLOWERS'),
          _Stat(value: profile.followingCount, label: 'FOLLOWING'),
          _Stat(value: profile.performanceCount, label: 'PERFORMANCES'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: Spacing.md),
            const Text('Your profile could not be loaded.'),
            const SizedBox(height: Spacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
