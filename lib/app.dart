import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/goalverse_logo.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/root_shell.dart';
import 'providers/app_state.dart';

class Fifa2026App extends StatelessWidget {
  const Fifa2026App({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      title: 'GoalVerse',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        child: !appState.ready
            ? const _Splash()
            : appState.onboarded
                ? const RootShell()
                : const OnboardingScreen(),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoalVerseMark(size: 92),
            const SizedBox(height: 22),
            GoalVerseLogo(
              markSize: 0,
              fontSize: 30,
              showTagline: true,
              onDark: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
