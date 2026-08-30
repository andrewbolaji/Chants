import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyChantUpdatesScreen extends ConsumerWidget {
  const MyChantUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('MY CHANT UPDATES')),
      body: user == null
          ? const Center(child: Text('Sign in to see your chant updates.'))
          : StreamBuilder<List<ChantUpdateSuggestion>>(
              stream: ref
                  .watch(chantUpdateRepositoryProvider)
                  .mySuggestions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: Text('Your chant updates could not be loaded.'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final suggestions = snapshot.data!;
                if (suggestions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: Text(
                        'Nothing here yet. Open a chant and choose Suggest an edit.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) =>
                      _UpdateCard(suggestion: suggestions[index]),
                );
              },
            ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final ChantUpdateSuggestion suggestion;

  const _UpdateCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
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
                    suggestion.chantTitleSnapshot,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusLabel(suggestion.status))),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              _kindLabel(suggestion),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.sm),
            Text(suggestion.message),
            if (suggestion.resolutionNote case final note?)
              if (note.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                Text(
                  'Review note',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: Spacing.xs),
                Text(note),
              ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(ChantUpdateStatus status) {
  return switch (status) {
    ChantUpdateStatus.received => 'RECEIVED',
    ChantUpdateStatus.planned => 'PLANNED',
    ChantUpdateStatus.updated => 'UPDATED',
    ChantUpdateStatus.notChanged => 'NOT CHANGED',
  };
}

String _kindLabel(ChantUpdateSuggestion suggestion) {
  return switch (suggestion.kind) {
    ChantUpdateKind.correction =>
      'Correction: ${suggestion.category?.name ?? 'other'}',
    ChantUpdateKind.variation => 'Another version',
    ChantUpdateKind.evidence => 'Proof it is being sung',
  };
}
