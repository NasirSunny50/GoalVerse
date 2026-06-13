import '../models/match.dart';
import '../models/team.dart';
import '../sources/players_data.dart';

/// A goal event on the match timeline.
class GoalEvent {
  GoalEvent({
    required this.minute,
    required this.isHome,
    required this.scorer,
    required this.team,
    this.assist,
  });

  final int minute;
  final bool isHome;
  final String scorer;
  final String? assist;
  final Team team;
}

/// Phase of a live match — drives the broadcast clock & labels.
enum MatchPhase {
  upcoming,
  firstHalf,
  firstHalfAdded,
  halfTime,
  secondHalf,
  secondHalfAdded,
  fullTime,
}

/// Snapshot of a match at a given instant — drives the realtime UI.
class LiveState {
  LiveState({
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.elapsed,
    required this.minute,
    required this.second,
    required this.phase,
    required this.addedTime,
    required this.events,
  });

  final MatchStatus status;
  final int homeScore;
  final int awayScore;
  final Duration elapsed;
  final int minute;
  final int second;
  final MatchPhase phase;
  final int addedTime; // minutes of stoppage currently shown
  final List<GoalEvent> events;

  bool get isHalfTime => phase == MatchPhase.halfTime;
  bool get isAddedTime =>
      phase == MatchPhase.firstHalfAdded ||
      phase == MatchPhase.secondHalfAdded;

  /// Broadcast clock for the pill, e.g. "67:12", "45+2'", "HT", "FT".
  String get clock {
    switch (phase) {
      case MatchPhase.firstHalf:
      case MatchPhase.secondHalf:
        return '${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
      case MatchPhase.firstHalfAdded:
        return "45+$addedTime'";
      case MatchPhase.secondHalfAdded:
        return "90+$addedTime'";
      case MatchPhase.halfTime:
        return 'HT';
      case MatchPhase.fullTime:
        return 'FT';
      case MatchPhase.upcoming:
        return '';
    }
  }

  /// Longer status caption.
  String get statusText {
    switch (phase) {
      case MatchPhase.halfTime:
        return 'HALF TIME';
      case MatchPhase.fullTime:
        return 'FULL TIME';
      case MatchPhase.firstHalfAdded:
      case MatchPhase.secondHalfAdded:
        return '+$addedTime MIN ADDED';
      default:
        return 'LIVE';
    }
  }
}

/// Aggregated stats for one team.
class TeamStats {
  TeamStats({
    required this.possession,
    required this.shots,
    required this.onTarget,
    required this.corners,
    required this.fouls,
    required this.offsides,
    required this.passes,
    required this.passAccuracy,
  });

  final int possession;
  final int shots;
  final int onTarget;
  final int corners;
  final int fouls;
  final int offsides;
  final int passes;
  final int passAccuracy;
}

class Player {
  const Player({required this.number, required this.name, required this.pos});
  final int number;
  final String name;
  final String pos; // GK / DEF / MID / FWD
}

class Lineup {
  const Lineup({required this.formation, required this.players});
  final String formation;
  final List<Player> players;
}

class _Rng {
  _Rng(this._s);
  int _s;
  double next() {
    _s = (1103515245 * _s + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }

  int range(int min, int max) => min + (next() * (max - min + 1)).floor();
}

int _seed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = (h ^ c) * 0x01000193 & 0x7fffffff;
  }
  return h == 0 ? 1 : h;
}

/// Deterministic match simulation. Every output is a pure function of the
/// match id (and the clock for live state), so results are stable per session
/// and the same on every device — while still evolving live, second by second.
class MatchEngine {
  MatchEngine._();

  static const _names = [
    'Silva', 'Santos', 'Pereira', 'López', 'García', 'Martínez', 'Rodríguez',
    'Fernández', 'Müller', 'Schmidt', 'Rossi', 'Bianchi', 'Dubois', 'Bernard',
    'Kovač', 'Novák', 'Hassan', 'Diallo', 'Traoré', 'Okafor', 'Mensah', 'Abe',
    'Tanaka', 'Kim', 'Lee', 'Park', 'Khan', 'Ali', 'Haaland', 'Kane', 'Mbappé',
    'Messi', 'Vinícius', 'Bellingham', 'Yamal', 'Modrić', 'Lukaku', 'Son',
    'Osimhen', 'Salah', 'Mahrez', 'Suárez', 'Núñez', 'Álvarez', 'Pulisic',
    'Davies', 'Mitoma', 'Gakpo', 'Nielsen', 'Andersson',
  ];

