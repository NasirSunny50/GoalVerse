import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/match_card.dart';
import '../../data/models/venue.dart';
import '../../providers/fixtures_provider.dart';

class VenueDetailScreen extends StatelessWidget {
  const VenueDetailScreen({super.key, required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final fixtures = context.watch<FixturesProvider>();
    final now = fixtures.now;
    final matches = fixtures.repo.matchesAtVenue(venue.id);

    return GradientScaffold(
      appBar: AppBar(title: Text(venue.city)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _hero(context),
          _facts(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Icon(Icons.event, size: 18, color: context.scheme.primary),
                const SizedBox(width: 8),
                Text('Scheduled Matches', style: context.texts.titleMedium),
                const Spacer(),
                Text('${matches.length}',
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.semantic.textDim)),
              ],
            ),
          ),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No matches scheduled here',
                    style: TextStyle(color: context.semantic.textDim)),
              ),
            )
          else
            for (final m in matches) MatchCard(match: m, now: now),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            venue.accent,
            Color.lerp(venue.accent, Colors.black, 0.55)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.stadium,
                size: 180, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(venue.countryFlag, style: const TextStyle(fontSize: 30)),
                const Spacer(),
                Text(venue.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24)),
                const SizedBox(height: 4),
                Text('${venue.city}, ${venue.country}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facts(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _factCard(context, Icons.groups, 'Capacity',
                _formatNumber(venue.capacity))),
        Expanded(
            child: _factCard(
                context, Icons.public, 'Country', venue.country)),
        Expanded(
            child: _factCard(context, Icons.schedule, 'Time Zone',
                venue.timeZone)),
      ],
    );
  }

  Widget _factCard(
      BuildContext context, IconData icon, String label, String value) {
    return GlassCard(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: context.scheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
