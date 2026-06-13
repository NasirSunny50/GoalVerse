import 'dart:io';
import 'dart:math' as math;

import 'fixtures.dart';
import 'store.dart';
import 'tournament_result.dart';

/// Point values — must match the app's `Points`.
class Points {
  // Per-match markets.
  static const winner = 10;
  static const exact = 25;
  static const firstScorer = 12;
  static const overUnder = 8; // Over/Under 2.5 goals (derived from the score)
  static const btts = 8; // Both Teams To Score (derived from the score)
  static const penalties = 10; // knockout only — decided on penalties?

  // Tournament-long markets (graded once the Final result is recorded).
  static const champion = 50;
  static const runnerUp = 30;
  static const goldenBoot = 20;
  static const goldenGlove = 20;

  static const perPredictionXp = 10;
}

enum Period { global, weekly, monthly, allTime }

int _seed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = (h ^ c) * 0x01000193 & 0x7fffffff;
  }
  return h;
}

/// The winner implied by an admin-confirmed result: an explicit admin pick if
/// present (handles knockout/penalty calls), otherwise derived from the score.
String? _winnerOf(Map<String, dynamic> r) {
  if (r['winner'] != null) return r['winner'] as String;
  final hs = r['homeScore'], as = r['awayScore'];
  if (hs == null || as == null) return null;
  return hs > as ? 'home' : (hs < as ? 'away' : 'draw');
}

/// Grade one match prediction [p] against the ADMIN-CONFIRMED result [r].
/// Markets: Match Winner, Exact Score, First Team to Score, Over/Under 2.5,
/// Both Teams to Score (these two derived from the score) and — knockout only —
/// decided on Penalties. Each market scores independently; nothing comes from
/// live data.
int gradeMatch(Map<String, dynamic> p, Map<String, dynamic> r) {
  final hs = r['homeScore'] as int?, as = r['awayScore'] as int?;
  final rw = _winnerOf(r);
  final hasScore = hs != null && as != null;
  var pts = 0;
  // Match Winner.
  if (p['winner'] != null && rw != null && p['winner'] == rw) {
    pts += Points.winner;
  }
  // Exact Score — separate bonus on top of the winner points.
  if (hasScore &&
      p['homeScore'] != null &&
      p['awayScore'] != null &&
      p['homeScore'] == hs &&
      p['awayScore'] == as) {
    pts += Points.exact;
  }
  // First Team to Score.
  if (p['firstScorerSide'] != null &&
      r['firstScorer'] != null &&
      p['firstScorerSide'] == r['firstScorer']) {
    pts += Points.firstScorer;
  }
  // Over/Under 2.5 goals — compare to the admin's recorded answer (derived
  // from the score at intake).
  if (p['overUnder'] != null &&
      r['overUnder'] != null &&
      p['overUnder'] == r['overUnder']) {
    pts += Points.overUnder;
  }
  // Both Teams to Score — compare to the admin's recorded answer.
  if (p['btts'] != null && r['btts'] != null && p['btts'] == r['btts']) {
    pts += Points.btts;
  }
  // Decided on penalties? (knockout) — admin-entered.
  if (p['penalties'] != null &&
      r['penalties'] != null &&
      p['penalties'] == r['penalties']) {
    pts += Points.penalties;
  }
  return pts;
}

/// Per-market correctness for the user's read-only review screen — only the
/// markets the user actually picked. Same comparisons as [gradeMatch] so the
/// ticks always agree with the points (single source of truth).
Map<String, bool> marketHits(Map<String, dynamic> p, Map<String, dynamic> r) {
  final rw = _winnerOf(r);
  final hs = r['homeScore'] as int?, as = r['awayScore'] as int?;
  final hasScore = hs != null && as != null;
  final out = <String, bool>{};
  if (p['winner'] != null) out['winner'] = rw != null && p['winner'] == rw;
  if (p['homeScore'] != null && p['awayScore'] != null) {
    out['exact'] = hasScore && p['homeScore'] == hs && p['awayScore'] == as;
  }
  if (p['firstScorerSide'] != null) {
    out['firstScorer'] =
        r['firstScorer'] != null && p['firstScorerSide'] == r['firstScorer'];
  }
  if (p['overUnder'] != null) {
    out['overUnder'] =
        r['overUnder'] != null && p['overUnder'] == r['overUnder'];
  }
  if (p['btts'] != null) {
    out['btts'] = r['btts'] != null && p['btts'] == r['btts'];
  }
  if (p['penalties'] != null) {
    out['penalties'] =
        r['penalties'] != null && p['penalties'] == r['penalties'];
  }
  return out;
}

