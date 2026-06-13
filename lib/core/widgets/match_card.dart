import 'package:flutter/material.dart';

import '../../data/models/match.dart';
import '../../data/sim/match_engine.dart';
import '../../features/match_details/match_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'glass_card.dart';
import 'status_pill.dart';
import 'team_badge.dart';

/// The primary fixture card used everywhere a match is shown in a list.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.now,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final FootballMatch match;
  final DateTime now;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final st = MatchEngine.stateAt(match, now);
    final status = st.status;

    return GlassCard(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stageChip(context),
              const Spacer(),
              StatusPill(
                status: status,
                liveLabel:
                    status == MatchStatus.live ? st.clock : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _teamColumn(context, isHome: true)),
              _centerColumn(context, st),
              Expanded(child: _teamColumn(context, isHome: false)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.stadium_outlined,
                  size: 14, color: context.semantic.textDim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${match.venue.name} • ${match.venue.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.semantic.textDim),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageChip(BuildContext context) {
    final label = match.stage == MatchStage.groupStage
        ? 'GROUP ${match.group}'
        : match.stage.label.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.group.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.group,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _teamColumn(BuildContext context, {required bool isHome}) {
    final team = isHome ? match.home : match.away;
    final name = isHome ? match.homeName : match.awayName;
    return Column(
      children: [
        TeamBadge(team: team, size: 54),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.texts.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _centerColumn(BuildContext context, LiveState st) {
    if (st.status == MatchStatus.upcoming) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              Dates.time(match.kickoffBd),
              style: context.texts.titleLarge?.copyWith(fontSize: 19),
            ),
            Text(
              'BD',
              style: context.texts.bodySmall?.copyWith(
                  color: context.scheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              Dates.day(match.kickoffBd), // e.g. "Sun, 14 Jun"
              textAlign: TextAlign.center,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim, fontSize: 11),
            ),
          ],
        ),
      );
    }
    final live = st.status == MatchStatus.live;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            '${st.homeScore} - ${st.awayScore}',
            style: context.texts.displaySmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: live ? AppColors.live : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            live ? st.statusText : 'FULL TIME',
            style: TextStyle(
              color: live ? AppColors.live : context.semantic.textDim,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
