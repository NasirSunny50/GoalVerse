import 'package:flutter_test/flutter_test.dart';

import 'package:fifa_world_cup_2026/data/models/match.dart';
import 'package:fifa_world_cup_2026/data/repositories/fixtures_repository.dart';
import 'package:fifa_world_cup_2026/data/sim/match_engine.dart';
import 'package:fifa_world_cup_2026/data/sources/teams_data.dart';
import 'package:fifa_world_cup_2026/data/sources/venues_data.dart';

void main() {
  test('dataset has 48 teams across 12 groups and 16 venues', () {
    expect(kTeams.length, 48);
    expect(kVenues.length, 16);
    for (final g in kGroupLetters) {
      expect(teamsInGroup(g).length, 4, reason: 'Group $g should have 4 teams');
    }
  });

  test('schedule generates 104 unique matches', () {
    final repo = FixturesRepository(now: DateTime(2026, 6, 11, 12));
    expect(repo.matches.length, 104);
    final ids = repo.matches.map((m) => m.id).toSet();
    expect(ids.length, 104, reason: 'match ids must be unique');
  });

  test('kick-off times convert to Bangladesh time (UTC+6) correctly', () {
    final repo = FixturesRepository(now: DateTime(2026, 6, 1));
    // Opener: Mexico vs South Africa, 13:00 local at Estadio Azteca (UTC-6)
    // → 19:00 UTC → 01:00 BD on 12 June.
    final opener =
        repo.matches.firstWhere((m) => m.home?.id == 'mex' && m.away?.id == 'rsa');
    final bd = opener.kickoffBd;
    expect(bd.month, 6);
    expect(bd.day, 12);
    expect(bd.hour, 1);
    expect(bd.minute, 0);
    // Stadium-local time should read back as 13:00.
    expect(opener.kickoffLocal.hour, 13);
  });

  test('win probability sums to 1 and favours the stronger team', () {
    final repo = FixturesRepository(now: DateTime(2026, 6, 1));
    final m = repo.matches.firstWhere(
        (m) => m.home != null && m.home!.rating != m.away!.rating);
    final (h, d, a) = MatchEngine.winProbability(m);
    expect((h + d + a), closeTo(1.0, 0.001));
    if (m.home!.rating > m.away!.rating) {
      expect(h, greaterThan(a));
    } else {
      expect(a, greaterThan(h));
    }
    // Timeline goal count matches the full-time score.
    final (fh, fa) = MatchEngine.fullTime(m);
    final tl = MatchEngine.timeline(m);
    expect(tl.where((e) => e.isHome).length, fh);
    expect(tl.where((e) => !e.isHome).length, fa);
  });

  test('display shows ONLY real data — no simulated score, real clock freezes',
      () {
    final repo = FixturesRepository(now: DateTime(2026, 6, 1));
    final m = repo.matches.firstWhere((m) => m.home != null && m.away != null);

    // No live data → the match is shown as a scheduled fixture, never a
    // fabricated live/finished scoreline.
    final none =
        MatchEngine.stateAt(m, m.kickoff.add(const Duration(minutes: 50)));
    expect(none.status, MatchStatus.upcoming);
    expect(m.statusAt(m.kickoff.add(const Duration(minutes: 50))),
        MatchStatus.upcoming);

    // Real half-time from the live source freezes the clock at 45'.
    m.remoteStatus = 'HT';
    m.remoteHalfTime = true;
    final ht =
        MatchEngine.stateAt(m, m.kickoff.add(const Duration(minutes: 50)));
    expect(ht.phase, MatchPhase.halfTime);
    expect(ht.minute, 45);
    expect(ht.clock, 'HT');

    // Real full-time stops the clock and shows the real score.
    m.remoteStatus = 'FT';
    m.remoteHalfTime = false;
    m.remoteFinished = true;
    m.remoteHomeScore = 2;
    m.remoteAwayScore = 1;
    final done =
        MatchEngine.stateAt(m, m.kickoff.add(const Duration(minutes: 120)));
    expect(done.status, MatchStatus.finished);
    expect(done.clock, 'FT');
    expect(done.homeScore, 2);
    expect(done.awayScore, 1);
  });

  // Prediction scoring is now owned by the backend and covered by the
  // server test suite (server/test/api_test.dart).

  test('standings are computed once results exist', () {
    // Simulate a clock late in the group stage so results are filled in.
    final repo = FixturesRepository(now: DateTime(2026, 6, 30, 12));
    final table = repo.standingsForGroup('A');
    expect(table.length, 4);
    // Table must be sorted by points descending.
    for (var i = 0; i < table.length - 1; i++) {
      expect(table[i].points >= table[i + 1].points, isTrue);
    }
  });

  test('admin result overrides the feed and feeds the group table', () {
    final at = DateTime(2026, 6, 14, 12);
    final repo = FixturesRepository(now: at);
    final m = repo.matches
        .firstWhere((x) => x.group == 'A' && x.home != null && x.away != null);

    // No admin result and no feed -> still upcoming, NOT counted (unchanged).
    expect(MatchEngine.stateAt(m, at).status, MatchStatus.upcoming);

    // Admin records 3-1 -> finished with the admin scoreline.
    m.adminHasResult = true;
    m.adminHomeScore = 3;
    m.adminAwayScore = 1;
    final st = MatchEngine.stateAt(m, at);
    expect(st.status, MatchStatus.finished);
    expect(st.homeScore, 3);
    expect(st.awayScore, 1);
    expect(m.statusAt(at), MatchStatus.finished);

    // A WRONG feed score must NOT win over the admin's result.
    m.remoteStatus = 'FT';
    m.remoteFinished = true;
    m.remoteHomeScore = 0;
    m.remoteAwayScore = 0;
    final st2 = MatchEngine.stateAt(m, at);
    expect(st2.homeScore, 3, reason: 'admin overrides the feed');
    expect(st2.awayScore, 1);

    // The group table now reflects the admin result (a 3-1 home win = +3).
    final homeRow = repo
        .standingsForGroup('A', at: at)
        .firstWhere((r) => r.team.id == m.home!.id);
    expect(homeRow.points, greaterThanOrEqualTo(3));
    expect(homeRow.goalsFor, greaterThanOrEqualTo(3));
  });

  test('clearing the admin result reverts to feed/upcoming (no leftover impact)',
      () {
    final at = DateTime(2026, 6, 14, 12);
    final repo = FixturesRepository(now: at);
    final m = repo.matches.firstWhere((x) => x.group == 'B' && x.home != null);

    // Feed says live 1-0.
    m.remoteStatus = '2H';
    m.remoteHomeScore = 1;
    m.remoteAwayScore = 0;
    expect(MatchEngine.stateAt(m, at).status, MatchStatus.live);

    // Admin records a final -> overrides to finished.
    m.adminHasResult = true;
    m.adminHomeScore = 2;
    m.adminAwayScore = 2;
    expect(MatchEngine.stateAt(m, at).status, MatchStatus.finished);

    // Clearing the admin result falls straight back to the live feed.
    m.adminHasResult = false;
    m.adminHomeScore = null;
    m.adminAwayScore = null;
    expect(MatchEngine.stateAt(m, at).status, MatchStatus.live);
  });
}