/// Grade a user's tournament-long prediction against the final [res]. Returns
/// 0 unless the result has been recorded (`res.decided`). Each market is graded
/// independently and only when the user actually picked a team for it.
int gradeTournament(Map<String, dynamic>? t, TournamentResult res) {
  if (t == null || !res.decided) return 0;
  final w = TournamentResult.normId(t['winnerTeamId']);
  final ru = TournamentResult.normId(t['runnerUpTeamId']);
  final gb = TournamentResult.normId(t['goldenBootTeamId']);
  final gg = TournamentResult.normId(t['goldenGloveTeamId']);
  var pts = 0;
  if (w != null && w == res.champion) pts += Points.champion;
  if (ru != null && ru == res.runnerUp) pts += Points.runnerUp;
  if (gb != null && gb == res.goldenBoot) pts += Points.goldenBoot;
  if (gg != null && gg == res.goldenGlove) pts += Points.goldenGlove;
  return pts;
}

bool isCorrect(Map<String, dynamic> p, Map<String, dynamic> r) {
  final rw = _winnerOf(r);
  final exact = p['homeScore'] != null &&
      p['awayScore'] != null &&
      r['homeScore'] != null &&
      r['awayScore'] != null &&
      p['homeScore'] == r['homeScore'] &&
      p['awayScore'] == r['awayScore'];
  return exact || (p['winner'] != null && rw != null && p['winner'] == rw);
}

bool _predEmpty(Map<String, dynamic> p) =>
    p['winner'] == null &&
    p['homeScore'] == null &&
    p['firstScorerSide'] == null &&
    p['overUnder'] == null &&
    p['btts'] == null &&
    p['penalties'] == null;

class Scoring {
  Scoring(this.fixtures, this.store, {TournamentResult Function()? tournamentResult})
      : _tournamentResult = tournamentResult ?? (() => TournamentResult.undecided);
  final Fixtures fixtures;
  final Store store;

  /// Reads the current tournament result on demand (fresh each scoring pass,
  /// so an admin can record it without restarting the server).
  final TournamentResult Function() _tournamentResult;

  /// The currently-recorded tournament result (or [TournamentResult.undecided]).
  TournamentResult get tournamentResult => _tournamentResult();

  /// Tournament points only count once the Final has actually kicked off *and*
  /// a result has been recorded. For weekly/monthly boards they additionally
  /// only count if the Final falls inside the period window.
  int _tournamentPointsFor(String email, TournamentResult res, DateTime now,
      {DateTime? since}) {
    if (!res.decided) return 0;
    if (fixtures.finalKickoff.isAfter(now)) return 0; // Final not played yet
    if (since != null && fixtures.finalKickoff.isBefore(since)) return 0;
    final preds = store.predsFor(email);
    final t = (preds['tournament'] as Map?)?.cast<String, dynamic>();
    return gradeTournament(t, res);
  }

  /// Whether an admin result actually carries an outcome (vs. only a knockout
  /// team assignment with no result entered yet).
  static bool _hasResult(Map<String, dynamic> r) =>
      r['winner'] != null ||
      (r['homeScore'] != null && r['awayScore'] != null);

