import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/standing.dart';
import '../../data/sources/teams_data.dart';
import '../../providers/app_state.dart';
import '../../providers/fixtures_provider.dart';
import 'team_dashboard_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _query = '';

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: context.scheme.primary,
          labelColor: context.scheme.primary,
          unselectedLabelColor: context.semantic.textDim,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Groups'), Tab(text: 'All Teams')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_groupsView(), _allTeamsView()],
      ),
    );
  }

  Widget _groupsView() {
    final fx = context.watch<FixturesProvider>();
    final now = fx.now;
    return RefreshIndicator(
      onRefresh: () => fx.refreshNow(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          for (final g in kGroupLetters)
            _GroupCard(
              group: g,
              standings: fx.repo.standingsForGroup(g, at: now),
              live: fx.repo.groupStageMatches.any((m) =>
                  m.group == g && m.statusAt(now) == MatchStatus.live),
            ),
        ],
      ),
    );
  }

  Widget _allTeamsView() {
    final appState = context.watch<AppState>();
    final teams = kTeams
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()) ||
            t.code.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final fa = appState.isFavorite(a.id) ? 0 : 1;
        final fb = appState.isFavorite(b.id) ? 0 : 1;
        if (fa != fb) return fa - fb;
        return a.name.compareTo(b.name);
      });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search nations…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: context.semantic.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.semantic.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.semantic.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 110),
            itemCount: teams.length,
            itemBuilder: (_, i) {
              final t = teams[i];
              final fav = appState.isFavorite(t.id);
              return ListTile(
                leading: TeamBadge(team: t, size: 42),
                title: Text(t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Group ${t.group}',
                    style: TextStyle(color: context.semantic.textDim)),
                trailing: IconButton(
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? context.scheme.tertiary : null),
                  onPressed: () =>
                      context.read<AppState>().toggleFavorite(t.id),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TeamDashboardScreen(team: t),
                )),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard(
      {required this.group, required this.standings, this.live = false});
  final String group;
  final List<Standing> standings;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AppColors.group,
                    AppColors.groupAlt,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(group,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text('Group $group', style: context.texts.titleMedium),
              if (live) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.live.withValues(alpha: 0.5)),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: AppColors.live,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ],
              const Spacer(),
              Text('P  W  D  L  Pts',
                  style: context.texts.bodySmall?.copyWith(
                      color: context.semantic.textDim,
                      fontFeatures: const [])),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < standings.length; i++)
            _row(context, i + 1, standings[i]),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int pos, Standing s) {
    final qualifies = pos <= 2;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TeamDashboardScreen(team: s.team),
      )),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text('$pos',
                  style: TextStyle(
                      color: qualifies
                          ? context.scheme.primary
                          : context.semantic.textDim,
                      fontWeight: FontWeight.w700)),
            ),
            TeamBadge(team: s.team, size: 28, showRing: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            _num(context, '${s.played}'),
            _num(context, '${s.won}'),
            _num(context, '${s.drawn}'),
            _num(context, '${s.lost}'),
            _num(context, '${s.points}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _num(BuildContext context, String v, {bool bold = false}) {
    return SizedBox(
      width: 22,
      child: Text(v,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? context.scheme.primary : null)),
    );
  }
}
