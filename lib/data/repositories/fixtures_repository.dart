import '../models/match.dart';
import '../models/standing.dart';
import '../sim/match_engine.dart';
import '../sources/schedule_data.dart';
import '../sources/teams_data.dart';
import '../sources/venues_data.dart';

/// Builds the real FIFA 2026 schedule (104 matches) from [kGroupSchedule] and
/// [kKnockoutSchedule], converting each venue-local kick-off into an absolute
/// UTC instant. Scores/standings come ONLY from real live data (overlaid by
/// [FixturesProvider]); matches without real data stay as scheduled fixtures.
class FixturesRepository {
  FixturesRepository({DateTime? now}) : now = now ?? DateTime.now();

  final DateTime now;

  late final List<FootballMatch> matches = _build();

  /// Tournament opening kick-off (Mexico vs South Africa, Estadio Azteca),
  /// 11 June 2026, 13:00 local (UTC−6) → 19:00 UTC.
  static final DateTime kickoffDay = DateTime.utc(2026, 6, 11, 13)
      .subtract(const Duration(hours: -6));

  List<FootballMatch> _build() {
    final seeds = [...kGroupSchedule, ...kKnockoutSchedule];

    // Resolve each seed to a (kickoffUtc, venue) so we can sort chronologically.
    final resolved = seeds.map((s) {
      final venue = venueById(s.venueId);
      final local = DateTime.utc(2026, s.month, s.day, s.hour, s.minute);
      final kickoffUtc = local.subtract(Duration(hours: venue.utcOffset));
      return (seed: s, venue: venue, kickoff: kickoffUtc);
    }).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    // Per-stage counters for readable knockout placeholders.
    final stageCount = <MatchStage, int>{};

    final list = <FootballMatch>[];
    for (var i = 0; i < resolved.length; i++) {
      final r = resolved[i];
      final s = r.seed;
      final number = i + 1;
      final idx = (stageCount[s.stage] = (stageCount[s.stage] ?? 0) + 1);

      String? homePh;
      String? awayPh;
      if (s.homeId == null) {
        final labels = _knockoutLabels(s.stage, idx);
        homePh = labels.$1;
        awayPh = labels.$2;
      }

      final m = FootballMatch(
        id: 'm$number',
        matchNumber: number,
        home: s.homeId == null ? null : teamById(s.homeId!),
        away: s.awayId == null ? null : teamById(s.awayId!),
        venue: r.venue,
        kickoff: r.kickoff,
        stage: s.stage,
        group: s.group,
        homePlaceholder: homePh,
        awayPlaceholder: awayPh,
      );
      list.add(m);
    }
    return list;
  }

  (String, String) _knockoutLabels(MatchStage stage, int idx) {
    switch (stage) {
      case MatchStage.roundOf32:
        const order = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
        final l = order[(idx - 1) % order.length];
        final r = order[idx % order.length];
        return ('Winner Group $l', 'Runner-up Group $r');
      case MatchStage.roundOf16:
        return ('Winner R32-${idx * 2 - 1}', 'Winner R32-${idx * 2}');
      case MatchStage.quarterFinal:
        return ('Winner R16-${idx * 2 - 1}', 'Winner R16-${idx * 2}');
      case MatchStage.semiFinal:
        return ('Winner QF-${idx * 2 - 1}', 'Winner QF-${idx * 2}');
      case MatchStage.thirdPlace:
        return ('Loser SF-1', 'Loser SF-2');
      case MatchStage.finalMatch:
        return ('Winner SF-1', 'Winner SF-2');
      case MatchStage.groupStage:
        return ('TBD', 'TBD');
    }
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  List<FootballMatch> get groupStageMatches =>
      matches.where((m) => m.stage == MatchStage.groupStage).toList();

  List<FootballMatch> matchesForTeam(String teamId) =>
      matches.where((m) => m.involvesTeam(teamId)).toList()
        ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

  /// Matches on a given Bangladesh-time calendar day.
  List<FootballMatch> matchesOnDay(DateTime bdDay) {
    return matches.where((m) {
      final k = m.kickoffBd;
      return k.year == bdDay.year &&
          k.month == bdDay.month &&
          k.day == bdDay.day;
    }).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }

  List<FootballMatch> matchesAtVenue(String venueId) =>
      matches.where((m) => m.venue.id == venueId).toList()
        ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

  /// Group-stage standings table for [group]. Counts live AND finished matches
  /// using the current scoreline so the table updates in real time. Pass [at]
  /// (the live clock) for an up-to-the-second table.
  List<Standing> standingsForGroup(String group, {DateTime? at}) {
    final clock = at ?? now;
    final table = {
      for (final t in teamsInGroup(group)) t.id: Standing(team: t),
    };
    for (final m in groupStageMatches) {
      if (m.group != group) continue;
      final st = MatchEngine.stateAt(m, clock);
      if (st.status == MatchStatus.upcoming) continue;
      table[m.home!.id]!.record(st.homeScore, st.awayScore);
      table[m.away!.id]!.record(st.awayScore, st.homeScore);
    }
    final rows = table.values.toList();
    rows.sort((a, b) {
      if (b.points != a.points) return b.points - a.points;
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference - a.goalDifference;
      }
      if (b.goalsFor != a.goalsFor) return b.goalsFor - a.goalsFor;
      return b.team.rating - a.team.rating;
    });
    return rows;
  }
}
