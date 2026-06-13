// App-side integration test: drives the real CompeteApi HTTP client against a
// LIVE backend running on http://localhost:8787.
// Run the server first (cd server && PORT=8787 dart run bin/server.dart), then:
//   flutter test test/live_integration.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:fifa_world_cup_2026/data/services/compete_api.dart';

void main() {
  final api = CompeteApi(base: 'http://localhost:8787');
  final email = 'itest_${DateTime.now().millisecondsSinceEpoch}@gv.app';
  late String token;

  test('register -> otp -> login through the app client', () async {
    await api.register('Integration Test', 'E1', email, 'pass1', 'pass1');
    final v = await api.verifyOtp(email, '123456');
    expect(v['token'], isNotNull);
    expect(v['user']['name'], 'Integration Test');
    token = v['token'] as String;

    final l = await api.login(email, 'pass1');
    expect(l['token'], isNotNull);
  });

  test('wrong OTP and wrong password are rejected', () async {
    final email2 = 'itest2_${DateTime.now().millisecondsSinceEpoch}@gv.app';
    await api.register('Other', 'E2', email2, 'pass1', 'pass1');
    expect(() => api.verifyOtp(email2, '000000'),
        throwsA(isA<ApiException>()));
    expect(() => api.login(email2, 'nope'), throwsA(isA<ApiException>()));
  });

  test('save + read a match prediction (upcoming match)', () async {
    // m72 is the last group match (late June) — still upcoming on the real
    // clock, so it is not locked.
    await api.putMatchPrediction(token, 'm72', {
      'winner': 'home',
      'homeScore': 1,
      'awayScore': 0,
      'firstScorerSide': 'home',
      'motmSide': 'home',
      'redCard': false,
    });
    final p = await api.predictions(token);
    final match = (p['match'] as Map).cast<String, dynamic>();
    expect(match['m72'], isNotNull);
    expect(match['m72']['winner'], 'home');
    expect(match['m72']['homeScore'], 1);
  });

  test('tournament prediction round-trips', () async {
    await api.putTournament(token, {
      'winnerTeamId': 'arg',
      'runnerUpTeamId': 'fra',
      'goldenBootTeamId': 'bra',
      'goldenGloveTeamId': 'esp',
    });
    final p = await api.predictions(token);
    final t = (p['tournament'] as Map).cast<String, dynamic>();
    expect(t['winnerTeamId'], 'arg');
    expect(t['runnerUpTeamId'], 'fra');
  });

  test('stats + leaderboard come back', () async {
    final me = await api.me(token);
    expect(me['stats'], isNotNull);
    expect(me['stats']['xp'], greaterThanOrEqualTo(10));

    final lb = await api.leaderboard('global', token: token);
    expect(lb, isNotEmpty);
    expect(lb.any((e) => e['isMe'] == true), isTrue);
  });
}
