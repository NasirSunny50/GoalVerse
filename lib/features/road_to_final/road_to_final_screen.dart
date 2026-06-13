import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/team.dart';
import '../../providers/fixtures_provider.dart';
import 'bracket_builder.dart';

class RoadToFinalScreen extends StatelessWidget {
  const RoadToFinalScreen({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FixturesProvider>().repo;
    final result = RoadToFinal(repo).buildFor(team);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Road to the Final')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _hero(context, result),
          if (!result.qualifies) _projectionBanner(context),
          _startNode(context),
          for (var i = 0; i < result.rounds.length; i++)
            _roundNode(context, result.rounds[i], i, result.rounds.length),
          _trophyNode(context),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Result result) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          TeamBadge(team: team, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${team.name}'s Path",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  'Projected seed #${result.seed} • 4 wins from glory',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _projectionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${team.name} is not currently projected to advance. This shows their potential path if they qualify.',
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _startNode(BuildContext context) {
    return _timelineRow(
      context,
      isFirst: true,
      child: GlassCard(
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            TeamBadge(team: team, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Group Stage',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('Top the group to start the journey',
                      style: TextStyle(
                          color: context.semantic.textDim, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.flag, color: context.scheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _roundNode(
      BuildContext context, RoadRound round, int index, int total) {
    final isFinal = index == total - 1;
    return _timelineRow(
      context,
      child: GlassCard(
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      context.scheme.secondary,
                      context.scheme.primary,
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(round.title.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                ),
                const Spacer(),
                if (isFinal)
                  const Icon(Icons.emoji_events, color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 6),
            Text(round.subtitle,
                style: TextStyle(
                    color: context.semantic.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              round.possibleOpponents.length == 1
                  ? 'Opponent'
                  : 'Possible opponents (${round.possibleOpponents.length})',
              style: context.texts.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.semantic.textDim),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opp in round.possibleOpponents)
                  _opponentChip(context, opp),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 120).ms).slideX(begin: 0.1);
  }

  Widget _opponentChip(BuildContext context, Team opp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.semantic.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.semantic.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamBadge(team: opp, size: 24, showRing: false),
          const SizedBox(width: 6),
          Text(opp.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _trophyNode(BuildContext context) {
    return _timelineRow(
      context,
      isLast: true,
      child: Container(
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.gold, Color(0xFFFF9D2F)],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('World Champions',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  Text('MetLife Stadium • 19 July 2026',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a left-side timeline rail with a node and connecting line.
  Widget _timelineRow(
    BuildContext context, {
    required Widget child,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : context.semantic.border,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: context.scheme.primary
                            .withValues(alpha: 0.3),
                        width: 4),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : context.semantic.border,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
