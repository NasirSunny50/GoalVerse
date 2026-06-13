import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/sim/match_engine.dart';
import '../../providers/fixtures_provider.dart';
import '../teams/team_dashboard_screen.dart';
import '../venues/venue_detail_screen.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});
  final FootballMatch match;

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final now = fx.now; // ticks → realtime
    final st = MatchEngine.stateAt(match, now);
    final hasTeams = match.home != null && match.away != null;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(match.stage == MatchStage.groupStage
            ? 'Group ${match.group}'
            : match.stage.label),
      ),
      body: RefreshIndicator(
        onRefresh: () => fx.refreshNow(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _header(context, st, now),
            if (hasTeams) _winProbability(context),
            _infoCard(context),
            _venueCard(context),
          ],
        ),
      ),
    );
  }

  // ---- Header --------------------------------------------------------------

  Widget _header(BuildContext context, LiveState st, DateTime now) {
    final live = st.status == MatchStatus.live;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: live
              ? const [Color(0xFF35121F), Color(0xFF14121C)]
              : const [Color(0xFF1C2247), Color(0xFF12162E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          StatusPill(status: st.status),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _teamHead(context, match.home, match.homeName)),
              _centerScore(context, st, now),
              Expanded(child: _teamHead(context, match.away, match.awayName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamHead(BuildContext context, Team? team, String name) {
    return GestureDetector(
      onTap: team == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TeamDashboardScreen(team: team))),
      child: Column(
        children: [
          TeamBadge(team: team, size: 70),
          const SizedBox(height: 12),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _centerScore(BuildContext context, LiveState st, DateTime now) {
    if (st.status == MatchStatus.upcoming) {
      final d = match.timeUntil(now);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(Dates.time(match.kickoffBd),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24)),
            const Text('BD time',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(Dates.countdown(d),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    final live = st.status == MatchStatus.live;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text('${st.homeScore} - ${st.awayScore}',
              style: TextStyle(
                  color: live ? AppColors.live : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34)),
          const SizedBox(height: 2),
          if (!live)
            const Text('FULL TIME',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700))
          else if (st.isHalfTime)
            _clockChip(context, 'HALF TIME', AppColors.gold)
          else if (st.isAddedTime)
            _clockChip(context, st.clock, AppColors.gold)
          else
            _clockChip(context, st.clock, AppColors.live),
        ],
      ),
    );
  }

  Widget _clockChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  // ---- Win probability -----------------------------------------------------

  Widget _winProbability(BuildContext context) {
    final (home, draw, away) = MatchEngine.winProbability(match);
    int pct(double v) => (v * 100).round();
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 18, color: context.scheme.primary),
              const SizedBox(width: 8),
              Text('Win Probability', style: context.texts.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _probColumn(context, match.home, '${pct(home)}%',
                  match.home!.primaryColor, CrossAxisAlignment.start),
              _probColumn(context, null, '${pct(draw)}%',
                  context.semantic.textDim, CrossAxisAlignment.center,
                  label: 'Draw'),
              _probColumn(context, match.away, '${pct(away)}%',
                  match.away!.primaryColor, CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                    flex: pct(home).clamp(1, 100),
                    child: Container(
                        height: 12, color: match.home!.primaryColor)),
                Expanded(
                    flex: pct(draw).clamp(1, 100),
                    child: Container(
                        height: 12, color: context.semantic.textDim)),
                Expanded(
                    flex: pct(away).clamp(1, 100),
                    child: Container(
                        height: 12, color: match.away!.primaryColor)),
              ],
            ),
          ).animate().scaleX(
              begin: 0, duration: 700.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _probColumn(BuildContext context, Team? team, String value,
      Color color, CrossAxisAlignment align,
      {String? label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: align == CrossAxisAlignment.end
                ? MainAxisAlignment.end
                : align == CrossAxisAlignment.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: [
              if (team != null) TeamBadge(team: team, size: 22, showRing: false),
              if (team != null) const SizedBox(width: 6),
              Text(team?.code ?? label ?? '',
                  style: TextStyle(
                      color: context.semantic.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: context.texts.titleLarge
                  ?.copyWith(fontSize: 22, color: color)),
        ],
      ),
    );
  }

  // ---- Info ----------------------------------------------------------------

  Widget _infoCard(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          _infoRow(context, Icons.event, 'Date', Dates.dayLong(match.kickoffBd)),
          _infoRow(context, Icons.schedule, 'Kick-off',
              '${Dates.time(match.kickoffBd)} 🇧🇩 BD'),
          _infoRow(context, Icons.emoji_events, 'Stage', match.stage.label),
          _infoRow(context, Icons.tag, 'Match', '#${match.matchNumber}'),
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.semantic.textDim),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child:
                Text(label, style: TextStyle(color: context.semantic.textDim)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.left,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---- Venue ---------------------------------------------------------------

  Widget _venueCard(BuildContext context) {
    final v = match.venue;
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: v),
      )),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: v.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.stadium, color: v.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${v.city}, ${v.country}',
                    style: TextStyle(color: context.semantic.textDim)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