  /// Fixtures that have an ADMIN-entered RESULT (the matches that score), in
  /// kick-off order. Works for knockout matches too (their teams are assigned
  /// by the admin, not the schedule). [since] optionally restricts the window.
  List<Fixture> _resolved(Map<String, Map<String, dynamic>> results,
      {DateTime? since}) {
    return fixtures.all.where((f) {
      final r = results[f.id];
      if (r == null || !_hasResult(r)) return false;
      if (since != null && f.kickoff.isBefore(since)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }

  /// Per-user score over the admin-confirmed matches in scope.
  ({int points, int made, int correct}) scoreUser(
      Map<String, dynamic> matchPreds,
      List<Fixture> resolved,
      Map<String, Map<String, dynamic>> results) {
    var points = 0, made = 0, correct = 0;
    for (final f in resolved) {
      final p = (matchPreds[f.id] as Map?)?.cast<String, dynamic>();
      if (p == null || _predEmpty(p)) continue;
      final r = results[f.id]!;
      points += gradeMatch(p, r);
      made++;
      if (isCorrect(p, r)) correct++;
    }
    return (points: points, made: made, correct: correct);
  }

  /// Full stats for one user.
  Map<String, dynamic> stats(String email, DateTime now) {
    final preds = store.predsFor(email);
    final matchPreds =
        (preds['match'] as Map?)?.cast<String, dynamic>() ?? {};
    final results = store.matchResults();
    final resolved = _resolved(results);

    var points = 0, made = 0, correct = 0, exact = 0, streak = 0;
    for (final f in resolved) {
      final p = (matchPreds[f.id] as Map?)?.cast<String, dynamic>();
      if (p == null || _predEmpty(p)) continue;
      final r = results[f.id]!;
      points += gradeMatch(p, r);
      made++;
      final ok = isCorrect(p, r);
      if (ok) {
        correct++;
        streak++;
      } else {
        streak = 0;
      }
      if (p['homeScore'] != null &&
          r['homeScore'] != null &&
          p['homeScore'] == r['homeScore'] &&
          p['awayScore'] == r['awayScore']) {
        exact++;
      }
    }

    final res = _tournamentResult();
    final tournamentPoints = _tournamentPointsFor(email, res, now);
    points += tournamentPoints;

    final madeAll = matchPreds.values
        .where((p) => p is Map && !_predEmpty(p.cast<String, dynamic>()))
        .length;
    final xp = points + madeAll * Points.perPredictionXp;
    final level = 1 + (math.sqrt(xp / 120)).floor();
    final lvlBase = (level - 1) * (level - 1) * 120;
    final lvlNext = level * level * 120;

    final board = leaderboard(Period.allTime, now);
    final rank = board.indexWhere((e) => e['email'] == email.toLowerCase()) + 1;

    return {
      'points': points,
      'tournamentPoints': tournamentPoints,
      'predictions': made,
      'correct': correct,
      'exact': exact,
      'accuracy': made == 0 ? 0 : ((correct / made) * 100).round(),
      'streak': streak,
      'xp': xp,
      'level': level,
      'xpIntoLevel': xp - lvlBase,
      'xpForLevel': lvlNext - lvlBase,
      'rank': rank == 0 ? board.length : rank,
      'totalPlayers': board.length,
      'badges': _badges(points, made, correct, exact, streak, level, madeAll),
    };
  }

  static const _botNames = [
    'StrikerKing', 'PitchProphet', 'GoalGuru', 'NetBuster', 'TikiTaka',
    'XGwizard', 'CornerFlag', 'OffsideOwl', 'MidfieldMaestro', 'CleanSheet',
    'HatTrickHero', 'VARvictim', 'DerbyDon', 'ExtraTime', 'PenaltyPete',
    'WingWizard', 'BoxToBox', 'TheGaffer', 'NutmegNinja', 'ScreamerSam',
    'TalismanT', 'GoldenBoot', 'SetPiece', 'CounterClk', 'FalseNine',
    'RabonaRay', 'TikiTina', 'GegenPress', 'ParkBus', 'TotalFooty',
    'BicycleKik', 'KeeperKev', 'SweeperS', 'PoacherP', 'MaestroM',
    'VolleyVic', 'HeaderH', 'DribbleD', 'ClutchC', 'EngineRoom',
  ];

  List<Map<String, dynamic>> leaderboard(Period period, DateTime now) {
    DateTime? since;
    if (period == Period.weekly) {
      since = now.subtract(const Duration(days: 7));
    } else if (period == Period.monthly) {
      since = now.subtract(const Duration(days: 30));
    }
    final results = store.matchResults();
    final resolved = _resolved(results, since: since);
    final res = _tournamentResult();
    final entries = <Map<String, dynamic>>[];

    // Real users.
    for (final u in store.allUsers()) {
      final email = (u['email'] as String).toLowerCase();
      final preds = store.predsFor(email);
      final matchPreds =
          (preds['match'] as Map?)?.cast<String, dynamic>() ?? {};
      final s = scoreUser(matchPreds, resolved, results);
      final tournamentPoints =
          _tournamentPointsFor(email, res, now, since: since);
      entries.add({
        'email': email,
        'name': u['name'],
        'points': s.points + tournamentPoints,
        'predictions': s.made,
        'correct': s.correct,
        'isUser': true,
      });
    }

    // Rival bots (demo competition). Off by default; enable with GV_BOTS=1.
    final botsOn = Platform.environment['GV_BOTS'] == '1';
    for (final name in botsOn ? _botNames : const <String>[]) {
      final skill = 0.32 + (_seed(name) % 60) / 100.0;
      var pts = 0, made = 0, ok = 0;
      for (final f in resolved) {
        final r = (_seed('$name-${f.id}') % 1000) / 1000.0;
        made++;
        if (r < skill) {
          ok++;
          final r2 = (_seed('$name-${f.id}-2') % 1000) / 1000.0;
          pts += r2 < skill * 0.18 ? Points.exact : Points.winner;
          if (r2 < skill * 0.5) pts += Points.firstScorer;
          if (r2 < skill * 0.35) pts += Points.overUnder;
        } else if (r < skill + 0.18) {
          pts += Points.btts;
        }
      }
      if (period == Period.allTime || period == Period.global) {
        pts += _seed('$name-career') % 40;
      }
      entries.add({
        'email': null,
        'name': name,
        'points': pts,
        'predictions': made,
        'correct': ok,
        'isUser': false,
      });
    }

    entries.sort((a, b) {
      if (b['points'] != a['points']) {
        return (b['points'] as int) - (a['points'] as int);
      }
      final aa = a['predictions'] == 0
          ? 0
          : (a['correct'] as int) / (a['predictions'] as int);
      final bb = b['predictions'] == 0
          ? 0
          : (b['correct'] as int) / (b['predictions'] as int);
      return bb.compareTo(aa);
    });
    return entries;
  }

  List<String> _badges(int points, int predictions, int correct, int exact,
      int streak, int level, int madeAll) {
    final out = <String>[];
    if (madeAll >= 1) out.add('first');
    if (madeAll >= 5) out.add('five');
    if (correct >= 1) out.add('correct1');
    if (exact >= 1) out.add('exact');
    if (streak >= 3) out.add('streak3');
    if (streak >= 5) out.add('streak5');
    if (points >= 100) out.add('p100');
    if (level >= 5) out.add('lvl5');
    return out;
  }
}
