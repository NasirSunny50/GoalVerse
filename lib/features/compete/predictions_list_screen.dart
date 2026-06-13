import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'predict_match_screen.dart';

/// Full list of every still-predictable match (kick-off in the future), so
/// users can predict matches beyond the few shown on the Compete dashboard.
class PredictionsListScreen extends StatelessWidget {
  const PredictionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final compete = context.watch<CompeteProvider>();
    final now = fx.now;
    final matches = fx.matches
        .where((m) =>
            m.home != null && m.away != null && now.isBefore(m.kickoff))
        .toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    final nowBd = now.toUtc().add(const Duration(hours: 6));
    final predicted = matches.where((m) => compete.hasPrediction(m.id)).length;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Predict Matches')),
      body: RefreshIndicator(
        onRefresh: () => context.read<FixturesProvider>().refreshNow(),
        child: matches.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text('No matches left to predict.',
                        style: TextStyle(color: context.semantic.textDim)),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: matches.length + 1,
                itemBuilder: (c, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                      child: Text(
                        '$predicted of ${matches.length} upcoming matches predicted',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: context.semantic.textDim),
                      ),
                    );
                  }
                  return _tile(context, matches[i - 1], compete, nowBd);
                },
              ),
      ),
    );
  }

  Widget _tile(BuildContext context, FootballMatch m, CompeteProvider compete,
      DateTime nowBd) {
    final has = compete.hasPrediction(m.id);
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
                  '${Dates.relativeDay(m.kickoffBd, nowBd)} • ${Dates.time(m.kickoffBd)} BD',
                  style: TextStyle(
                      color: context.semantic.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TeamBadge(team: m.away, size: 34),
          const SizedBox(width: 10),
          if (has)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: context.scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 13, color: context.scheme.primary),
                  const SizedBox(width: 3),
                  Text('Edit',
                      style: TextStyle(
                          color: context.scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ],
              ),
            )
          else
            Text('Predict',
                style: TextStyle(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
        ],
      ),
    );
  }
}
