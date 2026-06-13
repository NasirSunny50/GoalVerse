import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../calendar/calendar_screen.dart';
import '../compete/compete_screen.dart';
import '../fixtures/fixtures_screen.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../teams/teams_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Home', Icons.sports_soccer, Icons.sports_soccer_outlined),
    _TabDef('Compete', Icons.emoji_events, Icons.emoji_events_outlined),
    _TabDef('Fixtures', Icons.calendar_view_day, Icons.calendar_view_day_outlined),
    _TabDef('Teams', Icons.groups, Icons.groups_outlined),
    _TabDef('Calendar', Icons.calendar_month, Icons.calendar_month_outlined),
    _TabDef('Explore', Icons.explore, Icons.explore_outlined),
  ];

  final _pages = const [
    HomeScreen(),
    CompeteScreen(),
    FixturesScreen(),
    TeamsScreen(),
    CalendarScreen(),
    ExploreScreen(),
  ];

  Future<void> _handleBack(bool didPop) async {
    if (didPop) return;
    // From a sub-tab, back returns to Home first.
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    // On Home, confirm before exiting.
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit GoalVerse?'),
        content: const Text('Do you really want to leave the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.scheme.primary,
              foregroundColor: ctx.scheme.onPrimary,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: _GlassNavBar(
          tabs: _tabs,
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.active, this.inactive);
  final String label;
  final IconData active;
  final IconData inactive;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<_TabDef> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: context.semantic.card
                .withValues(alpha: isDark ? 0.82 : 0.92),
            border: Border(
              top: BorderSide(color: context.semantic.border),
            ),
          ),
          padding: EdgeInsets.only(
            top: 8,
            // Lift the bar above the Android gesture / system navigation bar.
            bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _NavItem(
                  def: tabs[i],
                  selected: i == index,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.scheme.primary : context.semantic.textDim;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? context.scheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? def.active : def.inactive,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                def.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
