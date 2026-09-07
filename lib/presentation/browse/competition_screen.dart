import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/presentation/shared/club_signal.dart';

class CompetitionScreen extends ConsumerWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsStream = ref
        .watch(teamRepositoryProvider)
        .teamsForCompetitionStream(competitionId: competitionId);
    return Theme(
      data: ClubSignalTheme.from(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CLUB SIGNAL',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.signalGold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(competitionName.toUpperCase()),
            ],
          ),
        ),
        body: StreamBuilder<List<Team>>(
          stream: teamsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ClubSignalState(
                headline: 'Clubs are out of reach',
                message: 'Could not load clubs. Go back and try again.',
                icon: Icons.signal_wifi_connected_no_internet_4_outlined,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final teams = snapshot.data!.toList();
            if (teams.isEmpty) {
              return const ClubSignalState(
                headline: 'No clubs yet',
                message: 'No clubs yet. Check back soon.',
                icon: Icons.sports_soccer,
              );
            }
            teams.sort((a, b) => a.name.compareTo(b.name));
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: ClubSignalHeader(
                    eyebrow: 'Premier League',
                    title: 'Find your club',
                    message:
                        'Open the terrace-proven Songbook, see new ideas, or save a set for matchday.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.xs),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return _ClubSignalRow(
                        team: team,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.team,
                          arguments: team,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClubSignalRow extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _ClubSignalRow({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.signalPaper,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.signalRule, width: 0.5),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                _ClubMark(name: team.name),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.signalInk,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Text(
                  'OPEN',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: AppColors.signalForestMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.signalForestMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubMark extends StatelessWidget {
  final String name;

  const _ClubMark({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.signalForest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Anton',
          fontSize: 17,
          color: AppColors.signalPaper,
        ),
      ),
    );
  }
}
