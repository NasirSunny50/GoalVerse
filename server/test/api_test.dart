import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:goalverse_server/api.dart';
import 'package:goalverse_server/fixtures.dart';
import 'package:goalverse_server/scoring.dart';
import 'package:goalverse_server/store.dart';
import 'package:goalverse_server/tournament_result.dart';
import 'package:goalverse_server/util.dart';

late Fixtures fixtures;

GoalVerseApi makeApi({DateTime? now, TournamentResult Function()? tournamentResult}) {
  final tmp = '${Directory.systemTemp.path}/gv_test_${DateTime.now().microsecondsSinceEpoch}_${now.hashCode}.json';
  final store = Store(tmp);
  return GoalVerseApi(store, fixtures,
      clock: () => now ?? DateTime.utc(2026, 6, 1),
      tournamentResult: tournamentResult);
}

Future<Map<String, dynamic>> call(GoalVerseApi api, String method, String path,
    {Map<String, dynamic>? body, String? token}) async {
  final headers = <String, String>{'content-type': 'application/json'};
  if (token != null) headers['authorization'] = 'Bearer $token';
  final req = Request(method, Uri.parse('http://localhost$path'),
      headers: headers, body: body == null ? null : jsonEncode(body));
  final res = await api.router.call(req);
  final text = await res.readAsString();
  final json = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
  return {'status': res.statusCode, 'body': json};
}

Future<String> registerAndLogin(GoalVerseApi api, String email) async {
  await call(api, 'POST', '/auth/register', body: {
    'name': 'Test User',
    'employeeId': 'EMP1',
    'email': email,
    'password': 'pass1',
    'confirmPassword': 'pass1',
  });
  final v = await call(api, 'POST', '/auth/verify-otp',
      body: {'email': email, 'code': GoalVerseApi.demoOtp});
  return v['body']['token'] as String;
}

