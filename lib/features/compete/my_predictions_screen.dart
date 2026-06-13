import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'predict_match_screen.dart';

/// Read-only review of matches — every match the user predicted PLUS every
/// match that has already kicked off (predicted or not). Tapping opens the
/// match read-only: kicked-off matches can't be edited (server rejects it),
/// and once scored each market shows ✓/✗ + the actual answer.
class MyPredictionsScreen extends StatelessWidget {
  const MyPredictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final compete = context.watch<CompeteProvider>();
    final now = fx.now;
    final predicted = compete.predictedMatchIds.toSet();
    final matches = fx.matches
        .where((m) =>
            m.home != null &&
            m.away != null &&
            (predicted.contains(m.id) || !now.isBefore(m.kickoff)))
        .toList()
      ..sort((a, b) => b.kickoff.compareTo(a.kickoff)); // most recent first

    return GradientScaffold(
      appBar: AppBar(title: const Text('My Predictions')),
      body: RefreshIndicator(
        onRefresh: () => compete.refresh(),
        child: matches.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text('Nothing to review yet.',
                        style: TextStyle(color: context.semantic.textDim)),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                itemCount: matches.length,
                itemBuilder: (c, i) => _tile(
                    context, matches[i], compete, fx, now,
                    predicted: predicted.contains(matches[i].id)),
              ),
      ),
    );
  }

  Widget _tile(BuildContext context, FootballMatch m, CompeteProvider compete,
      FixturesProvider fx, DateTime now,
      {required bool predicted}) {
    final review = compete.matchReview(m.id);
    final result = (review?['result'] as Map?)?.cast<String, dynamic>() ??
        fx.matchResult(m.id);
    final locked = !now.isBefore(m.kickoff);
    final hs = result?['homeScore'], as = result?['awayScore'];
    final score = (hs != null && as != null) ? '$hs–$as' : null;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PredictMatchScreen(match: m))),
      child: Row(
        children: [
          TeamBadge(team: m.home, size: 34),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Text('${m.home?.code ?? '—'}  v  ${m.away?.code ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  score != null
                      ? 'Final $score'
                      : '${Dates.day(m.kickoffBd)} • ${Dates.time(m.kickoffBd)} BD',
                  style: TextStyle(
                      color: context.semantic.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TeamBadge(team: m.away, size: 34),
          const SizedBox(width: 10),
          _statusBadge(context, predicted, review, locked),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, bool predicted,
      Map<String, dynamic>? review, bool locked) {
    late Color color;
    late String text;
    if (!predicted) {
      color = context.semantic.textDim;
      text = 'Not predicted';
    } else if (review != null) {
      color = context.scheme.primary;
      text = '+${review['points'] ?? 0} pts';
    } else if (locked) {
      color = AppColors.live;
      text = 'Locked';
    } else {
      color = const Color(0xFF2BA55B);
      text = 'Open';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }
}
