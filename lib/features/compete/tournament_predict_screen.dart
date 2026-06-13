import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/sources/teams_data.dart';
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'compete_models.dart';

/// Tournament-long predictions: winner, runners-up, golden boot, golden glove.
/// Locks when the Final kicks off.
class TournamentPredictScreen extends StatefulWidget {
  const TournamentPredictScreen({super.key});

  @override
  State<TournamentPredictScreen> createState() =>
      _TournamentPredictScreenState();
}

class _TournamentPredictScreenState extends State<TournamentPredictScreen> {
  late TournamentPrediction _t;

  @override
  void initState() {
    super.initState();
    final e = context.read<CompeteProvider>().tournament;
    _t = TournamentPrediction()
      ..winnerTeamId = e.winnerTeamId
      ..runnerUpTeamId = e.runnerUpTeamId
      ..goldenBootTeamId = e.goldenBootTeamId
      ..goldenGloveTeamId = e.goldenGloveTeamId;
  }

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final now = fx.now;
    final fin = fx.matches.firstWhere(
        (m) => m.stage == MatchStage.finalMatch,
        orElse: () => fx.matches.last);
    final locked = !now.isBefore(fin.kickoff);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Tournament Predictions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _deadline(context, fin, now, locked),
          _pick(context, 'Tournament Winner', Icons.emoji_events,
              Points.champion, _t.winnerTeamId, locked,
              (id) => setState(() => _t.winnerTeamId = id)),
          _pick(context, 'Tournament Runners-up', Icons.workspace_premium,
              Points.runnerUp, _t.runnerUpTeamId, locked,
              (id) => setState(() => _t.runnerUpTeamId = id)),
          _pick(context, 'Golden Boot (top scorer nation)', Icons.sports_soccer,
              Points.goldenBoot, _t.goldenBootTeamId, locked,
              (id) => setState(() => _t.goldenBootTeamId = id)),
          _pick(context, 'Golden Glove (best keeper nation)', Icons.back_hand,
              Points.goldenGlove, _t.goldenGloveTeamId, locked,
              (id) => setState(() => _t.goldenGloveTeamId = id)),
          const SizedBox(height: 20),
          if (!locked)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  final err = await context
                      .read<CompeteProvider>()
                      .saveTournament(_t);
                  if (!context.mounted) return;
                  if (err != null) {
                    messenger.showSnackBar(SnackBar(content: Text(err)));
                    return;
                  }
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Tournament predictions saved!')));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.scheme.primary,
                  foregroundColor: context.scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deadline(
      BuildContext context, FootballMatch fin, DateTime now, bool locked) {
    final d = fin.kickoff.difference(now);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: locked
            ? null
            : const LinearGradient(colors: AppColors.brandGradient),
        color: locked ? AppColors.live.withValues(alpha: 0.16) : null,
        border:
            locked ? Border.all(color: AppColors.live.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          Icon(locked ? Icons.lock_clock : Icons.timer,
              color: locked ? AppColors.live : Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locked ? 'Predictions closed' : 'Deadline',
                    style: TextStyle(
                        color: locked
                            ? AppColors.live
                            : Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(
                  locked
                      ? 'The Final has kicked off'
                      : 'Locks before the Final • ${Dates.kickoff(fin.kickoffBd)} BD',
                  style: TextStyle(
                      color: locked ? AppColors.live : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          if (!locked)
            Text(Dates.countdown(d),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
        ],
      ),
    );
  }

  Widget _pick(BuildContext context, String title, IconData icon, int points,
      String? value, bool locked, ValueChanged<String> onPick) {
    final team = value == null ? null : teamById(value);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: locked
          ? null
          : () async {
              final picked = await showModalBottomSheet<Team>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _TeamSheet(),
              );
              if (picked != null) onPick(picked.id);
            },
      child: Row(
        children: [
          Icon(icon, color: context.scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.scheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('+$points',
                          style: TextStyle(
                              color: context.scheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(team?.name ?? (locked ? 'Not picked' : 'Tap to choose'),
                    style: TextStyle(
                        color: team == null
                            ? context.semantic.textDim
                            : context.scheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          if (team != null) TeamBadge(team: team, size: 34),
          if (!locked) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}

class _TeamSheet extends StatefulWidget {
  const _TeamSheet();
  @override
  State<_TeamSheet> createState() => _TeamSheetState();
}

class _TeamSheetState extends State<_TeamSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final teams = kTeams
        .where((t) =>
            _q.isEmpty || t.name.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search team…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.semantic.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.semantic.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: teams.length,
                itemBuilder: (_, i) => ListTile(
                  leading: TeamBadge(team: teams[i], size: 36),
                  title: Text(teams[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Group ${teams[i].group}',
                      style: TextStyle(color: context.semantic.textDim)),
                  onTap: () => Navigator.of(context).pop(teams[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
