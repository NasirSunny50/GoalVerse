// Exports the app's fixtures + deterministic results to server/data/fixtures.json
// so the backend scores against EXACTLY the same data the app generates.
// Regenerated on every `flutter test`, keeping app & server in sync.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fifa_world_cup_2026/data/repositories/fixtures_repository.dart';
import 'package:fifa_world_cup_2026/data/sim/match_engine.dart';

void main() {
  test('export fixtures for the GoalVerse backend', () {
    final repo = FixturesRepository(now: DateTime.utc(2026, 6, 1));
    final out = <Map<String, dynamic>>[];
    for (final m in repo.matches) {
      final hasTeams = m.home != null && m.away != null;
      int? fth, fta;
      bool? rc;
      if (hasTeams) {
        final r = MatchEngine.fullTime(m);
        fth = r.$1;
        fta = r.$2;
        rc = MatchEngine.hadRedCard(m);
      }
      out.add({
        'id': m.id,
        'number': m.matchNumber,
        'stage': m.stage.name,
        'group': m.group,
        'homeId': m.home?.id,
        'awayId': m.away?.id,
        'homeName': m.home?.name,
        'awayName': m.away?.name,
        'homeCode': m.home?.code,
        'awayCode': m.away?.code,
        'kickoff': m.kickoff.toUtc().toIso8601String(),
        'ftHome': fth,
        'ftAway': fta,
        'redCard': rc,
      });
    }
    Directory('server/data').createSync(recursive: true);
    File('server/data/fixtures.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
    expect(out.length, 104);
    expect(out.where((e) => e['homeId'] != null).length, 72);
  });
}
