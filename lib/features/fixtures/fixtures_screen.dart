import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/sources/teams_data.dart';
import '../../providers/fixtures_provider.dart';

class FixturesScreen extends StatefulWidget {
  const FixturesScreen({super.key});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  MatchStage? _stage;
  Team? _team;

  @override
  Widget build(BuildContext context) {
    final fixtures = context.watch<FixturesProvider>();
    final now = fixtures.now;

    var list = fixtures.matches.where((m) {
      if (_stage != null && m.stage != _stage) return false;
      if (_team != null && !m.involvesTeam(_team!.id)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    // Group by Bangladesh-time day for date headers.
    final grouped = <String, List<FootballMatch>>{};
    for (final m in list) {
      final key = Dates.day(m.kickoffBd);
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Fixtures'),
        actions: [
          IconButton(
            icon: Icon(_team == null ? Icons.public : Icons.filter_alt,
                color: _team == null
                    ? context.semantic.textDim
                    : context.scheme.primary),
            onPressed: _pickTeam,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _stageFilter(context),
          if (_team != null) _activeTeamBanner(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<FixturesProvider>().refreshNow(),
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text('No fixtures match your filters',
                              style:
                                  TextStyle(color: context.semantic.textDim)),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 110),
                      children: [
                        for (final entry in grouped.entries) ...[
                          _dateHeader(context, entry.key, entry.value, now),
                          for (final m in entry.value)
                            MatchCard(match: m, now: now),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageFilter(BuildContext context) {
    final stages = <(String, MatchStage?)>[
      ('All', null),
      ('Groups', MatchStage.groupStage),
      ('R32', MatchStage.roundOf32),
      ('R16', MatchStage.roundOf16),
      ('QF', MatchStage.quarterFinal),
      ('SF', MatchStage.semiFinal),
      ('Final', MatchStage.finalMatch),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, stage) = stages[i];
          final selected = _stage == stage;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _stage = stage),
            showCheckmark: false,
            selectedColor: context.scheme.primary,
            backgroundColor: context.semantic.card,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? context.scheme.onPrimary
                  : context.semantic.textDim,
            ),
            side: BorderSide(
                color: selected
                    ? Colors.transparent
                    : context.semantic.border),
          );
        },
      ),
    );
  }

  Widget _activeTeamBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          TeamBadge(team: _team, size: 28),
          const SizedBox(width: 8),
          Text('Filtering: ${_team!.name}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _team = null),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _dateHeader(BuildContext context, String label,
      List<FootballMatch> matches, DateTime now) {
    final nowBd = now.toUtc().add(const Duration(hours: 6));
    final rel = Dates.relativeDay(matches.first.kickoffBd, nowBd);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(rel,
              style: context.texts.titleMedium
                  ?.copyWith(color: context.scheme.primary)),
          const SizedBox(width: 8),
          Text(label,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim)),
          const Spacer(),
          Text('${matches.length} match${matches.length > 1 ? 'es' : ''}',
              style: context.texts.bodySmall
                  ?.copyWith(color: context.semantic.textDim)),
        ],
      ),
    );
  }

  Future<void> _pickTeam() async {
    final picked = await showModalBottomSheet<Team?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TeamPickerSheet(),
    );
    if (picked != null) {
      setState(() => _team = picked.id == 'none' ? null : picked);
    }
  }
}

/// Bottom sheet to filter fixtures by national team, with search.
class _TeamPickerSheet extends StatefulWidget {
  const _TeamPickerSheet();

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final teams = kTeams
        .where((t) =>
            _q.isEmpty || t.name.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: false,
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
                    onTap: () => Navigator.of(context).pop(t),
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
