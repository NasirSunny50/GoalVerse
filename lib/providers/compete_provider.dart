import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/match.dart';
import '../data/services/compete_api.dart';
import '../features/compete/compete_models.dart';

/// Computed snapshot of a user's competition standing (from the backend).
class CompeteStats {
  CompeteStats({
    required this.points,
    required this.predictions,
    required this.correct,
    required this.exact,
    required this.streak,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
    required this.rank,
    required this.totalPlayers,
    required this.badges,
  });

  final int points;
  final int predictions;
  final int correct;
  final int exact;
  final int streak;
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int xpForLevel;
  final int rank;
  final int totalPlayers;
  final List<String> badges;

  int get accuracy =>
      predictions == 0 ? 0 : ((correct / predictions) * 100).round();

  static CompeteStats empty() => CompeteStats(
      points: 0,
      predictions: 0,
      correct: 0,
      exact: 0,
      streak: 0,
      xp: 0,
      level: 1,
      xpIntoLevel: 0,
      xpForLevel: 120,
      rank: 0,
      totalPlayers: 0,
      badges: const []);

  static CompeteStats fromJson(Map<String, dynamic> j) => CompeteStats(
        points: j['points'] ?? 0,
        predictions: j['predictions'] ?? 0,
        correct: j['correct'] ?? 0,
        exact: j['exact'] ?? 0,
        streak: j['streak'] ?? 0,
        xp: j['xp'] ?? 0,
        level: j['level'] ?? 1,
        xpIntoLevel: j['xpIntoLevel'] ?? 0,
        xpForLevel: j['xpForLevel'] ?? 120,
        rank: j['rank'] ?? 0,
        totalPlayers: j['totalPlayers'] ?? 0,
        badges: ((j['badges'] as List?) ?? const []).cast<String>(),
      );
}

enum LbPeriod { global, weekly, monthly, allTime }

/// Talks to the GoalVerse backend for auth, predictions, scoring and
/// leaderboards. Caches results in memory so the UI can read synchronously;
/// mutations call the API then refresh the cache.
class CompeteProvider extends ChangeNotifier {
  CompeteProvider({CompeteApi? api}) : _api = api ?? CompeteApi() {
    _load();
  }

  final CompeteApi _api;
  SharedPreferences? _prefs;

  bool _ready = false;
  bool get ready => _ready;

  bool _online = true;
  bool get online => _online;

  String? _token;
  String? _userName;
  String? _userEmail;
  String? get user => _userName;
  String? get email => _userEmail;
  bool get loggedIn => _token != null;

  /// True when the signed-in account is the admin (server-validated). Admins
  /// are routed to the result-entry panel, not the normal competition UI.
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  static const String demoOtp = '123456';
  String? _pendingEmail;
  bool get awaitingOtp => _pendingEmail != null;
  String? get pendingEmail => _pendingEmail;

  CompeteStats _stats = CompeteStats.empty();
  final Map<String, MatchPrediction> _matchPreds = {};

  /// Per-match read-only review (admin result + points + per-market ✓/✗) for
  /// matches the user predicted that have been scored. Keyed by match id.
  final Map<String, Map<String, dynamic>> _matchReviews = {};
  Map<String, dynamic>? matchReview(String matchId) => _matchReviews[matchId];
  TournamentPrediction _tourn = TournamentPrediction();
  final Map<LbPeriod, List<LeaderboardEntry>> _boards = {};

  Timer? _refreshTimer;

  TournamentPrediction get tournament => _tourn;