void main() {
  setUpAll(() {
    final path = File('data/fixtures.json').existsSync()
        ? 'data/fixtures.json'
        : 'server/data/fixtures.json';
    fixtures = Fixtures.load(path);
  });

  test('health', () async {
    final r = await call(makeApi(), 'GET', '/health');
    expect(r['status'], 200);
    expect(r['body']['ok'], true);
  });

  test('register requires valid fields', () async {
    final api = makeApi();
    final r = await call(api, 'POST', '/auth/register', body: {
      'name': 'A',
      'employeeId': '',
      'email': 'bad',
      'password': 'x',
      'confirmPassword': 'y',
    });
    expect(r['status'], 400);
    expect(r['body']['error'], isNotNull);
  });

  test('register -> otp -> login flow', () async {
    final api = makeApi();
    final reg = await call(api, 'POST', '/auth/register', body: {
      'name': 'Nasir',
      'employeeId': 'EMP9',
      'email': 'nasir@goalverse.app',
      'password': 'pass1',
      'confirmPassword': 'pass1',
    });
    expect(reg['status'], 200);
    expect(reg['body']['status'], 'otp_sent');

    final bad = await call(api, 'POST', '/auth/verify-otp',
        body: {'email': 'nasir@goalverse.app', 'code': '000000'});
    expect(bad['status'], 400);

    final ok = await call(api, 'POST', '/auth/verify-otp',
        body: {'email': 'nasir@goalverse.app', 'code': GoalVerseApi.demoOtp});
    expect(ok['status'], 200);
    expect(ok['body']['token'], isNotNull);
    expect(ok['body']['user']['name'], 'Nasir');

    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'nasir@goalverse.app', 'password': 'pass1'});
    expect(login['status'], 200);
    expect(login['body']['token'], isNotNull);

    final wrong = await call(api, 'POST', '/auth/login',
        body: {'email': 'nasir@goalverse.app', 'password': 'nope'});
    expect(wrong['status'], 401);
  });

  test('duplicate email rejected', () async {
    final api = makeApi();
    await registerAndLogin(api, 'dup@goalverse.app');
    final r = await call(api, 'POST', '/auth/register', body: {
      'name': 'Other',
      'employeeId': 'E2',
      'email': 'dup@goalverse.app',
      'password': 'pass1',
      'confirmPassword': 'pass1',
    });
    expect(r['status'], 400);
  });

  test('unauthorized without token', () async {
    final r = await call(makeApi(), 'GET', '/predictions');
    expect(r['status'], 401);
  });

  test('save match prediction when open, reject when locked', () async {
    // Early clock: group matches are still upcoming → open.
    final api = makeApi(now: DateTime.utc(2026, 6, 11, 0));
    final token = await registerAndLogin(api, 'pred@goalverse.app');
    final open = await call(api, 'PUT', '/predictions/match/m1',
        body: {'winner': 'home', 'homeScore': 2, 'awayScore': 0},
        token: token);
    expect(open['status'], 200, reason: 'm1 not yet started at this clock');

    // Late clock: m1 already kicked off → locked.
    final apiLate = makeApi(now: DateTime.utc(2026, 7, 1));
    final token2 = await registerAndLogin(apiLate, 'pred2@goalverse.app');
    final locked = await call(apiLate, 'PUT', '/predictions/match/m1',
        body: {'winner': 'home'}, token: token2);
    expect(locked['status'], 409);
  });

  test('blank score box counts as 0 once one side is entered', () async {
    final api = makeApi(now: DateTime.utc(2026, 6, 11, 0));
    final token = await registerAndLogin(api, 'score@goalverse.app');

    // Half-filled exact score: home set, away left blank -> away becomes 0.
    final half = await call(api, 'PUT', '/predictions/match/m1',
        body: {'winner': 'home', 'homeScore': 4}, token: token);
    expect(half['status'], 200);
    expect(half['body']['prediction']['homeScore'], 4);
    expect(half['body']['prediction']['awayScore'], 0);

    // Winner-only pick, score untouched -> stays unset (not forced to 0-0).
    final winnerOnly = await call(api, 'PUT', '/predictions/match/m2',
        body: {'winner': 'home'}, token: token);
    expect(winnerOnly['status'], 200);
    expect(winnerOnly['body']['prediction']['homeScore'], isNull);
    expect(winnerOnly['body']['prediction']['awayScore'], isNull);
  });

  test('correct prediction earns points once admin records the result',
      () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final token = await registerAndLogin(api, 'scorer@goalverse.app');
    await _seedPrediction(api, token, 'm1', {
      'winner': 'home',
      'homeScore': 3,
      'awayScore': 1,
    });

    // Before the admin records the result → nothing is scored.
    final before = await call(api, 'GET', '/stats', token: token);
    expect(before['body']['points'], 0);
    expect(before['body']['predictions'], 0);

    // Admin records the real result → the prediction now grades.
    api.store.saveMatchResult('m1', {
      'winner': 'home',
      'homeScore': 3,
      'awayScore': 1,
    });
    final after = await call(api, 'GET', '/stats', token: token);
    expect(after['body']['points'], greaterThanOrEqualTo(25));
    expect(after['body']['predictions'], greaterThanOrEqualTo(1));

    final lb =
        await call(api, 'GET', '/leaderboard?period=allTime', token: token);
    expect(lb['status'], 200);
    final entries = lb['body']['entries'] as List;
    expect(entries.any((e) => e['isMe'] == true), true);
  });

  test('all markets via admin API: coercion + derive + grade = 63', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    // Admin enters ONLY the home score (away omitted). Server must coerce
    // away→0 and derive Over/Under + BTTS from the final 2-0.
    final set = await call(api, 'PUT', '/admin/result/m1', body: {
      'winner': 'home',
      'homeScore': 2,
      'firstScorer': 'home',
    }, token: adminToken);
    expect(set['body']['result']['awayScore'], 0, reason: 'away coerced to 0');
    expect(set['body']['result']['overUnder'], 'under'); // total 2
    expect(set['body']['result']['btts'], false); // away 0 → no

    final token = await registerAndLogin(api, 'markets@goalverse.app');
    await _seedPrediction(api, token, 'm1', {
      'winner': 'home',
      'homeScore': 2,
      'awayScore': 0,
      'firstScorerSide': 'home',
      'overUnder': 'under',
      'btts': false,
    });
    final s = await call(api, 'GET', '/stats', token: token);
    // winner(10) + exact(25) + first(12) + over/under(8) + btts(8) = 63.
    expect(s['body']['points'], 63);
  });

  test('every wrong pick scores nothing', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    // Result 3-1 home → over, btts yes, first home.
    await call(api, 'PUT', '/admin/result/m1', body: {
      'winner': 'home',
      'homeScore': 3,
      'awayScore': 1,
      'firstScorer': 'home',
    }, token: adminToken);
    final token = await registerAndLogin(api, 'wrong@goalverse.app');
    await _seedPrediction(api, token, 'm1', {
      'winner': 'away',
      'homeScore': 0,
      'awayScore': 2,
      'firstScorerSide': 'away',
      'overUnder': 'under',
      'btts': false,
    });
    final s = await call(api, 'GET', '/stats', token: token);
    expect(s['body']['points'], 0);
    expect(s['body']['predictions'], 1);
  });

  test('GET /predictions returns per-match review once scored', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    await call(api, 'PUT', '/admin/result/m1', body: {
      'winner': 'home',
      'homeScore': 2,
      'awayScore': 0,
      'firstScorer': 'home',
    }, token: adminToken);
    final token = await registerAndLogin(api, 'review@goalverse.app');
    await _seedPrediction(api, token, 'm1', {
      'winner': 'home',
      'homeScore': 2,
      'awayScore': 1, // wrong exact
      'firstScorerSide': 'home',
      'overUnder': 'under',
      'btts': false,
    });
    final preds = await call(api, 'GET', '/predictions', token: token);
    final review = (preds['body']['results'] as Map)['m1'] as Map;
    final markets = (review['markets'] as Map);
    expect(markets['winner'], true);
    expect(markets['exact'], false);
    expect(markets['firstScorer'], true);
    expect(markets['overUnder'], true);
    expect(markets['btts'], true);
    // winner(10)+first(12)+over/under(8)+btts(8) = 38 (no exact).
    expect(review['points'], 38);
  });

  test('penalties market scores on a knockout admin result', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final ko = fixtures.all.firstWhere((f) => f.stage != 'groupStage');
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    await call(api, 'PUT', '/admin/result/${ko.id}', body: {
      'homeTeamId': 'arg',
      'awayTeamId': 'bra',
      'winner': 'home',
      'homeScore': 1,
      'awayScore': 1,
      'penalties': true,
    }, token: adminToken);
    final token = await registerAndLogin(api, 'pens@goalverse.app');
    await _seedPrediction(
        api, token, ko.id, {'winner': 'home', 'penalties': true});
    final s = await call(api, 'GET', '/stats', token: token);
    // winner(10) + penalties(10) = 20.
    expect(s['body']['points'], 20);
  });

  test('winner and exact score are additive, not exclusive', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    api.store.saveMatchResult(
        'm1', {'winner': 'home', 'homeScore': 2, 'awayScore': 1});

    // Right winner, wrong scoreline → winner only (10).
    final t1 = await registerAndLogin(api, 'wonly@goalverse.app');
    await _seedPrediction(
        api, t1, 'm1', {'winner': 'home', 'homeScore': 3, 'awayScore': 0});
    final s1 = await call(api, 'GET', '/stats', token: t1);
    expect(s1['body']['points'], 10);

    // Exact scoreline → winner + exact bonus (10 + 25 = 35).
    final t2 = await registerAndLogin(api, 'exact@goalverse.app');
    await _seedPrediction(
        api, t2, 'm1', {'winner': 'home', 'homeScore': 2, 'awayScore': 1});
    final s2 = await call(api, 'GET', '/stats', token: t2);
    expect(s2['body']['points'], 35);
  });

  test('admin login + admin-only result endpoints', () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));

    // Admin signs in on the normal login route with the hardcoded creds.
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    expect(login['status'], 200);
    expect(login['body']['isAdmin'], true);
    final adminToken = login['body']['token'] as String;

    // Wrong admin password is rejected.
    final bad = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'nope'});
    expect(bad['status'], 401);

    // A normal user cannot reach the admin endpoints.
    final userToken = await registerAndLogin(api, 'user@goalverse.app');
    final forbidden = await call(api, 'GET', '/admin/results', token: userToken);
    expect(forbidden['status'], 403);
    final forbiddenSet = await call(api, 'PUT', '/admin/result/m1',
        body: {'homeScore': 1, 'awayScore': 0}, token: userToken);
    expect(forbiddenSet['status'], 403);

    // Admin can list and set results.
    final list = await call(api, 'GET', '/admin/results', token: adminToken);
    expect(list['status'], 200);
    expect((list['body']['matches'] as List).length, 104);

    final set = await call(api, 'PUT', '/admin/result/m1',
        body: {'winner': 'home', 'homeScore': 2, 'awayScore': 1},
        token: adminToken);
    expect(set['status'], 200);
    expect(set['body']['result']['homeScore'], 2);

    final clear =
        await call(api, 'DELETE', '/admin/result/m1', token: adminToken);
    expect(clear['status'], 200);
  });

  test('admin email is reserved + admin cannot predict', () async {
    final api = makeApi();
    final reg = await call(api, 'POST', '/auth/register', body: {
      'name': 'Imposter',
      'employeeId': 'X',
      'email': 'admin@gmail.com',
      'password': 'pass1',
      'confirmPassword': 'pass1',
    });
    expect(reg['status'], 400);

    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    final pred = await call(api, 'PUT', '/predictions/match/m1',
        body: {'winner': 'home'}, token: adminToken);
    expect(pred['status'], 403);
  });

  test('admin is a permanent HASHED db row, hidden from players + leaderboard',
      () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));

    // Seeded as a real users-table row with a salted hash (never plaintext).
    final a = api.store.user('admin@gmail.com');
    expect(a, isNotNull);
    expect(a!['salt'], isNotNull);
    expect(a['pwHash'], isNotNull);
    expect(a['pwHash'], isNot('Admin@123'));
    expect(hashPassword('Admin@123', a['salt'] as String), a['pwHash'],
        reason: 'stored hash verifies the seeded password');

    // Hidden from the players list + count (so it never pollutes scoring).
    expect(api.store.allUsers().any((u) => u['email'] == 'admin@gmail.com'),
        isFalse);
    expect(api.store.userCount, 0);

    // Login verifies against the stored hash; wrong password rejected.
    final ok = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    expect(ok['status'], 200);
    expect(ok['body']['isAdmin'], true);
    final bad = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'wrong'});
    expect(bad['status'], 401);

    // A real player who scores appears on the leaderboard; the admin never does.
    final t = await registerAndLogin(api, 'lbplayer@goalverse.app');
    api.store.saveMatchResult(
        'm1', {'winner': 'home', 'homeScore': 2, 'awayScore': 1});
    await _seedPrediction(
        api, t, 'm1', {'winner': 'home', 'homeScore': 2, 'awayScore': 1});
    final lb =
        await call(api, 'GET', '/leaderboard?period=allTime', token: t);
    final entries = lb['body']['entries'] as List;
    expect(entries.any((e) => e['name'] == 'Admin'), isFalse,
        reason: 'admin must never show on the leaderboard');
    expect(entries.any((e) => e['isMe'] == true), isTrue);
  });

  test('admin cannot be lost: re-seeded + idempotent across restarts', () {
    final path = '${Directory.systemTemp.path}/'
        'gv_admin_${DateTime.now().microsecondsSinceEpoch}.json';

    // First "boot" seeds the admin; a second ensure is a no-op (no duplicate).
    final s1 = Store(path);
    s1.ensureAdmin('admin@gmail.com', 'Admin@123');
    s1.ensureAdmin('admin@gmail.com', 'Admin@123');
    final u1 = s1.user('admin@gmail.com');
    expect(u1, isNotNull);
    expect(hashPassword('Admin@123', u1!['salt'] as String), u1['pwHash']);
    expect(s1.userCount, 0); // hidden from the player count
    s1.close();

    // "Restart": reopening the same DB still has the admin, re-seed is safe.
    final s2 = Store(path);
    expect(s2.user('admin@gmail.com'), isNotNull,
        reason: 'admin persisted across restart');
    s2.ensureAdmin('admin@gmail.com', 'Admin@123');
    expect(s2.user('admin@gmail.com'), isNotNull);
    s2.close();
  });

  test('knockout: admin assigns teams + result, overlay + scoring work',
      () async {
    final api = makeApi(now: DateTime.utc(2026, 8, 1));
    final ko = fixtures.all.firstWhere((f) => f.stage != 'groupStage');
    expect(ko.homeId, isNull, reason: 'knockout slots start without teams');

    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;

    // Assign teams only (no result yet) → exposed via /fixtures, but unscored.
    await call(api, 'PUT', '/admin/result/${ko.id}',
        body: {'homeTeamId': 'arg', 'awayTeamId': 'fra'}, token: adminToken);
    final fx = await call(api, 'GET', '/fixtures');
    final row = (fx['body']['fixtures'] as List)
        .cast<Map>()
        .firstWhere((m) => m['id'] == ko.id);
    expect(row['homeId'], 'arg');
    expect(row['awayId'], 'fra');

    final token = await registerAndLogin(api, 'ko@goalverse.app');
    await _seedPrediction(api, token, ko.id,
        {'winner': 'home', 'homeScore': 2, 'awayScore': 1});
    final before = await call(api, 'GET', '/stats', token: token);
    expect(before['body']['points'], 0, reason: 'teams set but no result yet');

    // Now record the result → the side-based prediction scores.
    await call(api, 'PUT', '/admin/result/${ko.id}', body: {
      'homeTeamId': 'arg',
      'awayTeamId': 'fra',
      'winner': 'home',
      'homeScore': 2,
      'awayScore': 1,
    }, token: adminToken);
    final after = await call(api, 'GET', '/stats', token: token);
    expect(after['body']['points'], greaterThanOrEqualTo(25));
  });

  test('knockout match is predictable THROUGH THE API once teams assigned',
      () async {
    // Regression: knockout fixtures have no teams in the schedule, so the
    // predict endpoint must accept them once the admin has assigned teams via
    // the result row — otherwise the whole knockout stage (and the penalties
    // market) is unreachable for real users.
    final api = makeApi(now: DateTime.utc(2026, 6, 1));
    final ko = fixtures.all.firstWhere((f) => f.stage != 'groupStage');
    final token = await registerAndLogin(api, 'koapi@goalverse.app');

    // Before teams are assigned -> 404.
    final pre = await call(api, 'PUT', '/predictions/match/${ko.id}',
        body: {'winner': 'home', 'penalties': true}, token: token);
    expect(pre['status'], 404, reason: 'no teams assigned yet');

    // Admin assigns teams (no result yet).
    final login = await call(api, 'POST', '/auth/login',
        body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
    final adminToken = login['body']['token'] as String;
    await call(api, 'PUT', '/admin/result/${ko.id}',
        body: {'homeTeamId': 'arg', 'awayTeamId': 'bra'}, token: adminToken);

    // Now the user CAN predict it through the API, penalties market included.
    final post = await call(api, 'PUT', '/predictions/match/${ko.id}',
        body: {'winner': 'home', 'homeScore': 1, 'awayScore': 1, 'penalties': true},
        token: token);
    expect(post['status'], 200, reason: 'predictable once teams assigned');

    // Admin records the knockout result -> penalties market scores end-to-end.
    await call(api, 'PUT', '/admin/result/${ko.id}', body: {
      'homeTeamId': 'arg',
      'awayTeamId': 'bra',
      'winner': 'home',
      'homeScore': 1,
      'awayScore': 1,
      'penalties': true,
    }, token: adminToken);
    final s = await call(api, 'GET', '/stats', token: token);
    // winner(10) + exact 1-1(25) + penalties(10) = 45.
    expect(s['body']['points'], 45, reason: 'winner+exact+penalties via API');
  });

  test('gradeTournament: per-market, only when decided', () {
    const res = TournamentResult(
        decided: true,
        champion: 'arg',
        runnerUp: 'fra',
        goldenBoot: 'arg',
        goldenGlove: 'fra');

    // All four correct.
    expect(
        gradeTournament({
          'winnerTeamId': 'arg',
          'runnerUpTeamId': 'fra',
          'goldenBootTeamId': 'arg',
          'goldenGloveTeamId': 'fra',
        }, res),
        Points.champion + Points.runnerUp + Points.goldenBoot +
            Points.goldenGlove);

    // Only champion correct (and case-insensitive id match).
    expect(
        gradeTournament({
          'winnerTeamId': 'ARG',
          'runnerUpTeamId': 'bra',
          'goldenBootTeamId': 'bra',
          'goldenGloveTeamId': null,
        }, res),
        Points.champion);

    // Undecided result never awards.
    expect(gradeTournament({'winnerTeamId': 'arg'}, TournamentResult.undecided),
        0);

    // No prediction at all.
    expect(gradeTournament(null, res), 0);
  });

  test('tournament points award only after the Final, once recorded', () async {
    const decided = TournamentResult(
        decided: true,
        champion: 'arg',
        runnerUp: 'fra',
        goldenBoot: 'arg',
        goldenGlove: 'fra');
    const pick = {
      'winnerTeamId': 'arg',
      'runnerUpTeamId': 'fra',
      'goldenBootTeamId': 'arg',
      'goldenGloveTeamId': 'fra',
    };
    const full = Points.champion +
        Points.runnerUp +
        Points.goldenBoot +
        Points.goldenGlove;

    // After the Final + recorded result → full tournament points.
    final after =
        makeApi(now: DateTime.utc(2026, 8, 1), tournamentResult: () => decided);
    final tokenA = await registerAndLogin(after, 'tour@goalverse.app');
    _seedTournament(after, 'tour@goalverse.app', pick);
    final sa = await call(after, 'GET', '/stats', token: tokenA);
    expect(sa['body']['tournamentPoints'], full);
    expect(sa['body']['points'], greaterThanOrEqualTo(full));

    // Same result, but the clock is before the Final → not yet awarded.
    final before = makeApi(
        now: DateTime.utc(2026, 6, 12), tournamentResult: () => decided);
    final tokenB = await registerAndLogin(before, 'tour2@goalverse.app');
    _seedTournament(before, 'tour2@goalverse.app', pick);
    final sb = await call(before, 'GET', '/stats', token: tokenB);
    expect(sb['body']['tournamentPoints'], 0);

    // After the Final but no result recorded → 0.
    final undecided = makeApi(now: DateTime.utc(2026, 8, 1));
    final tokenC = await registerAndLogin(undecided, 'tour3@goalverse.app');
    _seedTournament(undecided, 'tour3@goalverse.app', pick);
    final sc = await call(undecided, 'GET', '/stats', token: tokenC);
    expect(sc['body']['tournamentPoints'], 0);
  });

  test('GET /tournament/result reflects the recorded result', () async {
    final undecided = await call(makeApi(), 'GET', '/tournament/result');
    expect(undecided['status'], 200);
    expect(undecided['body']['decided'], false);

    const decided = TournamentResult(decided: true, champion: 'arg');
    final r = await call(
        makeApi(now: DateTime.utc(2026, 8, 1), tournamentResult: () => decided),
        'GET',
        '/tournament/result');
    expect(r['body']['decided'], true);
    expect(r['body']['champion'], 'arg');
    expect(r['body']['graded'], true);
  });

  test('tournament prediction locks at the final', () async {
    final apiOpen = makeApi(now: DateTime.utc(2026, 6, 12));
    final t1 = await registerAndLogin(apiOpen, 't1@goalverse.app');
    final open = await call(apiOpen, 'PUT', '/predictions/tournament',
        body: {'winnerTeamId': 'arg', 'runnerUpTeamId': 'fra'}, token: t1);
    expect(open['status'], 200);

    final apiClosed = makeApi(now: DateTime.utc(2026, 8, 1));
    final t2 = await registerAndLogin(apiClosed, 't2@goalverse.app');
    final closed = await call(apiClosed, 'PUT', '/predictions/tournament',
        body: {'winnerTeamId': 'arg'}, token: t2);
    expect(closed['status'], 409);
  });
}

Future<void> _seedPrediction(GoalVerseApi api, String token, String matchId,
    Map<String, dynamic> body) async {
  // Save directly via the store (bypasses the kick-off lock for scoring tests).
  final email = api.store.emailForToken(token)!;
  final data = api.store.predsFor(email);
  final match = (data['match'] as Map?)?.cast<String, dynamic>() ?? {};
  match[matchId] = {
    'winner': body['winner'],
    'homeScore': body['homeScore'],
    'awayScore': body['awayScore'],
    'firstScorerSide': body['firstScorerSide'],
    'overUnder': body['overUnder'],
    'btts': body['btts'],
    'penalties': body['penalties'],
  };
  data['match'] = match;
  api.store.savePredsFor(email, data);
}

void _seedTournament(
    GoalVerseApi api, String email, Map<String, dynamic> t) {
  final data = api.store.predsFor(email);
  data['tournament'] = Map<String, dynamic>.from(t);
  api.store.savePredsFor(email, data);
}
