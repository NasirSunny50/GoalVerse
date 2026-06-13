import 'package:flutter/material.dart';

import '../../data/models/team.dart';

/// Circular country-flag badge. Renders the nation's flag (emoji) on a subtle
/// team-coloured disc. Falls back to a neutral placeholder for unknown teams.
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.team,
    this.size = 44,
    this.showRing = true,
  });

  final Team? team;
  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    if (team == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.help_outline,
            size: size * 0.5, color: Theme.of(context).colorScheme.outline),
      );
    }

    final t = team!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.primaryColor.withValues(alpha: 0.16),
        border: showRing
            ? Border.all(
                color: t.primaryColor.withValues(alpha: 0.55), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: t.primaryColor.withValues(alpha: 0.28),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              t.flag,
              style: TextStyle(
                fontSize: size * 0.56,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
