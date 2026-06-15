import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'fixtures.dart';
import 'scoring.dart';
import 'store.dart';
import 'tournament_result.dart';
import 'util.dart';

/// All GoalVerse competition endpoints.
class GoalVerseApi {
  GoalVerseApi(this.store, this.fixtures,
      {DateTime Function()? clock,
      TournamentResult Function()? tournamentResult})
      : scoring =
            Scoring(fixtures, store, tournamentResult: tournamentResult),
        _clock = clock ?? DateTime.now {
    // The admin is a permanent, hashed DB row — seeded on every start so it
    // survives a wipe and can never be deleted. The email stays reserved and
    // the row is hidden from the players list / leaderboard.
    store.ensureAdmin(adminEmail, adminPassword);
  }

  final Store store;
  final Fixtures fixtures;
  final Scoring scoring;
  final DateTime Function() _clock;

  static const demoOtp = '123456';

  /// Hardcoded admin account. The admin signs in on the SAME login screen with
  /// these credentials and is routed to the admin panel. Override via env vars
  /// for a real deployment.
  static final String adminEmail =
      (Platform.environment['GV_ADMIN_EMAIL'] ?? 'admin@gmail.com')
          .toLowerCase();
  static final String adminPassword =
      Platform.environment['GV_ADMIN_PASSWORD'] ?? 'Admin@123';

  // email -> pending registration {name, eid, email, pwHash, salt}
  final Map<String, Map<String, dynamic>> _pending = {};

  DateTime get _now => _clock().toUtc();

  Router get router {
    final r = Router();
    r.get('/health', (Request _) => jsonResponse({'ok': true}));
    r.post('/auth/register', _register);
    r.post('/auth/verify-otp', _verifyOtp);
    r.post('/auth/login', _login);
    r.get('/me', _me);
    r.get('/stats', _stats);
    r.get('/predictions', _getPredictions);
    r.put('/predictions/match/<id>', _putMatchPrediction);
    r.put('/predictions/tournament', _putTournament);
    r.get('/leaderboard', _leaderboard);
    r.get('/fixtures', _getFixtures);
    r.get('/tournament/result', _getTournamentResult);
    // Admin (bearer token must belong to the admin account).
    r.get('/admin/results', _adminResults);
    r.put('/admin/result/<id>', _setAdminResult);
    r.delete('/admin/result/<id>', _clearAdminResult);
    return r;
  }

  // ---- helpers ------------------------------------------------------------

  String? _authEmail(Request req) {
    final auth = req.headers['authorization'];
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    return store.emailForToken(auth.substring(7));
  }

  /// True only when the request's bearer token belongs to the admin account.
  /// Admin authority is enforced HERE on the server — never trusted from the
  /// client.
  bool _isAdmin(Request req) => _authEmail(req) == adminEmail;

  Map<String, dynamic> _publicUser(Map<String, dynamic> u) =>
      {'name': u['name'], 'email': u['email'], 'employeeId': u['eid']};

  // ---- auth ---------------------------------------------------------------

  Future<Response> _register(Request req) async {
    late Map<String, dynamic> b;
    try {
      b = await readJsonBody(req);
    } catch (_) {
      return jsonError('Invalid JSON body');
    }
    final name = '${b['name'] ?? ''}'.trim();
    final eid = '${b['employeeId'] ?? ''}'.trim();
    final email = '${b['email'] ?? ''}'.trim();
    final pw = '${b['password'] ?? ''}';
    final confirm = '${b['confirmPassword'] ?? ''}';

    if (name.length < 2) return jsonError('Please enter your full name');
    if (eid.isEmpty) return jsonError('Please enter your Employee ID');
    if (!isValidEmail(email)) return jsonError('Please enter a valid email');
    if (email.toLowerCase() == adminEmail) {
      return jsonError('This email is reserved');
    }
    if (pw.length < 4) {
      return jsonError('Password must be at least 4 characters');
    }
    if (pw != confirm) return jsonError('Passwords do not match');
    if (store.userExists(email)) {
      return jsonError('An account with that email already exists');
    }

    final salt = genSalt();
    _pending[email.toLowerCase()] = {
      'name': name,
      'eid': eid,
      'email': email,
      'salt': salt,
      'pwHash': hashPassword(pw, salt),
    };
    // In production an email with the OTP is sent here. Demo OTP: 123456.
    return jsonResponse({'status': 'otp_sent', 'email': email});
  }