  // ---- Result -------------------------------------------------------------

  /// Deterministic full-time score.
  static (int, int) fullTime(FootballMatch m) {
    if (m.home == null || m.away == null) return (0, 0);
    final rng = _Rng(_seed(m.id));
    final diff = (m.home!.rating - m.away!.rating) / 22.0;
    final hg = _goals(rng, (1.25 + diff).clamp(0.2, 3.2));
    final ag = _goals(rng, (1.25 - diff).clamp(0.2, 3.2));
    return (hg, ag);
  }

  static int _goals(_Rng rng, double lambda) {
    var l = 1.0;
    final target = _expNeg(lambda);
    var k = 0;
    while (true) {
      l *= rng.next();
      if (l <= target || k >= 7) break;
      k++;
    }
    return k;
  }

  static double _expNeg(double x) {
    var term = 1.0, sum = 1.0;
    for (var n = 1; n < 20; n++) {
      term *= -x / n;
      sum += term;
    }
    return sum < 0 ? 0 : sum;
  }

  // ---- Timeline -----------------------------------------------------------

  /// Full list of goals with minutes and scorers (full-time).
  static List<GoalEvent> timeline(FootballMatch m) {
    if (m.home == null || m.away == null) return const [];
    final (hg, ag) = fullTime(m);
    final rng = _Rng(_seed('${m.id}-tl'));
    final used = <int>{};
    int minute() {
      var v = rng.range(1, 92);
      while (used.contains(v)) {
        v = rng.range(1, 92);
      }
      used.add(v);
      return v;
    }

    final home = squad(m.home!);
    final away = squad(m.away!);
    final events = <GoalEvent>[];
    for (var i = 0; i < hg; i++) {
      final p = _attacker(home, rng);
      events.add(GoalEvent(
          minute: minute(), isHome: true, scorer: p.name, team: m.home!));
    }
    for (var i = 0; i < ag; i++) {
      final p = _attacker(away, rng);
      events.add(GoalEvent(
          minute: minute(), isHome: false, scorer: p.name, team: m.away!));
    }
    events.sort((a, b) => a.minute.compareTo(b.minute));
    return events;
  }

  static Player _attacker(Lineup l, _Rng rng) {
    // Forwards score ~65% of goals, midfielders the rest.
    final fwd = l.players.where((p) => p.pos == 'FWD').toList();
    final mid = l.players.where((p) => p.pos == 'MID').toList();
    final pool = (rng.next() < 0.65 || mid.isEmpty) ? fwd : mid;
    if (pool.isEmpty) return l.players.last;
    return pool[rng.range(0, pool.length - 1)];
  }

  // ---- Live state ---------------------------------------------------------

  // Phase boundaries in seconds since kick-off.
  static const _h1 = 45 * 60; // 2700  end of 1st half play
  static const _st1 = 3 * 60; // +180  1st-half stoppage
  static const _ht = 15 * 60; // +900  half-time break
  static const _h2 = 45 * 60; // +2700 2nd half play
  static const _st2 = 4 * 60; // +240  2nd-half stoppage

  /// Live snapshot for display. Uses REAL data from the live source when
  /// available; otherwise the match is shown as a scheduled fixture (no score,
  /// no clock). The app never displays a simulated/deterministic result.
  static LiveState stateAt(FootballMatch m, DateTime now) {
    if (m.hasRemote) return _remoteState(m, now);
    return _scheduledState();
  }

  /// Neutral "not started" snapshot — shown whenever there is no real data, so
  /// the UI renders the kick-off time/countdown and never a made-up scoreline.
  static LiveState _scheduledState() => LiveState(
        status: MatchStatus.upcoming,
        homeScore: 0,
        awayScore: 0,
        elapsed: Duration.zero,
        minute: 0,
        second: 0,
        phase: MatchPhase.upcoming,
        addedTime: 0,
        events: const [],
      );

