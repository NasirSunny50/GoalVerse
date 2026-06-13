import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/match_card.dart';
import '../../providers/fixtures_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(2026, 6);
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final fixtures = context.watch<FixturesProvider>();
    final now = fixtures.nowBd;
    final selected = _selected ?? now;
    final dayMatches = fixtures.matchesOnDay(selected);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: RefreshIndicator(
        onRefresh: () => context.read<FixturesProvider>().refreshNow(),
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _monthHeader(context),
          _calendarGrid(context, fixtures),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.event, size: 18, color: context.scheme.primary),
                const SizedBox(width: 8),
                Text(Dates.dayLong(selected),
                    style: context.texts.titleMedium),
                const Spacer(),
                Text('${dayMatches.length} match${dayMatches.length == 1 ? '' : 'es'}',
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.semantic.textDim)),
              ],
            ),
          ),
          if (dayMatches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy,
                        size: 40, color: context.semantic.textDim),
                    const SizedBox(height: 8),
                    Text('No matches on this day',
                        style:
                            TextStyle(color: context.semantic.textDim)),
                  ],
                ),
              ),
            )
          else
            for (final m in dayMatches) MatchCard(match: m, now: now),
        ],
        ),
      ),
    );
  }

  Widget _monthHeader(BuildContext context) {
    final canPrev = _month.isAfter(DateTime(2026, 6));
    final canNext = _month.isBefore(DateTime(2026, 7));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(Dates.monthYear(_month),
              style: context.texts.displaySmall?.copyWith(fontSize: 24)),
          const Spacer(),
          _navBtn(context, Icons.chevron_left,
              canPrev ? () => _shiftMonth(-1) : null),
          const SizedBox(width: 8),
          _navBtn(context, Icons.chevron_right,
              canNext ? () => _shiftMonth(1) : null),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap == null
          ? context.semantic.card.withValues(alpha: 0.4)
          : context.semantic.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 22,
              color: onTap == null
                  ? context.semantic.textDim
                  : context.scheme.primary),
        ),
      ),
    );
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Widget _calendarGrid(BuildContext context, FixturesProvider fixtures) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = first.weekday % 7; // Sunday-first
    final now = fixtures.nowBd;

    final cells = <Widget>[];
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final w in weekdays) {
      cells.add(Center(
        child: Text(w,
            style: TextStyle(
                color: context.semantic.textDim,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ));
    }
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      final count = fixtures.matchesOnDay(date).length;
      final isSelected = _selected != null && Dates.isSameDay(date, _selected!);
      final isToday = Dates.isSameDay(date, now);
      cells.add(_DayCell(
        day: d,
        matchCount: count,
        selected: isSelected,
        isToday: isToday,
        onTap: () => setState(() => _selected = date),
      ));
    }

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.matchCount,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final int matchCount;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMatches = matchCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? context.scheme.primary
              : isToday
                  ? context.scheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !selected
              ? Border.all(color: context.scheme.primary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                  fontWeight: hasMatches ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? context.scheme.onPrimary
                      : hasMatches
                          ? null
                          : context.semantic.textDim,
                )),
            const SizedBox(height: 2),
            if (hasMatches)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: selected
                      ? context.scheme.onPrimary
                      : context.scheme.tertiary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
