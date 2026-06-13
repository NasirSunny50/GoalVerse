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
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'compete_models.dart';

class PredictMatchScreen extends StatefulWidget {
  const PredictMatchScreen({super.key, required this.match});
  final FootballMatch match;

  @override
  State<PredictMatchScreen> createState() => _PredictMatchScreenState();
}

class _PredictMatchScreenState extends State<PredictMatchScreen> {
  late MatchPrediction _p;

  FootballMatch get m => widget.match;

  @override
  void initState() {
    super.initState();
    final e = context.read<CompeteProvider>().predictionFor(m.id);
    _p = MatchPrediction(matchId: m.id)
      ..winner = e.winner
      ..homeScore = e.homeScore
      ..awayScore = e.awayScore
      ..firstScorerSide = e.firstScorerSide
      ..overUnder = e.overUnder
      ..btts = e.btts
      ..penalties = e.penalties;
  }

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final compete = context.watch<CompeteProvider>();
    final now = fx.now;
    // Predictions lock at the real kick-off time (the server is authoritative).
    final locked = !now.isBefore(m.kickoff);
    // Read-only review: result from my own scored prediction, else the public
    // admin result (so matches I did NOT predict are reviewable too).
    final review = compete.matchReview(m.id);
    final markets = (review?['markets'] as Map?)?.cast<String, dynamic>();
    final result = (review?['result'] as Map?)?.cast<String, dynamic>() ??
        fx.matchResult(m.id);
    final scored = result != null;
    final points = (review?['points'] as int?) ?? 0;

    // win / miss / none(not predicted) / null(not scored yet).
    String? state(String key) {
      if (!scored) return null;
      final mk = markets?[key];
      if (mk == null) return 'none';
      return mk == true ? 'win' : 'miss';
    }

    Widget actual(String key) =>
        scored ? _actualCaption(context, _actualAnswer(key, result)) : const SizedBox.shrink();

