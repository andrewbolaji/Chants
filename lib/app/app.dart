import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';

class ChantApp extends ConsumerWidget {
  const ChantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Addition B: force dark system UI overlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Chants',
      theme: ChantTheme.dark,
      darkTheme: ChantTheme.dark,
      themeMode: ThemeMode.dark, // Addition B: force dark regardless of system
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: authState.when(
        data: (user) =>
            user != null ? const HomeScreen() : const SignInScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const SignInScreen(),
      ),
    );
  }
}
