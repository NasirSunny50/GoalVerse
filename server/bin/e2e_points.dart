// End-to-end test of the GoalVerse POINTS / scoring system against the LIVE
// backend (http://localhost:8787). Exercises every market plus happy, negative
// and corner cases through the real HTTP API + admin flow. Throwaway tool -
// safe to delete; resets nothing (caller restores the DB afterwards).
//
//   dart run bin/e2e_points.dart [baseUrl]
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

late String base;
int passed = 0, failed = 0;
final failures = <String>[];

void check(String name, bool cond, [String detail = '']) {
  if (cond) {
    passed++;
    stdout.writeln('  PASS  $name');
  } else {
    failed++;
    failures.add('$name  ${detail.isEmpty ? '' : '($detail)'}');
    stdout.writeln('  FAIL  $name   $detail');
  }
}

Map<String, String> _headers(String? token) => {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };

Future<(int, Map<String, dynamic>)> req(String method, String path,
    {Map<String, dynamic>? body, String? token}) async {
  final uri = Uri.parse('$base$path');
  final h = _headers(token);
  late http.Response r;
  switch (method) {
    case 'GET':
      r = await http.get(uri, headers: h);
    case 'POST':
      r = await http.post(uri, headers: h, body: jsonEncode(body));
    case 'PUT':
      r = await http.put(uri, headers: h, body: jsonEncode(body));
    case 'DELETE':
      r = await http.delete(uri, headers: h);
  }
  final j = r.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(r.body) as Map<String, dynamic>;
  return (r.statusCode, j);
}

String uniqEmail(String tag) =>
    'e2e_${tag}_${DateTime.now().microsecondsSinceEpoch}@goalverse.test';

Future<String> registerUser(String email) async {
  await req('POST', '/auth/register', body: {
    'name': 'E2E $email',
    'employeeId': 'E2E',
    'email': email,
    'password': 'pass1',
    'confirmPassword': 'pass1',
  });
  final (_, v) = await req('POST', '/auth/verify-otp',
      body: {'email': email, 'code': '123456'});
  return v['token'] as String;
}

