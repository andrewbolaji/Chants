import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chants'),
        actions: [
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
      body: const Center(
        child: Text('Home. Browse and search arrive in Block 2.'),
      ),
    );
  }
}
