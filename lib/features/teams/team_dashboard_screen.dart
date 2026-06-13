import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../providers/app_state.dart';
import '../../providers/fixtures_provider.dart';
import '../road_to_final/road_to_final_screen.dart';

class TeamDashboardScreen extends StatelessWidget {
  const TeamDashboardScreen({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final fixtures = context.watch<FixturesProvider>();
    final appState = context.watch<AppState>();
    final now = fixtures.now;
    final matches = fixtures.repo.matchesForTeam(team.id);
    final standings = fixtures.repo.standingsForGroup(team.group);
    final pos = standings.indexWhere((s) => s.team.id == team.id) + 1;
    final me = standings.firstWhere((s) => s.team.id == team.id);

    final upcoming = matches
        .where((m) => m.statusAt(now) != MatchStatus.finished)
        .toList();
    final past = matches
        .where((m) => m.statusAt(now) == MatchStatus.finished)
        .toList()
        .reversed
        .toList();

    return GradientScaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              appState.isFavorite(team.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: appState.isFavorite(team.id)
                  ? context.scheme.tertiary
                  : null,
            ),
            onPressed: () => context.read<AppState>().toggleFavorite(team.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _hero(context, pos),
          _statsRow(context, me, pos),
          _roadCta(context),
          if (upcoming.isNotEmpty) ...[
            _label(context, 'Upcoming Matches'),
            for (final m in upcoming.take(4)) MatchCard(match: m, now: now),
          ],
          if (past.isNotEmpty) ...[
            _label(context, 'Recent Results'),
            for (final m in past.take(4)) MatchCard(match: m, now: now),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, int pos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            team.primaryColor,
            Color.lerp(team.primaryColor, Colors.black, 0.5)!,
          ],
        ),
      ),
      child: Row(
        children: [
          TeamBadge(team: team, size: 76),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('Group ${team.group}'),
                    _chip('FIFA ${team.rating}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      );

  Widget _statsRow(BuildContext context, me, int pos) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _stat(context, '#$pos', 'Group Pos'),
          _div(context),
          _stat(context, '${me.points}', 'Points'),
          _div(context),
          _stat(context, '${me.won}-${me.drawn}-${me.lost}', 'W-D-L'),
          _div(context),
          _stat(
              context,
              '${me.goalsFor}:${me.goalsAgainst}',
              'Goals'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v,
                style: context.texts.titleMedium
                    ?.copyWith(color: context.scheme.primary)),
            const SizedBox(height: 2),
            Text(l,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.semantic.textDim, fontSize: 10)),
          ],
        ),
      );

  Widget _div(BuildContext context) =>
      Container(width: 1, height: 30, color: context.semantic.border);

  Widget _roadCta(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gradient: LinearGradient(
        colors: [
          context.scheme.secondary.withValues(alpha: 0.9),
          context.scheme.primary.withValues(alpha: 0.85),
        ],
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RoadToFinalScreen(team: team),
      )),
      child: Row(
        children: [
          const Icon(Icons.route, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Road to the Final',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('See ${team.name}\'s projected path to glory',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Text(text, style: context.texts.titleMedium),
      );
}
