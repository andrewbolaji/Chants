import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/presentation/browse/discovery_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chants'),
        actions: [
          // Operator-only moderation link
          StreamBuilder(
            stream: ref.watch(authStateProvider).whenData((user) {
              if (user == null) return const Stream.empty();
              return ref
                  .watch(profileRepositoryProvider)
                  .profileStream(user.uid);
            }).value,
            builder: (context, snap) {
              final profile = snap.data;
              if (profile != null && profile.isOperator) {
                return IconButton(
                  icon: const Icon(Icons.shield_outlined),
                  tooltip: 'Moderation',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.moderation),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.policy_outlined),
            tooltip: 'Content policy',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.contentPolicy),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Premier League entry
          Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.emoji_events_outlined),
                ),
                title: const Text('Premier League'),
                subtitle: const Text('All 20 clubs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.competition,
                  arguments: {
                    'id': 'premier-league',
                    'name': 'Premier League',
                  },
                ),
              ),
            ),
          ),

          // Discovery shuffle
          const DiscoverySection(),
        ],
      ),
    );
  }
}