  Future<Response> _verifyOtp(Request req) async {
    final b = await readJsonBody(req);
    final email = '${b['email'] ?? ''}'.trim().toLowerCase();
    final code = '${b['code'] ?? ''}'.trim();
    final pending = _pending[email];
    if (pending == null) return jsonError('No registration in progress');
    if (code != demoOtp) return jsonError('Incorrect OTP. Please try again.');
    pending['created'] = _now.toIso8601String();
    store.saveUser(pending);
    _pending.remove(email);
    final token = store.issueToken(genToken(), email);
    return jsonResponse({'token': token, 'user': _publicUser(pending)});
  }

  Future<Response> _login(Request req) async {
    final b = await readJsonBody(req);
    final email = '${b['email'] ?? ''}'.trim().toLowerCase();
    final pw = '${b['password'] ?? ''}';
    // Admin signs in here; the password is verified against the stored salted
    // hash (seeded by ensureAdmin, kept in sync with GV_ADMIN_PASSWORD).
    if (email == adminEmail) {
      final a = store.user(adminEmail);
      if (a == null ||
          hashPassword(pw, a['salt'] as String) != a['pwHash']) {
        return jsonError('Incorrect password', status: 401);
      }
      final token = store.issueToken(genToken(), adminEmail);
      return jsonResponse({
        'token': token,
        'user': {'name': 'Admin', 'email': adminEmail, 'employeeId': 'ADMIN'},
        'isAdmin': true,
      });
    }
    final u = store.user(email);
    if (u == null) return jsonError('No account with that email', status: 401);
    if (hashPassword(pw, u['salt'] as String) != u['pwHash']) {
      return jsonError('Incorrect password', status: 401);
    }
    final token = store.issueToken(genToken(), email);
    return jsonResponse(
        {'token': token, 'user': _publicUser(u), 'isAdmin': false});
  }

  Response _me(Request req) {
    final email = _authEmail(req);
    if (email == null) return jsonError('Unauthorized', status: 401);
    final u = store.user(email);
    if (u == null) return jsonError('Unauthorized', status: 401);
    return jsonResponse({
      'user': _publicUser(u),
      'stats': scoring.stats(email, _now),
    });
  }

  Response _stats(Request req) {
    final email = _authEmail(req);
    if (email == null) return jsonError('Unauthorized', status: 401);
    return jsonResponse(scoring.stats(email, _now));
  }

  // ---- predictions --------------------------------------------------------

  Response _getPredictions(Request req) {
    final email = _authEmail(req);
    if (email == null) return jsonError('Unauthorized', status: 401);
    final data = store.predsFor(email);
    // Attach the admin result + per-market correctness + points for predicted
    // matches that have been scored — read-only review for the user.
    final matchPreds = (data['match'] as Map?)?.cast<String, dynamic>() ?? {};
    final results = <String, dynamic>{};
    for (final id in matchPreds.keys) {
      final r = store.matchResult(id);
      if (r == null) continue;
      final hasResult = r['winner'] != null ||
          (r['homeScore'] != null && r['awayScore'] != null);
      if (!hasResult) continue;
      final p = (matchPreds[id] as Map).cast<String, dynamic>();
      results[id] = {
        'result': r,
        'points': gradeMatch(p, r),
        'markets': marketHits(p, r),
      };
    }
    data['results'] = results;
    return jsonResponse(data);
  }

