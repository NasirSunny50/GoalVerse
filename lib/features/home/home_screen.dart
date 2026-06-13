import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/goalverse_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/match.dart';
import '../../data/models/venue.dart';
import '../../data/sources/venues_data.dart';
import '../../providers/app_state.dart';
import '../../providers/fixtures_provider.dart';
import '../venues/venue_detail_screen.dart';
import 'widgets/hero_match_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fixtures = context.watch<FixturesProvider>();
    final appState = context.watch<AppState>();
    final now = fixtures.now;

    final live = fixtures.liveMatches;
    // Hero = a live match if one is on now, otherwise the next upcoming match.
    final hero = live.isNotEmpty ? live.first : fixtures.nextMatch;
    final today = fixtures.todayMatches;
    final favMatches = fixtures
        .favoriteMatches(appState.favorites)
        .where((m) => m.statusAt(now) != MatchStatus.finished)
        .take(6)
        .toList();

    return GradientScaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<FixturesProvider>().refreshNow(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(child: _TopBar(now: now)),
          SliverToBoxAdapter(child: _TournamentPulse(now: now)),
          if (hero != null)
            SliverToBoxAdapter(
              child: HeroMatchBanner(
                match: hero,
                now: now,
                label: live.isNotEmpty ? 'LIVE NOW' : 'NEXT MATCH',
              ),
            ),
          SliverToBoxAdapter(child: _QuickFilters()),
          // Selected teams' fixtures come right after the hero.
          if (favMatches.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                  title: 'Your Teams', icon: Icons.favorite),
            ),
            SliverList.builder(
              itemCount: favMatches.length,
              itemBuilder: (_, i) =>
                  MatchCard(match: favMatches[i], now: now),
            ),
          ],
          // Any other live matches not shown in the hero.
          if (live.length > 1) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                  title: 'Also Live',
                  icon: Icons.bolt,
                  actionLabel: '${live.length - 1}'),
            ),
            SliverList.builder(
              itemCount: live.length - 1,
              itemBuilder: (_, i) =>
                  MatchCard(match: live[i + 1], now: now),
            ),
          ],
          SliverToBoxAdapter(
            child: SectionHeader(
              title: today.isEmpty ? 'Next Up' : "Today's Matches",
              icon: Icons.today,
            ),
          ),
          _todaySliver(context, today, fixtures, now),
          const SliverToBoxAdapter(
            child: SectionHeader(
                title: 'Host Cities', icon: Icons.location_on),
          ),
          SliverToBoxAdapter(child: _HostCityRail()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: SizedBox(
                height: 100 + MediaQuery.of(context).viewPadding.bottom),
          ),
          ],
        ),
      ),
    );
  }

  Widget _todaySliver(BuildContext context, List<FootballMatch> today,
      FixturesProvider fixtures, DateTime now) {
    final list = today.isNotEmpty ? today : fixtures.upcomingMatches.take(4).toList();
    if (list.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => MatchCard(match: list[i], now: now),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Dates.dayLong(now.toUtc().add(const Duration(hours: 6))),
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.semantic.textDim)),
              const SizedBox(height: 4),
              GoalVerseLogo(
                  markSize: 34,
                  fontSize: 24,
                  onDark: Theme.of(context).brightness == Brightness.dark),
              Text('World Cup 2026',
                  style: context.texts.bodySmall?.copyWith(
                      color: context.semantic.textDim,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          _circleButton(
            context,
            icon: appState.isDark ? Icons.light_mode : Icons.dark_mode,
            onTap: () => context.read<AppState>().toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: context.semantic.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: context.scheme.primary),
        ),
      ),
    );
  }
}

class _TournamentPulse extends StatelessWidget {
  const _TournamentPulse({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fixtures = context.read<FixturesProvider>();
    final total = fixtures.matches.length;
    final played = fixtures.matches
        .where((m) => m.statusAt(now) == MatchStatus.finished)
        .length;
    final progress = played / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          _stat(context, '$played', 'Played'),
          _divider(context),
          _stat(context, '${total - played}', 'To Go'),
          _divider(context),
          _stat(context, '${(progress * 100).round()}%', 'Complete'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String v, String l) {
    return Expanded(
      child: Column(
        children: [
          Text(v,
              style: context.texts.titleLarge
                  ?.copyWith(fontSize: 20, color: context.scheme.primary)),
          Text(l,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
      width: 1, height: 28, color: context.semantic.border);
}

class _QuickFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fixtures = context.read<FixturesProvider>();
    final filters = <_Filter>[
      _Filter('⚡ Live', () => _open(context, fixtures.liveMatches, 'Live')),
      _Filter('📅 Today', () => _open(context, fixtures.todayMatches, 'Today')),
      _Filter(
          '🏆 Knockouts',
          () => _open(
              context,
              fixtures.matches
                  .where((m) => m.stage.isKnockout)
                  .toList(),
              'Knockout Stage')),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          return ActionChip(
            label: Text(f.label),
            onPressed: f.onTap,
            backgroundColor: context.semantic.card,
            side: BorderSide(color: context.semantic.border),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, List<FootballMatch> matches, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MatchListScreen(title: title, matches: matches),
    ));
  }
}

class _Filter {
  _Filter(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}

class _HostCityRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kVenues.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final v = kVenues[i];
          return _HostCityCard(venue: v)
              .animate()
              .fadeIn(delay: (i * 40).ms, duration: 300.ms);
        },
      ),
    );
  }
}

class _HostCityCard extends StatelessWidget {
  const _HostCityCard({required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      )),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              venue.accent,
              Color.lerp(venue.accent, Colors.black, 0.45)!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(venue.countryFlag, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(venue.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 2),
            Text(venue.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.groups,
                    color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text('${(venue.capacity / 1000).round()}k',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic match list page reused by the quick filters.
class _MatchListScreen extends StatelessWidget {
  const _MatchListScreen({required this.title, required this.matches});
  final String title;
  final List<FootballMatch> matches;

  @override
  Widget build(BuildContext context) {
    final now = context.watch<FixturesProvider>().now;
    return GradientScaffold(
      appBar: AppBar(title: Text(title)),
      body: matches.isEmpty
          ? Center(
              child: Text('No matches here right now',
                  style: TextStyle(color: context.semantic.textDim)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: matches.length,
              itemBuilder: (_, i) => MatchCard(match: matches[i], now: now),
            ),
    );
  }
}
