import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../providers/fixtures_provider.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/venue.dart';
import '../../data/sources/teams_data.dart';
import '../../data/sources/venues_data.dart';
import '../road_to_final/road_to_final_screen.dart';
import '../venues/venue_detail_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: RefreshIndicator(
        onRefresh: () => context.read<FixturesProvider>().refreshNow(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 110),
          children: [
            _toolCards(context),
            const SectionHeader(
                title: 'Stadium Explorer', icon: Icons.stadium),
            _stadiumGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _toolCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _ToolCard(
        title: 'Road to the Final',
        subtitle: 'Map any team\'s bracket path to glory',
        icon: Icons.route,
        colors: const [AppColors.secondary, AppColors.primary],
        onTap: () => _pickTeamForRoad(context),
      ),
    );
  }

  void _pickTeamForRoad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoadTeamPicker(),
    );
  }

  Widget _stadiumGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: kVenues.length,
        itemBuilder: (_, i) => _StadiumCard(venue: kVenues[i]),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StadiumCard extends StatelessWidget {
  const _StadiumCard({required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              venue.accent,
              Color.lerp(venue.accent, Colors.black, 0.5)!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(venue.countryFlag, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Icon(Icons.stadium,
                    color: Colors.white.withValues(alpha: 0.5), size: 22),
              ],
            ),
            const Spacer(),
            Text(venue.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${(venue.capacity / 1000).round()}k seats',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadTeamPicker extends StatefulWidget {
  @override
  State<_RoadTeamPicker> createState() => _RoadTeamPickerState();
}

class _RoadTeamPickerState extends State<_RoadTeamPicker> {
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
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.semantic.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('Choose a nation',
                style: context.texts.titleLarge),
            const SizedBox(height: 12),
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
                itemBuilder: (_, i) {
                  final t = teams[i];
                  return ListTile(
                    leading: TeamBadge(team: t, size: 38),
                    title: Text(t.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Group ${t.group}',
                        style: TextStyle(color: context.semantic.textDim)),
                    trailing: const Icon(Icons.route),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RoadToFinalScreen(team: t),
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
