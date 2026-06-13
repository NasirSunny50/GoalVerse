import 'dart:async';

import 'package:flutter/material.dart';

import '../core/env.dart';
import '../data/models/match.dart';
import '../data/models/team.dart';
import '../data/repositories/fixtures_repository.dart';
import '../data/services/compete_api.dart';
import '../data/services/live_data_service.dart';
import '../data/sources/teams_data.dart';

/// Exposes the schedule plus a ticking [now]. On top of the (offline-safe)
/// generated schedule it overlays REAL scores/status from the live data
/// source and polls for updates, so the app shows genuine live data when
/// online and still works when offline.
class FixturesProvider extends ChangeNotifier {
  FixturesProvider({LiveDataService? service, CompeteApi? competeApi})
      : _service = service ?? LiveDataService(),
        _compete = competeApi ?? CompeteApi() {
    _rebuild();
    if (!kScreenshotMode) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _now = DateTime.now();
        notifyListeners();
      });
      // First full sync, then poll a rolling window for live updates.
      _syncAll();
      _syncAssignments();
      _poll = Timer.periodic(const Duration(seconds: 30), (_) {
        _syncLive();
        _syncAssignments();
      });
    }
  }

  final LiveDataService _service;
  final CompeteApi _compete;
  late FixturesRepository _repo;
  late Map<String, FootballMatch> _byTeams;
  late Map<String, FootballMatch> _byId;
  Timer? _ticker;
  Timer? _poll;
  DateTime _now = DateTime.now();

  bool _liveConnected = false;
  bool _liveLoading = true;
  DateTime? _lastSync;

  /// True once at least one successful real-data sync has happened.
  bool get liveConnected => _liveConnected;
  bool get liveLoading => _liveLoading;
  DateTime? get lastSync => _lastSync;

  DateTime get now => _now;
  DateTime get nowBd => _now.toUtc().add(const Duration(hours: 6));

  FixturesRepository get repo => _repo;
  List<FootballMatch> get matches => _repo.matches;

  void _rebuild() {
    _repo = FixturesRepository(now: DateTime.now());
    _now = DateTime.now();
    _byId = {for (final m in _repo.matches) m.id: m};
    _byTeams = {
      for (final m in _repo.matches)
        if (m.home != null && m.away != null)
          _key(m.home!.name, m.away!.name): m,
    };
  }

  /// admin match result (public once recorded), keyed by match id — for the
  /// read-only review of matches the user did or did NOT predict.
  final Map<String, Map<String, dynamic>> _results = {};
  Map<String, dynamic>? matchResult(String id) => _results[id];

  /// Pulls from the backend `/fixtures`: overlays admin knockout team
  /// assignments onto placeholder slots AND captures each match's admin result.
  Future<void> _syncAssignments() async {
    try {
      final fx = await _compete.serverFixtures();
      var changed = false;
      for (final raw in fx) {
        final f = (raw as Map);
        final id = '${f['id']}';
        final m = _byId[id];
        if (m == null) continue;
        final result = f['result'];
        if (result is Map) {
          _results[id] = result.cast<String, dynamic>();
        } else {
          _results.remove(id);
        }
        // Knockout slots get their teams from the admin assignment.
        if (m.stage != MatchStage.groupStage) {
          final newHome = _teamOrNull(f['homeId']);
          final newAway = _teamOrNull(f['awayId']);
          if (m.home?.id != newHome?.id) {
            m.home = newHome;
            changed = true;
          }
          if (m.away?.id != newAway?.id) {
            m.away = newAway;
            changed = true;
          }
        }
      }
      if (changed) notifyListeners();
    } catch (_) {
      // Offline / server down — keep whatever we have.
    }
  }

  Team? _teamOrNull(dynamic id) =>
      (id is String && id.isNotEmpty) ? kTeamsById[id] : null;

  // ---- Live sync ----------------------------------------------------------

  static final DateTime _tournamentStart = DateTime.utc(2026, 6, 11);

  Future<void> _syncAll() async {
    _liveLoading = true;
    notifyListeners();
    try {
      final nowUtc = DateTime.now().toUtc();
      final events = await _service.fetchRange(
          _tournamentStart, nowUtc.add(const Duration(days: 1)));
      _apply(events);
      _liveConnected = true;
      _lastSync = DateTime.now();
    } catch (_) {
      _liveConnected = false;
    } finally {
      _liveLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncLive() async {
    try {
      final nowUtc = DateTime.now().toUtc();
      final events = await _service.fetchRange(
          nowUtc.subtract(const Duration(days: 1)),
          nowUtc.add(const Duration(days: 1)));
      _apply(events);
      _liveConnected = true;
      _lastSync = DateTime.now();
      notifyListeners();
    } catch (_) {
      // keep last good data; stay quiet on transient failures
    }
  }

  /// Manual refresh (pull-to-refresh / reload button). Re-syncs everything.
  Future<void> refreshNow() async {
    await _syncAll();
    await _syncAssignments();
  }

  /// Fetches real per-match detail (goals, cards, subs, lineups, stats).
  Future<EventDetail?> fetchDetail(FootballMatch m) async {
    if (m.home == null || m.away == null) return null;
    var id = m.remoteId;
    if (id == null || id.isEmpty) {
      try {
        final events = await _service.fetchDay(m.kickoff.toUtc());
        for (final e in events) {
          if (_key(e.homeName, e.awayName) ==
              _key(m.home!.name, m.away!.name)) {
            id = e.id;
            m.remoteId = e.id;
            break;
          }
        }
      } catch (_) {}
    }
    if (id == null || id.isEmpty) return null;
    try {
      return await _service.fetchDetail(id);
    } catch (_) {
      return null;
    }
  }

  void _apply(List<RemoteEvent> events) {
    for (final e in events) {
      final m = _byTeams[_key(e.homeName, e.awayName)];
      if (m == null) continue;
      final sameOrder = _canon(e.homeName) == _canon(m.home!.name);
      m.remoteId = e.id;
      m.remoteStatus = e.status;
      m.remoteFinished = e.isFinished;
      m.remoteNotStarted = e.isNotStarted;
      m.remoteHalfTime = e.isHalfTime;
      m.remoteHomeScore = sameOrder ? e.homeScore : e.awayScore;
      m.remoteAwayScore = sameOrder ? e.awayScore : e.homeScore;
      // Feed real results into the standings.
      if (e.isFinished) {
        m.homeScore = m.remoteHomeScore;
        m.awayScore = m.remoteAwayScore;
        m.minute = null;
      } else {
        m.homeScore = null;
        m.awayScore = null;
      }
    }
  }

  String _key(String a, String b) {
    final x = [_canon(a), _canon(b)]..sort();
    return x.join('|');
  }

  /// Normalises a nation name to a canonical token so the live source's
  /// spellings match ours (e.g. "Czech Republic" == "Czechia").
  String _canon(String name) {
    var s = name.toLowerCase();
    const accents = {
      'ç': 'c', 'ü': 'u', 'é': 'e', 'è': 'e', 'í': 'i', 'á': 'a',
      'ó': 'o', 'ñ': 'n', 'ã': 'a', 'â': 'a', 'ô': 'o', 'ı': 'i',
      'ş': 's', 'ğ': 'g', 'ø': 'o', 'å': 'a', 'ä': 'a', 'ö': 'o',
    };
    accents.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp('[^a-z0-9]'), '');
    const alias = {
      'czechrepublic': 'czechia',
      'korearepublic': 'southkorea',
      'republicofkorea': 'southkorea',
      'unitedstates': 'usa',
      'unitedstatesofamerica': 'usa',
      'congodr': 'drcongo',
      'democraticrepublicofcongo': 'drcongo',
      'cotedivoire': 'ivorycoast',
      'turkey': 'turkiye',
      'caboverde': 'capeverde',
      'bosniaandherzegovina': 'bosniaherzegovina',
      'iranislamicrepublic': 'iran',
    };
    return alias[s] ?? s;
  }

  // ---- Queries ------------------------------------------------------------

  List<FootballMatch> matchesOnDay(DateTime bdDay) => _repo.matchesOnDay(bdDay);

  List<FootballMatch> get todayMatches => _repo.matchesOnDay(nowBd);

  List<FootballMatch> get liveMatches => matches
      .where((m) => m.statusAt(_now) == MatchStatus.live)
      .toList()
    ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

  List<FootballMatch> get upcomingMatches => matches
      .where((m) => m.statusAt(_now) == MatchStatus.upcoming)
      .toList()
    ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

  FootballMatch? get nextMatch {
    final up = upcomingMatches;
    return up.isEmpty ? null : up.first;
  }

  FootballMatch? get blockbusterMatch {
    final candidates = upcomingMatches
        .where((m) => m.home != null && m.away != null)
        .toList()
      ..sort((a, b) => (b.home!.rating + b.away!.rating)
          .compareTo(a.home!.rating + a.away!.rating));
    return candidates.isEmpty ? null : candidates.first;
  }

  List<FootballMatch> favoriteMatches(Set<String> favoriteIds) {
    if (favoriteIds.isEmpty) return const [];
    return matches
        .where((m) => favoriteIds.any((id) => m.involvesTeam(id)))
        .toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poll?.cancel();
    _service.dispose();
    _compete.dispose();
    super.dispose();
  }
}
