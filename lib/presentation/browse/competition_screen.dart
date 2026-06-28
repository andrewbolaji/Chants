import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(competitionName.toUpperCase())),
      body: StreamBuilder<List<Team>>(
        stream: teamsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorState(
              message: 'Could not load clubs. Pull down to try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teams = snapshot.data!;
          if (teams.isEmpty) {
            return const EmptyState(
              message: 'No clubs yet. Check back soon.',
              icon: Icons.sports_soccer,
            );
          }
          teams.sort((a, b) => a.name.compareTo(b.name));
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            itemCount: teams.length,
            separatorBuilder: (_, _) => const Divider(
              indent: Spacing.lg,
              endIndent: Spacing.lg,
            ),
            itemBuilder: (context, index) {
              final team = teams[index];
              return ListTile(
                title: Text(team.name, style: textTheme.titleMedium),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textFaint,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.team,
                  arguments: team,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