    return GradientScaffold(
      appBar: AppBar(
          title: Text(locked ? 'Your Prediction' : 'Make Prediction')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            0, 8, 0, 32 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          _matchHeader(context),
          if (scored)
            _resultBanner(context, result, points)
          else if (locked)
            _banner(context, Icons.lock,
                'Predictions are locked — awaiting the result.', AppColors.live)
          else
            _banner(context, Icons.timer,
                'Locks at kick-off • ${Dates.kickoff(m.kickoffBd)} BD',
                context.scheme.primary),
          _section(context, 'Match Winner', Icons.emoji_events, Points.winner,
              state: state('winner')),
          _winnerMarket(context, locked),
          actual('winner'),
          _section(context, 'Exact Score', Icons.sports_soccer, Points.exact,
              state: state('exact')),
          _scoreMarket(context, locked),
          actual('exact'),
          _section(context, 'First Team To Score', Icons.bolt,
              Points.firstScorer,
              state: state('firstScorer')),
          _sideMarket(context, locked,
              value: _p.firstScorerSide,
              onPick: (v) => setState(() => _p.firstScorerSide = v),
              includeNone: true),
          actual('firstScorer'),
          _section(context, 'Total Goals', Icons.numbers, Points.overUnder,
              state: state('overUnder')),
          _overUnderMarket(context, locked),
          actual('overUnder'),
          _section(context, 'Both Teams to Score?', Icons.repeat, Points.btts,
              state: state('btts')),
          _yesNoMarket(context, locked,
              value: _p.btts, onPick: (v) => setState(() => _p.btts = v)),
          actual('btts'),
          if (m.stage.isKnockout) ...[
            _section(context, 'Decided on Penalties?', Icons.sports_soccer,
                Points.penalties, state: state('penalties')),
            _yesNoMarket(context, locked,
                value: _p.penalties,
                onPick: (v) => setState(() => _p.penalties = v)),
            actual('penalties'),
          ],
          const SizedBox(height: 20),
          if (!locked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final err = await context
                        .read<CompeteProvider>()
                        .savePrediction(_p);
                    if (!context.mounted) return;
                    if (err != null) {
                      messenger.showSnackBar(
                          SnackBar(content: Text(err)));
                      return;
                    }
                    nav.pop();
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Prediction saved! Good luck 🍀')));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: context.scheme.primary,
                    foregroundColor: context.scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Prediction',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _matchHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF20264F), Color(0xFF131730)]),
      ),
      child: Row(
        children: [
          Expanded(child: _teamCol(m.home, m.homeName)),
          const Text('VS',
              style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          Expanded(child: _teamCol(m.away, m.awayName)),
        ],
      ),
    );
  }

  Widget _teamCol(Team? team, String name) => Column(
        children: [
          TeamBadge(team: team, size: 52),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      );

  Widget _banner(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 12.5))),
      ]),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, int points,
      {String? state}) {
    // null → not scored (show point value); win/miss/none → review states.
    final Color color;
    final String label;
    switch (state) {
      case 'win':
        color = const Color(0xFF2BA55B);
        label = '✓ +$points';
        break;
      case 'miss':
        color = context.scheme.error;
        label = '✗ 0';
        break;
      case 'none':
        color = context.semantic.textDim;
        label = 'Not predicted';
        break;
      default:
        color = context.scheme.primary;
        label = '+$points pts';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Icon(icon, size: 18, color: context.scheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: context.texts.titleMedium)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ]),
    );
  }

  /// Human-readable actual answer for a market, from the admin result.
  String? _actualAnswer(String key, Map<String, dynamic>? r) {
    if (r == null) return null;
    final hs = r['homeScore'], as = r['awayScore'];
    switch (key) {
      case 'winner':
        final w = r['winner'] ??
            (hs != null && as != null
                ? (hs > as ? 'home' : (hs < as ? 'away' : 'draw'))
                : null);
        if (w == null) return null;
        return w == 'home'
            ? '${m.home?.code ?? 'Home'} win'
            : w == 'away'
                ? '${m.away?.code ?? 'Away'} win'
                : 'Draw';
      case 'exact':
        return (hs != null && as != null) ? '$hs–$as' : null;
      case 'firstScorer':
        switch (r['firstScorer']) {
          case 'home':
            return m.home?.code ?? 'Home';
          case 'away':
            return m.away?.code ?? 'Away';
          case 'none':
            return 'No goals';
        }
        return null;
      case 'overUnder':
        return r['overUnder'] == 'over'
            ? '3 or more'
            : r['overUnder'] == 'under'
                ? 'Under 3'
                : null;
      case 'btts':
        return r['btts'] == null ? null : (r['btts'] == true ? 'Yes' : 'No');
      case 'penalties':
        return r['penalties'] == null
            ? null
            : (r['penalties'] == true ? 'Yes' : 'No');
    }
    return null;
  }

  Widget _actualCaption(BuildContext context, String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Text('Actual: $text',
          style: TextStyle(
              color: context.semantic.textDim,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _resultBanner(
      BuildContext context, Map<String, dynamic> result, int pts) {
    final hs = result['homeScore'], as = result['awayScore'];
    final score = (hs != null && as != null) ? '$hs–$as' : '—';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.emoji_events, size: 20, color: context.scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Final result  $score',
                  style: TextStyle(
                      color: context.scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Text('Read-only review',
                  style: TextStyle(
                      color: context.semantic.textDim, fontSize: 11.5)),
            ],
          ),
        ),
        Text('+$pts pts',
            style: TextStyle(
                color: context.scheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 17)),
      ]),
    );
  }

  Widget _winnerMarket(BuildContext context, bool locked) {
    return _row(context, [
      _chip(context, m.home?.code ?? 'Home', _p.winner == Outcome.home, locked,
          () => setState(() => _p.winner = Outcome.home)),
      _chip(context, 'Draw', _p.winner == Outcome.draw, locked,
          () => setState(() => _p.winner = Outcome.draw)),
      _chip(context, m.away?.code ?? 'Away', _p.winner == Outcome.away, locked,
          () => setState(() => _p.winner = Outcome.away)),
    ]);
  }

  Widget _scoreMarket(BuildContext context, bool locked) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stepper(context, m.home?.code ?? 'H', _p.homeScore ?? 0, locked,
              (v) => setState(() => _p.homeScore = v)),
          Text(':',
              style: context.texts.displaySmall?.copyWith(fontSize: 28)),
          _stepper(context, m.away?.code ?? 'A', _p.awayScore ?? 0, locked,
              (v) => setState(() => _p.awayScore = v)),
        ],
      ),
    );
  }

  Widget _stepper(BuildContext context, String label, int value, bool locked,
      ValueChanged<int> onChange) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: context.semantic.textDim, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            _miniBtn(context, Icons.remove,
                locked ? null : () => onChange((value - 1).clamp(0, 15))),
            SizedBox(
              width: 40,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: context.texts.titleLarge?.copyWith(fontSize: 24)),
            ),
            _miniBtn(context, Icons.add,
                locked ? null : () => onChange((value + 1).clamp(0, 15))),
          ],
        ),
      ],
    );
  }

  Widget _miniBtn(BuildContext context, IconData icon, VoidCallback? onTap) {
    return Material(
      color: context.semantic.bg2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 18,
              color: onTap == null
                  ? context.semantic.textDim
                  : context.scheme.primary),
        ),
      ),
    );
  }

  Widget _yesNoMarket(BuildContext context, bool locked,
      {required bool? value, required ValueChanged<bool> onPick}) {
    return _row(context, [
      _chip(context, 'Yes', value == true, locked, () => onPick(true)),
      _chip(context, 'No', value == false, locked, () => onPick(false)),
    ]);
  }

  Widget _overUnderMarket(BuildContext context, bool locked) {
    // 'under' = 0–2 total goals, 'over' = 3 or more.
    return _row(context, [
      _chip(context, 'Under 3', _p.overUnder == 'under', locked,
          () => setState(() => _p.overUnder = 'under')),
      _chip(context, '3 or more', _p.overUnder == 'over', locked,
          () => setState(() => _p.overUnder = 'over')),
    ]);
  }

  Widget _sideMarket(BuildContext context, bool locked,
      {required String? value,
      required ValueChanged<String> onPick,
      required bool includeNone}) {
    return _row(context, [
      _chip(context, m.home?.code ?? 'Home', value == 'home', locked,
          () => onPick('home')),
      if (includeNone)
        _chip(context, 'None', value == 'none', locked, () => onPick('none')),
      _chip(context, m.away?.code ?? 'Away', value == 'away', locked,
          () => onPick('away')),
    ]);
  }

  Widget _row(BuildContext context, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );

  Widget _chip(BuildContext context, String label, bool selected, bool locked,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.scheme.primary : context.semantic.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? Colors.transparent : context.semantic.border),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? context.scheme.onPrimary
                    : (locked ? context.semantic.textDim : null))),
      ),
    );
  }
}