  /// Builds the live snapshot from real (remote) scores + status. The score is
  /// authoritative from the API; the clock ticks smoothly from local time and
  /// the goal list is sized to match the real score (with real squad names).
  static LiveState _remoteState(FootballMatch m, DateTime now) {
    final status = m.statusAt(now);
    final hg = m.remoteHomeScore ?? 0;
    final ag = m.remoteAwayScore ?? 0;

    if (status == MatchStatus.upcoming) {
      return LiveState(
        status: status,
        homeScore: 0,
        awayScore: 0,
        elapsed: Duration.zero,
        minute: 0,
        second: 0,
        phase: MatchPhase.upcoming,
        addedTime: 0,
        events: const [],
      );
    }
    if (status == MatchStatus.finished) {
      return LiveState(
        status: status,
        homeScore: hg,
        awayScore: ag,
        elapsed: const Duration(minutes: 90),
        minute: 90,
        second: 0,
        phase: MatchPhase.fullTime,
        addedTime: 0,
        events: _synthEvents(m, hg, ag, 90),
      );
    }

    // Live.
    final elapsed = now.difference(m.kickoff);
    final p = _phaseFromElapsed(elapsed.inSeconds);
    var phase = p.$1;
    var mm = p.$2;
    var ss = p.$3;
    var added = p.$4;
    var goalMinute = p.$5;
    if (m.remoteHalfTime) {
      phase = MatchPhase.halfTime;
      mm = 45;
      ss = 0;
      added = 0;
      goalMinute = 45;
    } else if (phase == MatchPhase.fullTime) {
      // Source still reports the match live past 90' — hold at 90:00 LIVE
      // rather than showing full-time while the status says in-play.
      phase = MatchPhase.secondHalf;
      mm = 90;
      ss = 0;
      added = 0;
      goalMinute = 90;
    }
    return LiveState(
      status: status,
      homeScore: hg,
      awayScore: ag,
      elapsed: elapsed,
      minute: mm,
      second: ss,
      phase: phase,
      addedTime: added,
      events: _synthEvents(m, hg, ag, goalMinute < 1 ? 1 : goalMinute),
    );
  }

  /// Goals sized to a real scoreline, with real squad names & spread minutes.
  static List<GoalEvent> _synthEvents(
      FootballMatch m, int hg, int ag, int upTo) {
    if (m.home == null || m.away == null || (hg + ag) == 0) return const [];
    final rng = _Rng(_seed('${m.id}-rt-$hg-$ag'));
    final home = squad(m.home!);
    final away = squad(m.away!);
    final events = <GoalEvent>[];
    void add(int count, bool isHome, Team t, Lineup sq) {
      for (var i = 0; i < count; i++) {
        final raw = rng.range(2, 90);
        final mn = (raw * upTo / 90).round().clamp(1, upTo);
        events.add(GoalEvent(
            minute: mn, isHome: isHome, scorer: _attacker(sq, rng).name, team: t));
      }
    }

    add(hg, true, m.home!, home);
    add(ag, false, m.away!, away);
    events.sort((a, b) => a.minute.compareTo(b.minute));
    return events;
  }

  /// Maps real elapsed seconds since kick-off to a match phase + clock.
  /// Returns (phase, minute, second, addedTime, goalMinute).
  static (MatchPhase, int, int, int, int) _phaseFromElapsed(int e) {
    if (e < _h1) return (MatchPhase.firstHalf, e ~/ 60, e % 60, 0, e ~/ 60);
    if (e < _h1 + _st1) {
      return (MatchPhase.firstHalfAdded, 45, (e - _h1) % 60,
          ((e - _h1) ~/ 60) + 1, 45);
    }
    if (e < _h1 + _st1 + _ht) return (MatchPhase.halfTime, 45, 0, 0, 45);
    if (e < _h1 + _st1 + _ht + _h2) {
      final t = e - (_h1 + _st1 + _ht);
      return (MatchPhase.secondHalf, 45 + t ~/ 60, t % 60, 0, 45 + t ~/ 60);
    }
    if (e < _h1 + _st1 + _ht + _h2 + _st2) {
      final t = e - (_h1 + _st1 + _ht + _h2);
      return (MatchPhase.secondHalfAdded, 90, t % 60, (t ~/ 60) + 1, 90);
    }
    return (MatchPhase.fullTime, 90, 0, 0, 90);
  }