Future<void> main(List<String> args) async {
  base = args.isNotEmpty ? args[0] : 'http://localhost:8787';
  stdout.writeln('E2E points test against $base\n');

  // ---- admin login --------------------------------------------------------
  final (alStatus, al) = await req('POST', '/auth/login',
      body: {'email': 'admin@gmail.com', 'password': 'Admin@123'});
  check('admin login 200 + isAdmin', alStatus == 200 && al['isAdmin'] == true,
      'status=$alStatus');
  final admin = al['token'] as String;

  // ---- fixtures: pick open group matches + a knockout slot ----------------
  final now = DateTime.now().toUtc();
  final (_, fx) = await req('GET', '/fixtures');
  final fixtures = (fx['fixtures'] as List).cast<Map<String, dynamic>>();
  bool isGroup(Map m) => m['stage'] == 'groupStage';
  bool open(Map m) =>
      DateTime.parse(m['kickoff'] as String).toUtc().isAfter(now);
  final openGroups = fixtures
      .where((m) => isGroup(m) && open(m) && m['homeId'] != null)
      .toList();
  final lockedGroup =
      fixtures.firstWhere((m) => isGroup(m) && !open(m), orElse: () => {});
  final ko = fixtures.firstWhere((m) => m['stage'] == 'roundOf32');
  stdout.writeln('open group matches available: ${openGroups.length}; '
      'knockout slot=${ko['id']}; lockedGroup=${lockedGroup['id']}\n');
  check('enough open group matches for test (>=8)', openGroups.length >= 8,
      'only ${openGroups.length}');
  String mk(int i) => openGroups[i]['id'] as String;

  // =========================================================================
  // 1) AUTH - negative cases
  // =========================================================================
  stdout.writeln('\n[1] Auth negative cases');
  final (s1, _) = await req('POST', '/auth/register', body: {
    'name': 'A',
    'employeeId': '',
    'email': 'bad',
    'password': 'x',
    'confirmPassword': 'y'
  });
  check('register invalid fields -> 400', s1 == 400, 'status=$s1');

  final (s2, _) = await req('POST', '/auth/register', body: {
    'name': 'Imposter',
    'employeeId': 'X',
    'email': 'admin@gmail.com',
    'password': 'pass1',
    'confirmPassword': 'pass1'
  });
  check('register reserved admin email -> 400', s2 == 400, 'status=$s2');

  final dupEmail = uniqEmail('dup');
  await registerUser(dupEmail);
  final (s3, _) = await req('POST', '/auth/register', body: {
    'name': 'Dup',
    'employeeId': 'D',
    'email': dupEmail,
    'password': 'pass1',
    'confirmPassword': 'pass1'
  });
  check('duplicate email -> 400', s3 == 400, 'status=$s3');

  final (s4, _) = await req('POST', '/auth/login',
      body: {'email': 'admin@gmail.com', 'password': 'nope'});
  check('admin wrong password -> 401', s4 == 401, 'status=$s4');

  final (s5, _) = await req('GET', '/predictions');
  check('unauthorized /predictions -> 401', s5 == 401, 'status=$s5');

  // =========================================================================
  // 2) PREDICTION GATING
  // =========================================================================
  stdout.writeln('\n[2] Prediction gating');
  final gateToken = await registerUser(uniqEmail('gate'));

  final (s6, _) = await req('GET', '/admin/results', token: gateToken);
  check('normal user hits /admin/results -> 403', s6 == 403, 'status=$s6');

  final (s7, _) = await req('PUT', '/admin/result/${mk(0)}',
      body: {'winner': 'home', 'homeScore': 1, 'awayScore': 0},
      token: gateToken);
  check('normal user sets admin result -> 403', s7 == 403, 'status=$s7');

  final (s8, _) = await req('PUT', '/predictions/match/${mk(0)}',
      body: {'winner': 'home', 'homeScore': 2, 'awayScore': 1}, token: gateToken);
  check('user predicts OPEN group match -> 200', s8 == 200, 'status=$s8');

  final (s9, _) = await req('PUT', '/predictions/match/m999999',
      body: {'winner': 'home'}, token: gateToken);
  check('user predicts unknown match -> 404', s9 == 404, 'status=$s9');

  if (lockedGroup.isNotEmpty) {
    final (s10, _) = await req(
        'PUT', '/predictions/match/${lockedGroup['id']}',
        body: {'winner': 'home'}, token: gateToken);
    check('user predicts LOCKED (kicked-off) match -> 409', s10 == 409,
        'status=$s10');
  }

  final (s11, _) = await req('PUT', '/predictions/match/${mk(0)}',
      body: {'winner': 'home'}, token: admin);
  check('admin account cannot predict -> 403', s11 == 403, 'status=$s11');

  // --- knockout predict flow (THE key functional question) ---
  final (sKoPre, _) = await req('PUT', '/predictions/match/${ko['id']}',
      body: {'winner': 'home'}, token: gateToken);
  stdout.writeln('  note: predict knockout BEFORE team assignment -> $sKoPre '
      '(expected 404, no teams yet)');

  // admin assigns teams to the knockout slot (no result yet)
  final (sAssign, _) = await req('PUT', '/admin/result/${ko['id']}',
      body: {'homeTeamId': 'arg', 'awayTeamId': 'bra'}, token: admin);
  check('admin assigns knockout teams -> 200', sAssign == 200, 'status=$sAssign');

  // verify the overlay exposes the teams via /fixtures
  final (_, fx2) = await req('GET', '/fixtures');
  final koRow = (fx2['fixtures'] as List)
      .cast<Map>()
      .firstWhere((m) => m['id'] == ko['id']);
  check('knockout teams overlaid on /fixtures', koRow['homeId'] == 'arg',
      'homeId=${koRow['homeId']}');

  // NOW try to predict the knockout match through the API
  final (sKoPost, koBody) = await req(
      'PUT', '/predictions/match/${ko['id']}',
      body: {'winner': 'home', 'penalties': true}, token: gateToken);
  check('user can predict knockout AFTER teams assigned -> 200', sKoPost == 200,
      'status=$sKoPost body=$koBody  <<< penalties market depends on this');

  // =========================================================================
  // 3) ADMIN RESULT: coercion + derived Over/Under & BTTS (corner cases)
  // =========================================================================
  stdout.writeln('\n[3] Coercion + derived Over/Under & BTTS');
  // one-sided score coerces to 0
  final (_, c1) = await req('PUT', '/admin/result/${mk(1)}',
      body: {'winner': 'home', 'homeScore': 2, 'firstScorer': 'home'},
      token: admin);
  final r1 = c1['result'] as Map;
  check('coerce one-sided 2 -> away 0', r1['awayScore'] == 0,
      'awayScore=${r1['awayScore']}');
  check('derive 2-0 total=2 -> under', r1['overUnder'] == 'under',
      'ou=${r1['overUnder']}');
  check('derive 2-0 -> btts false', r1['btts'] == false, 'btts=${r1['btts']}');

  // boundary: total exactly 3 -> over
  final (_, c2) = await req('PUT', '/admin/result/${mk(2)}',
      body: {'winner': 'home', 'homeScore': 2, 'awayScore': 1}, token: admin);
  check('derive 2-1 total=3 -> OVER (boundary)',
      (c2['result'] as Map)['overUnder'] == 'over');
  check('derive 2-1 -> btts true', (c2['result'] as Map)['btts'] == true);

  // total 2 -> under, btts true (1-1)
  final (_, c3) = await req('PUT', '/admin/result/${mk(3)}',
      body: {'winner': 'draw', 'homeScore': 1, 'awayScore': 1}, token: admin);
  check('derive 1-1 total=2 -> under', (c3['result'] as Map)['overUnder'] == 'under');
  check('derive 1-1 -> btts true', (c3['result'] as Map)['btts'] == true);

  // 0-0 -> under, btts false, first=none
  final (_, c4) = await req('PUT', '/admin/result/${mk(4)}',
      body: {'winner': 'draw', 'homeScore': 0, 'awayScore': 0, 'firstScorer': 'none'},
      token: admin);
  check('derive 0-0 -> under', (c4['result'] as Map)['overUnder'] == 'under');
  check('derive 0-0 -> btts false', (c4['result'] as Map)['btts'] == false);

  // =========================================================================
  // 4) SCORING MATH through the full API
  // =========================================================================
  stdout.writeln('\n[4] Scoring math (full API)');
  // PERFECT group prediction = 63. Use mk(5): result 2-1 home, first home.
  final scoreMatch = mk(5);
  final perfectTok = await registerUser(uniqEmail('perfect'));
  await req('PUT', '/predictions/match/$scoreMatch', body: {
    'winner': 'home',
    'homeScore': 2,
    'awayScore': 1,
    'firstScorerSide': 'home',
    'overUnder': 'over',
    'btts': true,
  }, token: perfectTok);
  await req('PUT', '/admin/result/$scoreMatch', body: {
    'winner': 'home',
    'homeScore': 2,
    'awayScore': 1,
    'firstScorer': 'home',
  }, token: admin);
  final (_, ps) = await req('GET', '/stats', token: perfectTok);
  check('perfect group prediction = 63', ps['points'] == 63,
      'points=${ps['points']}');
  check('perfect: predictions counted = 1', ps['predictions'] == 1,
      'pred=${ps['predictions']}');
  check('perfect: exact counted = 1', ps['exact'] == 1, 'exact=${ps['exact']}');

  // review screen: every market true + points 63
  final (_, pr) = await req('GET', '/predictions', token: perfectTok);
  final rev = ((pr['results'] as Map)[scoreMatch] as Map);
  final mkts = rev['markets'] as Map;
  check('review: winner hit', mkts['winner'] == true);
  check('review: exact hit', mkts['exact'] == true);
  check('review: firstScorer hit', mkts['firstScorer'] == true);
  check('review: overUnder hit', mkts['overUnder'] == true);
  check('review: btts hit', mkts['btts'] == true);
  check('review: points 63', rev['points'] == 63, 'pts=${rev['points']}');

  // WRONG everything -> 0 but counted
  final wrongMatch = mk(6);
  final wrongTok = await registerUser(uniqEmail('wrong'));
  await req('PUT', '/predictions/match/$wrongMatch', body: {
    'winner': 'away',
    'homeScore': 0,
    'awayScore': 3,
    'firstScorerSide': 'away',
    'overUnder': 'under',
    'btts': false,
  }, token: wrongTok);
  await req('PUT', '/admin/result/$wrongMatch', body: {
    'winner': 'home',
    'homeScore': 2,
    'awayScore': 1,
    'firstScorer': 'home',
  }, token: admin);
  final (_, ws) = await req('GET', '/stats', token: wrongTok);
  check('all-wrong prediction = 0 points', ws['points'] == 0,
      'points=${ws['points']}');
  check('all-wrong still counts as a prediction', ws['predictions'] == 1,
      'pred=${ws['predictions']}');

  // right winner, wrong scoreline -> 10 (winner only)
  final wonlyMatch = mk(7);
  final wonlyTok = await registerUser(uniqEmail('wonly'));
  await req('PUT', '/predictions/match/$wonlyMatch',
      body: {'winner': 'home', 'homeScore': 3, 'awayScore': 0}, token: wonlyTok);
  await req('PUT', '/admin/result/$wonlyMatch',
      body: {'winner': 'home', 'homeScore': 2, 'awayScore': 1}, token: admin);
  final (_, wos) = await req('GET', '/stats', token: wonlyTok);
  // Prediction picked ONLY winner + score (no Over/Under or BTTS chips), so
  // only those two markets are in play: winner hits (10), exact misses. The
  // result's derived O/U is irrelevant because the user never picked it.
  check('right winner, wrong score, no other chips -> winner only (10)',
      wos['points'] == 10, 'points=${wos['points']}');

  // =========================================================================
  // 5) RESULT LIFECYCLE: edit + clear recompute
  // =========================================================================
  stdout.writeln('\n[5] Result edit + clear recompute');
  final lifeMatch = mk(8);
  final lifeTok = await registerUser(uniqEmail('life'));
  await req('PUT', '/predictions/match/$lifeMatch',
      body: {'winner': 'home', 'homeScore': 1, 'awayScore': 0}, token: lifeTok);
  // admin sets home win 1-0 -> user exact -> winner10+exact25+OU(1-0 under==?) pred has no OU/btts -> 35
  await req('PUT', '/admin/result/$lifeMatch',
      body: {'winner': 'home', 'homeScore': 1, 'awayScore': 0}, token: admin);
  final (_, lf1) = await req('GET', '/stats', token: lifeTok);
  check('edit: initial correct result -> 35', lf1['points'] == 35,
      'points=${lf1['points']}');
  // admin EDITS result to away win 0-2 -> user now wrong -> 0
  await req('PUT', '/admin/result/$lifeMatch',
      body: {'winner': 'away', 'homeScore': 0, 'awayScore': 2}, token: admin);
  final (_, lf2) = await req('GET', '/stats', token: lifeTok);
  check('edit: flipped result -> recomputed to 0', lf2['points'] == 0,
      'points=${lf2['points']}');
  // admin CLEARS result -> match no longer scored
  final (sClr, _) = await req('DELETE', '/admin/result/$lifeMatch', token: admin);
  check('clear result -> 200', sClr == 200, 'status=$sClr');
  final (_, lf3) = await req('GET', '/stats', token: lifeTok);
  check('clear: points back to 0 and prediction uncounted',
      lf3['points'] == 0 && lf3['predictions'] == 0,
      'points=${lf3['points']} pred=${lf3['predictions']}');

  // =========================================================================
  // 6) TOURNAMENT prediction + leaderboard
  // =========================================================================
  stdout.writeln('\n[6] Tournament + leaderboard');
  final tourTok = await registerUser(uniqEmail('tour'));
  final (sTour, _) = await req('PUT', '/predictions/tournament', body: {
    'winnerTeamId': 'arg',
    'runnerUpTeamId': 'fra',
    'goldenBootTeamId': 'arg',
    'goldenGloveTeamId': 'fra',
  }, token: tourTok);
  check('tournament prediction saves (final not yet) -> 200', sTour == 200,
      'status=$sTour');
  final (_, tr) = await req('GET', '/tournament/result');
  check('tournament result undecided before set', tr['decided'] == false,
      'decided=${tr['decided']}');
  final (_, ts) = await req('GET', '/stats', token: tourTok);
  check('tournament points 0 until Final + recorded', ts['tournamentPoints'] == 0,
      'tp=${ts['tournamentPoints']}');

  final (sLb, lb) = await req('GET', '/leaderboard?period=allTime', token: perfectTok);
  final entries = (lb['entries'] as List).cast<Map<String, dynamic>>();
  check('leaderboard 200 + entries', sLb == 200 && entries.isNotEmpty);
  bool ranksOk = true, sortedOk = true;
  for (var i = 0; i < entries.length; i++) {
    if (entries[i]['rank'] != i + 1) ranksOk = false;
    if (i > 0 &&
        (entries[i - 1]['points'] as int) < (entries[i]['points'] as int)) {
      sortedOk = false;
    }
  }
  check('leaderboard ranks are 1..N in order', ranksOk);
  check('leaderboard sorted by points desc', sortedOk);
  check('leaderboard marks me (isMe)', entries.any((e) => e['isMe'] == true));
  check('leaderboard hides raw email', entries.every((e) => !e.containsKey('email')));

  // =========================================================================
  stdout.writeln('\n========================================');
  stdout.writeln('RESULT:  $passed passed, $failed failed');
  if (failures.isNotEmpty) {
    stdout.writeln('\nFailures:');
    for (final f in failures) {
      stdout.writeln('  - $f');
    }
  }
  exitCode = failed == 0 ? 0 : 1;
}