  Future<Response> _putMatchPrediction(Request req, String id) async {
    final email = _authEmail(req);
    if (email == null) return jsonError('Unauthorized', status: 401);
    if (email == adminEmail) {
      return jsonError('Admin accounts cannot make predictions', status: 403);
    }
    final f = fixtures[id];
    if (f == null) return jsonError('Unknown match', status: 404);
    // Knockout slots start without teams in the schedule — the admin assigns
    // them via the result row. Teams are "known" if the static fixture has
    // them OR the admin has assigned them (mirrors the /fixtures overlay), so
    // knockout matches become predictable (incl. the penalties market) as soon
    // as the bracket is filled.
    final r = store.matchResult(id);
    final teamsKnown = f.hasTeams ||
        (r != null && r['homeTeamId'] != null && r['awayTeamId'] != null);
    if (!teamsKnown) {
      return jsonError('Teams not assigned yet', status: 404);
    }
    if (fixtures.isLocked(id, _now)) {
      return jsonError('Predictions are locked — the match has started',
          status: 409);
    }
    final b = await readJsonBody(req);
    // Exact-score market: once either side has been entered, treat a blank
    // box as 0 (e.g. 4-? saves as 4-0). An untouched score stays unset so a
    // winner-only pick isn't forced into a contradictory 0-0.
    var homeScore = _intOrNull(b['homeScore']);
    var awayScore = _intOrNull(b['awayScore']);
    if (homeScore != null || awayScore != null) {
      homeScore ??= 0;
      awayScore ??= 0;
    }
    final pred = <String, dynamic>{
      'winner': _oneOf(b['winner'], const ['home', 'draw', 'away']),
      'homeScore': homeScore,
      'awayScore': awayScore,
      'firstScorerSide':
          _oneOf(b['firstScorerSide'], const ['home', 'away', 'none']),
      'overUnder': _oneOf(b['overUnder'], const ['over', 'under']),
      'btts': b['btts'] is bool ? b['btts'] : null,
      'penalties': b['penalties'] is bool ? b['penalties'] : null,
    };
    final data = store.predsFor(email);
    final match = (data['match'] as Map?)?.cast<String, dynamic>() ?? {};
    match[id] = pred;
    data['match'] = match;
    store.savePredsFor(email, data);
    return jsonResponse({'ok': true, 'prediction': pred});
  }

  Future<Response> _putTournament(Request req) async {
    final email = _authEmail(req);
    if (email == null) return jsonError('Unauthorized', status: 401);
    if (email == adminEmail) {
      return jsonError('Admin accounts cannot make predictions', status: 403);
    }
    if (!_now.isBefore(fixtures.finalKickoff)) {
      return jsonError('Tournament predictions are closed', status: 409);
    }
    final b = await readJsonBody(req);
    final t = <String, dynamic>{
      'winnerTeamId': b['winnerTeamId'],
      'runnerUpTeamId': b['runnerUpTeamId'],
      'goldenBootTeamId': b['goldenBootTeamId'],
      'goldenGloveTeamId': b['goldenGloveTeamId'],
    };
    final data = store.predsFor(email);
    data['tournament'] = t;
    store.savePredsFor(email, data);
    return jsonResponse({'ok': true, 'tournament': t});
  }

  // ---- leaderboard / fixtures --------------------------------------------

  Response _leaderboard(Request req) {
    final periodStr = req.url.queryParameters['period'] ?? 'global';
    final period = Period.values.firstWhere((p) => p.name == periodStr,
        orElse: () => Period.global);
    final me = _authEmail(req);
    final board = scoring.leaderboard(period, _now);
    for (var i = 0; i < board.length; i++) {
      board[i]['rank'] = i + 1;
      board[i]['accuracy'] = board[i]['predictions'] == 0
          ? 0
          : (((board[i]['correct'] as int) /
                      (board[i]['predictions'] as int)) *
                  100)
              .round();
      board[i]['isMe'] = me != null && board[i]['email'] == me;
      board[i].remove('email');
    }
    return jsonResponse({'period': period.name, 'entries': board});
  }

