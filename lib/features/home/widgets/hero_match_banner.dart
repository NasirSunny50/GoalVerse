import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/team_badge.dart';
import '../../../data/models/match.dart';
import '../../../data/models/team.dart';
import '../../../data/sim/match_engine.dart';
import '../../match_details/match_detail_screen.dart';

/// Hero banner. Shows a live scoreline + ticking clock when a match is on,
/// otherwise an animated countdown to the next match.
class HeroMatchBanner extends StatelessWidget {
  const HeroMatchBanner({
    super.key,
    required this.match,
    required this.now,
    this.label = 'NEXT MATCH',
  });

  final FootballMatch match;
  final DateTime now;
  final String label;

  @override
  Widget build(BuildContext context) {
    final st = MatchEngine.stateAt(match, now);
    final isLive = st.status == MatchStatus.live;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLive
                ? const [Color(0xFF3A1020), Color(0xFF1A1020)]
                : const [Color(0xFF20264F), Color(0xFF131730)],
          ),
          border: Border.all(
              color: (isLive ? AppColors.live : Colors.white)
                  .withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: (isLive ? AppColors.live : AppColors.secondary)
                  .withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: isLive
                        ? null
                        : const LinearGradient(
                            colors: AppColors.brandGradient),
                    color: isLive ? AppColors.live : null,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.8)),
                ),
                const Spacer(),
                Text(
                  match.stage == MatchStage.groupStage
                      ? 'Group ${match.group}'
                      : match.stage.label,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _team(match.home, match.homeName)),
                isLive
                    ? _liveScore(st)
                    : const Text('VS',
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                Expanded(child: _team(match.away, match.awayName)),
              ],
            ),
            const SizedBox(height: 20),
            if (isLive)
              _liveFooter(context, st)
            else
              _countdown(context, match.timeUntil(now)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stadium_outlined,
                    size: 14, color: Colors.white60),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${match.venue.name} • ${Dates.kickoff(match.kickoffBd)} BD',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _team(Team? team, String name) {
    return Column(
      children: [
        TeamBadge(team: team, size: 60),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ],
    );
  }

  Widget _liveScore(LiveState st) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('${st.homeScore} - ${st.awayScore}',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 34)),
    );
  }

  Widget _liveFooter(BuildContext context, LiveState st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.live.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.live),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _liveDot(),
          const SizedBox(width: 8),
          Text(st.isHalfTime ? 'HALF TIME' : '${st.clock}  •  LIVE',
              style: const TextStyle(
                  color: AppColors.live,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _liveDot() {
    final dot = Container(
      width: 8,
      height: 8,
      decoration:
          const BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
    );
    if (kScreenshotMode) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 1, end: 0.2, duration: 700.ms);
  }

  Widget _countdown(BuildContext context, Duration d) {
    if (d.isNegative) return const SizedBox.shrink();
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _unit('$days', 'DAYS'),
        _sep(),
        _unit(hours.toString().padLeft(2, '0'), 'HRS'),
        _sep(),
        _unit(mins.toString().padLeft(2, '0'), 'MIN'),
        _sep(),
        _unit(secs.toString().padLeft(2, '0'), 'SEC'),
      ],
    );
  }

  Widget _unit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          alignment: Alignment.center,
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(':',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
      );
}