  // ---- Stats --------------------------------------------------------------

  static (TeamStats, TeamStats) stats(FootballMatch m, DateTime now) {
    final live = stateAt(m, now);
    final frac = live.status == MatchStatus.upcoming
        ? 0.0
        : live.status == MatchStatus.finished
            ? 1.0
            : (live.minute / 90).clamp(0.05, 1.0);
    final rng = _Rng(_seed('${m.id}-st'));
    final d = ((m.home?.rating ?? 75) - (m.away?.rating ?? 75)) / 10.0;

    var possH = (50 + d * 2.2 + rng.range(-4, 4)).round().clamp(34, 66);
    final shotsH = ((9 + d * 0.6) * frac + rng.next() * 2).round();
    final shotsA = ((9 - d * 0.6) * frac + rng.next() * 2).round();

    TeamStats build(int poss, int shots, bool home) {
      final on = (shots * (0.38 + rng.next() * 0.12)).round();
      return TeamStats(
        possession: poss,
        shots: shots.clamp(0, 30),
        onTarget: on.clamp(0, shots),
        corners: ((home ? 5 : 4) * frac + rng.next()).round(),
        fouls: ((home ? 9 : 10) * frac + rng.next() * 2).round(),
        offsides: ((home ? 2 : 2) * frac).round(),
        passes: ((home ? 480 : 430) * (poss / 50) * frac).round(),
        passAccuracy: (78 + d.abs() + rng.range(0, 6)).round().clamp(70, 93),
      );
    }

    return (build(possH, shotsH, true), build(100 - possH, shotsA, false));
  }

  // ---- Squad / Lineup -----------------------------------------------------

  static const _nums = [1, 2, 5, 4, 3, 6, 8, 10, 7, 9, 11];
  static const _poss = [
    'GK', 'DEF', 'DEF', 'DEF', 'DEF', 'MID', 'MID', 'MID', 'FWD', 'FWD', 'FWD',
  ];

  /// Real starting eleven (4-3-3) for [team], in position order.
  static Lineup squad(Team team) {
    final names = kSquads[team.id] ?? _fallbackNames(team);
    final players = <Player>[];
    for (var i = 0; i < 11; i++) {
      players.add(Player(
        number: _nums[i],
        name: i < names.length ? names[i] : '${team.code} ${_nums[i]}',
        pos: _poss[i],
      ));
    }
    return Lineup(formation: '4-3-3', players: players);
  }

  static List<String> _fallbackNames(Team team) {
    final rng = _Rng(_seed('${team.id}-sq'));
    return List.generate(11, (_) => _names[rng.range(0, _names.length - 1)]);
  }

  /// Deterministic: did this match have a red card? (~18% of matches.)
  static bool hadRedCard(FootballMatch m) => _seed('${m.id}-rc') % 100 < 18;

  // ---- Win probability ----------------------------------------------------

  /// Returns (homeWin, draw, awayWin) probabilities that sum to 1.0.
  ///
  /// Model: the rating gap is turned into an expected goal supremacy
  /// `sup = (ratingHome − ratingAway) / 12`. A logistic on the supremacy gives
  /// the split of decisive outcomes between the two sides, and the draw share
  /// shrinks as the gap widens (close games draw more often).
  static (double, double, double) winProbability(FootballMatch m) {
    if (m.home == null || m.away == null) return (0.4, 0.2, 0.4);
    final sup = (m.home!.rating - m.away!.rating) / 12.0;
    // Draw likelihood: ~28% for an even tie, decaying with the gap.
    final draw = (0.30 / (1 + sup.abs() * 0.55)).clamp(0.10, 0.32);
    final decisive = 1 - draw;
    final pHomeOfDecisive = 1 / (1 + _exp(-sup)); // logistic
    final home = decisive * pHomeOfDecisive;
    final away = decisive * (1 - pHomeOfDecisive);
    return (home, draw, away);
  }

  static double _exp(double x) {
    // e^x via series, adequate for the small range used here.
    var term = 1.0, sum = 1.0;
    for (var n = 1; n < 25; n++) {
      term *= x / n;
      sum += term;
    }
    return sum;
  }
}