  /// The schedule, with any admin-assigned knockout teams overlaid onto the
  /// placeholder slots so every client (and the predict flow) sees the bracket.
  Response _getFixtures(Request _) {
    final results = store.matchResults();
    final out = fixtures.all.map((f) {
      final mini = f.toMini();
      final r = results[f.id];
      if (r != null) {
        if (r['homeTeamId'] != null) mini['homeId'] = r['homeTeamId'];
        if (r['awayTeamId'] != null) mini['awayId'] = r['awayTeamId'];
        // Public once recorded — lets the app show results read-only for
        // matches the user didn't predict.
        final hasResult = r['winner'] != null ||
            (r['homeScore'] != null && r['awayScore'] != null);
        if (hasResult) mini['result'] = r;
      }
      return mini;
    }).toList();
    return jsonResponse({'fixtures': out});
  }

  /// The recorded tournament outcome, plus whether the Final has been played.
  /// `decided` is false until an admin records it with `bin/set_result.dart`.
  Response _getTournamentResult(Request _) {
    final res = scoring.tournamentResult;
    final live = res.decided && !fixtures.finalKickoff.isAfter(_now);
    return jsonResponse({
      'decided': res.decided,
      'graded': live,
      ...res.toJson(),
    });
  }

  // ---- admin (result entry — the ONLY source scoring grades against) -------

  /// Every fixture with its current admin-confirmed result (admin only).
  Response _adminResults(Request req) {
    if (!_isAdmin(req)) return jsonError('Forbidden', status: 403);
    final results = store.matchResults();
    final matches = fixtures.all
        .map((f) => {
              ...f.toMini(),
              'locked': fixtures.isLocked(f.id, _now),
              'result': results[f.id], // null until the admin sets it
            })
        .toList();
    return jsonResponse({'matches': matches});
  }

  Future<Response> _setAdminResult(Request req, String id) async {
    if (!_isAdmin(req)) return jsonError('Forbidden', status: 403);
    final f = fixtures[id];
    // Knockout matches have no teams in the schedule — the admin assigns them
    // here — so only require that the match exists.
    if (f == null) return jsonError('Unknown match', status: 404);
    final b = await readJsonBody(req);
    // Coerce a one-sided score to 0 (e.g. 4-? → 4-0) so a finished result is
    // never stored with a NULL side — that would break Exact / Over-Under / BTTS.
    var homeScore = _intOrNull(b['homeScore']);
    var awayScore = _intOrNull(b['awayScore']);
    if (homeScore != null || awayScore != null) {
      homeScore ??= 0;
      awayScore ??= 0;
    }
    // Over/Under 2.5 and Both Teams To Score are a pure function of the final
    // score — derive them once here so they're stored and graded uniformly.
    String? overUnder;
    bool? btts;
    if (homeScore != null && awayScore != null) {
      overUnder = (homeScore + awayScore) >= 3 ? 'over' : 'under';
      btts = homeScore > 0 && awayScore > 0;
    }
    store.saveMatchResult(id, {
      'homeTeamId': _str(b['homeTeamId']),
      'awayTeamId': _str(b['awayTeamId']),
      'winner': _oneOf(b['winner'], const ['home', 'draw', 'away']),
      'homeScore': homeScore,
      'awayScore': awayScore,
      'firstScorer': _oneOf(b['firstScorer'], const ['home', 'away', 'none']),
      'overUnder': overUnder,
      'btts': btts,
      'penalties': b['penalties'] is bool ? b['penalties'] : null,
    });
    return jsonResponse({'ok': true, 'id': id, 'result': store.matchResult(id)});
  }

  Future<Response> _clearAdminResult(Request req, String id) async {
    if (!_isAdmin(req)) return jsonError('Forbidden', status: 403);
    store.deleteMatchResult(id);
    return jsonResponse({'ok': true, 'id': id});
  }

  // ---- parsing ------------------------------------------------------------

  String? _oneOf(dynamic v, List<String> allowed) =>
      (v is String && allowed.contains(v)) ? v : null;

  String? _str(dynamic v) =>
      (v is String && v.trim().isNotEmpty) ? v.trim() : null;

  int? _intOrNull(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : null);
}
