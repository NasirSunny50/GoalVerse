import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/match.dart';
import '../env.dart';
import '../theme/app_colors.dart';

/// Small pill showing LIVE / UPCOMING / FT status with a pulsing live dot.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.liveLabel});

  final MatchStatus status;

  /// For live matches: the broadcast clock, e.g. "67:12" or "HT".
  final String? liveLabel;

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case MatchStatus.live:
        color = AppColors.live;
        label = liveLabel ?? 'LIVE';
        break;
      case MatchStatus.upcoming:
        color = AppColors.upcoming;
        label = 'UPCOMING';
        break;
      case MatchStatus.finished:
        color = AppColors.finished;
        label = 'FULL TIME';
        break;
    }

    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.live && !kScreenshotMode)
            dot
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
                .then()
                .fade(begin: 1, end: 0.2, duration: 700.ms)
          else
            dot,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
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