  // ---- session ------------------------------------------------------------

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('gv_token');
    _userName = _prefs!.getString('gv_name');
    _userEmail = _prefs!.getString('gv_email');
    _isAdmin = _prefs!.getBool('gv_admin') ?? false;
    if (_token != null && !_isAdmin) {
      await _refreshAll();
    }
    _ready = true;
    notifyListeners();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _refreshAll());
  }

  Future<void> _persistSession() async {
    if (_token == null) {
      await _prefs?.remove('gv_token');
      await _prefs?.remove('gv_name');
      await _prefs?.remove('gv_email');
      await _prefs?.remove('gv_admin');
    } else {
      await _prefs?.setString('gv_token', _token!);
      await _prefs?.setString('gv_name', _userName ?? '');
      await _prefs?.setString('gv_email', _userEmail ?? '');
      await _prefs?.setBool('gv_admin', _isAdmin);
    }
  }

  // ---- auth ---------------------------------------------------------------

  /// Returns an error message, or null on success (OTP sent).
  Future<String?> register(String name, String employeeId, String email,
      String password, String confirmPassword) async {
    try {
      await _api.register(name, employeeId, email, password, confirmPassword);
      _pendingEmail = email.trim();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Is it running?';
    }
  }

  Future<String?> verifyOtp(String code) async {
    if (_pendingEmail == null) return 'No registration in progress';
    try {
      final r = await _api.verifyOtp(_pendingEmail!, code);
      await _onAuthed(r);
      _pendingEmail = null;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Is it running?';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final r = await _api.login(email, password);
      await _onAuthed(r);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Is it running?';
    }
  }

  Future<void> _onAuthed(Map<String, dynamic> r) async {
    _token = r['token'] as String?;
    _isAdmin = r['isAdmin'] == true;
    final u = (r['user'] as Map?)?.cast<String, dynamic>();
    _userName = u?['name'] as String?;
    _userEmail = u?['email'] as String?;
    await _persistSession();
    // Admins have no user profile/predictions to load — skip the normal refresh.
    if (!_isAdmin) await _refreshAll();
    notifyListeners();
  }

  void cancelOtp() {
    _pendingEmail = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _isAdmin = false;
    _userName = null;
    _userEmail = null;
    _stats = CompeteStats.empty();
    _matchPreds.clear();
    _matchReviews.clear();
    _tourn = TournamentPrediction();
    _boards.clear();
    await _persistSession();
    notifyListeners();
  }

  // ---- admin --------------------------------------------------------------

  /// Every fixture with its current admin-confirmed result. Throws on network
  /// error so the panel can show a retry state.
  Future<List<Map<String, dynamic>>> adminResults() async {
    if (_token == null) return const [];
    final list = await _api.adminResults(_token!);
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Records (or overwrites) the real result for a match. Returns an error
  /// message or null on success.
  Future<String?> setMatchResult(
      String matchId, Map<String, dynamic> result) async {
    if (_token == null) return 'Not signed in';
    try {
      await _api.setMatchResult(_token!, matchId, result);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server';
    }
  }

  Future<String?> clearMatchResult(String matchId) async {
    if (_token == null) return 'Not signed in';
    try {
      await _api.clearMatchResult(_token!, matchId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server';
    }
  }

  // ---- data refresh -------------------------------------------------------

  Future<void> refresh() => _refreshAll();

  Future<void> _refreshAll() async {
    if (_token == null || _isAdmin) return;
    try {
      final me = await _api.me(_token!);
      _stats = CompeteStats.fromJson(
          (me['stats'] as Map).cast<String, dynamic>());
      final u = (me['user'] as Map?)?.cast<String, dynamic>();
      if (u != null) {
        _userName = u['name'] as String?;
        _userEmail = u['email'] as String? ?? _userEmail;
      }

      final preds = await _api.predictions(_token!);
      _parsePredictions(preds);

      for (final p in LbPeriod.values) {
        final entries = await _api.leaderboard(p.name, token: _token!);
        _boards[p] = entries
            .map((e) =>
                LeaderboardEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
      _online = true;
    } on ApiException catch (e) {
      if (e.status == 401) {
        // token no longer valid
        await logout();
      }
      _online = false;
    } catch (_) {
      _online = false;
    }
    notifyListeners();
  }

  void _parsePredictions(Map<String, dynamic> data) {
    _matchPreds.clear();
    final match = (data['match'] as Map?)?.cast<String, dynamic>() ?? {};
    match.forEach((id, raw) {
      final m = (raw as Map).cast<String, dynamic>();
      _matchPreds[id] = MatchPrediction(matchId: id)
        ..winner = _outcome(m['winner'])
        ..homeScore = m['homeScore']
        ..awayScore = m['awayScore']
        ..firstScorerSide = m['firstScorerSide']
        ..overUnder = m['overUnder']
        ..btts = m['btts']
        ..penalties = m['penalties'];
    });
    _matchReviews
      ..clear()
      ..addAll(((data['results'] as Map?) ?? const {}).map(
          (k, v) => MapEntry('$k', (v as Map).cast<String, dynamic>())));
    final t = (data['tournament'] as Map?)?.cast<String, dynamic>() ?? {};
    _tourn = TournamentPrediction()
      ..winnerTeamId = t['winnerTeamId']
      ..runnerUpTeamId = t['runnerUpTeamId']
      ..goldenBootTeamId = t['goldenBootTeamId']
      ..goldenGloveTeamId = t['goldenGloveTeamId'];
  }

  Outcome? _outcome(dynamic v) => v == 'home'
      ? Outcome.home
      : v == 'draw'
          ? Outcome.draw
          : v == 'away'
              ? Outcome.away
              : null;

  // ---- predictions --------------------------------------------------------

  MatchPrediction predictionFor(String matchId) {
    final p = _matchPreds[matchId];
    if (p == null) return MatchPrediction(matchId: matchId);
    return MatchPrediction(matchId: matchId)
      ..winner = p.winner
      ..homeScore = p.homeScore
      ..awayScore = p.awayScore
      ..firstScorerSide = p.firstScorerSide
      ..overUnder = p.overUnder
      ..btts = p.btts
      ..penalties = p.penalties;
  }

  bool hasPrediction(String matchId) {
    final p = _matchPreds[matchId];
    return p != null && !p.isEmpty;
  }

  /// Match ids the user has actually predicted (for the My Predictions list).
  List<String> get predictedMatchIds => _matchPreds.entries
      .where((e) => !e.value.isEmpty)
      .map((e) => e.key)
      .toList();

  /// Saves a match prediction. Returns an error message or null on success.
  Future<String?> savePrediction(MatchPrediction p) async {
    if (_token == null) return 'Please log in';
    // Exact-score market: once either side is entered, a blank box counts as 0
    // (e.g. 4-? saves as 4-0). An untouched score stays unset. Mirrors the
    // server so the cached prediction matches what gets stored.
    final hasScore = p.homeScore != null || p.awayScore != null;
    final homeScore = hasScore ? (p.homeScore ?? 0) : null;
    final awayScore = hasScore ? (p.awayScore ?? 0) : null;
    try {
      await _api.putMatchPrediction(_token!, p.matchId, {
        'winner': _outcomeStr(p.winner),
        'homeScore': homeScore,
        'awayScore': awayScore,
        'firstScorerSide': p.firstScorerSide,
        'overUnder': p.overUnder,
        'btts': p.btts,
        'penalties': p.penalties,
      });
      _matchPreds[p.matchId] = predictionFor(p.matchId)
        ..winner = p.winner
        ..homeScore = homeScore
        ..awayScore = awayScore
        ..firstScorerSide = p.firstScorerSide
        ..overUnder = p.overUnder
        ..btts = p.btts
        ..penalties = p.penalties;
      notifyListeners();
      unawaited(_refreshAll());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server';
    }
  }

  Future<String?> saveTournament(TournamentPrediction t) async {
    if (_token == null) return 'Please log in';
    try {
      await _api.putTournament(_token!, {
        'winnerTeamId': t.winnerTeamId,
        'runnerUpTeamId': t.runnerUpTeamId,
        'goldenBootTeamId': t.goldenBootTeamId,
        'goldenGloveTeamId': t.goldenGloveTeamId,
      });
      _tourn = t;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server';
    }
  }

  String? _outcomeStr(Outcome? o) => o == Outcome.home
      ? 'home'
      : o == Outcome.draw
          ? 'draw'
          : o == Outcome.away
              ? 'away'
              : null;

  // ---- reads for the UI ---------------------------------------------------

  CompeteStats compute() => _stats;

  List<LeaderboardEntry> leaderboard(LbPeriod period) =>
      _boards[period] ?? const [];

  /// In-app notifications (deadlines from local fixtures + achievements + rank).
  List<AppNotification> notifications(
      List<FootballMatch> matches, DateTime now) {
    final out = <AppNotification>[];
    final soon = matches.where((m) {
      if (m.home == null || m.away == null) return false;
      if (m.statusAt(now) != MatchStatus.upcoming) return false;
      final d = m.kickoff.difference(now);
      return d.inHours >= 0 && d.inHours < 24 && !hasPrediction(m.id);
    }).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    for (final m in soon.take(5)) {
      out.add(AppNotification(
        title: 'Prediction deadline soon',
        body:
            '${m.home!.name} v ${m.away!.name} locks at kick-off — get your pick in!',
        icon: Icons.timer,
        kind: 'deadline',
      ));
    }
    if (loggedIn) {
      for (final id in _stats.badges) {
        final b = allBadges.firstWhere((x) => x.id == id,
            orElse: () => allBadges.first);
        out.add(AppNotification(
            title: 'Achievement unlocked',
            body: '${b.name} — ${b.description}',
            icon: b.icon,
            kind: 'achievement'));
      }
      if (_stats.totalPlayers > 0) {
        out.add(AppNotification(
          title: 'Leaderboard position',
          body:
              'You are ranked #${_stats.rank} of ${_stats.totalPlayers} predictors.',
          icon: Icons.leaderboard,
          kind: 'rank',
        ));
      }
    }
    return out;
  }

  static const List<AchievementBadge> allBadges = [
    AchievementBadge(id: 'first', name: 'First Steps', description: 'Make your first prediction', icon: Icons.flag),
    AchievementBadge(id: 'five', name: 'Getting Serious', description: 'Make 5 predictions', icon: Icons.checklist),
    AchievementBadge(id: 'correct1', name: 'On the Board', description: 'Get a prediction right', icon: Icons.check_circle),
    AchievementBadge(id: 'exact', name: 'Crystal Ball', description: 'Nail an exact score', icon: Icons.gps_fixed),
    AchievementBadge(id: 'streak3', name: 'On Fire', description: 'A 3-prediction streak', icon: Icons.local_fire_department),
    AchievementBadge(id: 'streak5', name: 'Unstoppable', description: 'A 5-prediction streak', icon: Icons.bolt),
    AchievementBadge(id: 'p100', name: 'Centurion', description: 'Reach 100 points', icon: Icons.military_tech),
    AchievementBadge(id: 'lvl5', name: 'Rising Star', description: 'Reach level 5', icon: Icons.star),
  ];

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}
