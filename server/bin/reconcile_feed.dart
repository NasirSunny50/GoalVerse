// Reconciles the app's 104 fixtures (data/fixtures.json) against TheSportsDB's
// World Cup 2026 feed (league 4429) and reports which matchups the feed COVERS
// vs is MISSING/mismatched — so you know exactly where the admin must enter
// results for the display + group table to fill in.
//
//   cd server && dart run bin/reconcile_feed.dart
//
// Rate-limit aware: each day is fetched once with a delay and cached to
// data/.feed_cache/<date>.json, so reruns are instant and don't hit 429s.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _base = 'https://www.thesportsdb.com/api/v1/json/3';
const _league = '4429';

String _canon(String name) {
  var s = name.toLowerCase();
  const accents = {
    'ç': 'c', 'ü': 'u', 'é': 'e', 'è': 'e', 'í': 'i', 'á': 'a', 'ó': 'o',
    'ñ': 'n', 'ã': 'a', 'â': 'a', 'ô': 'o', 'ı': 'i', 'ş': 's', 'ğ': 'g',
    'ø': 'o', 'å': 'a', 'ä': 'a', 'ö': 'o',
  };
  accents.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp('[^a-z0-9]'), '');
  const alias = {
    'czechrepublic': 'czechia',
    'korearepublic': 'southkorea',
    'republicofkorea': 'southkorea',
    'unitedstates': 'usa',
    'turkiye': 'turkey',
    'turkey': 'turkey',
    'bosniaherzegovina': 'bosniaandherzegovina',
    'capeverde': 'capeverde',
  };
  return alias[s] ?? s;
}

String _key(String a, String b) => ([_canon(a), _canon(b)]..sort()).join('|');

Future<void> main() async {
  final fxFile = File('data/fixtures.json').existsSync()
      ? File('data/fixtures.json')
      : File('server/data/fixtures.json');
  final fixtures = (jsonDecode(fxFile.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  // App fixtures that actually have both team names (knockout slots are blank).
  final appNamed = fixtures
      .where((f) => f['homeName'] != null && f['awayName'] != null)
      .toList();

  // Tournament window (a little padding around 11 Jun – 19 Jul 2026).
  final start = DateTime.utc(2026, 6, 10);
  final end = DateTime.utc(2026, 7, 20);
  final cacheDir = Directory('${fxFile.parent.path}/.feed_cache')
    ..createSync(recursive: true);
  final client = http.Client();

  // feed key -> "Home v Away (date) status score"
  final feedByKey = <String, String>{};
  var feedCount = 0, fetched = 0, cached = 0;
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    final ds = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final cacheFile = File('${cacheDir.path}/$ds.json');
    String body;
    if (cacheFile.existsSync()) {
      body = cacheFile.readAsStringSync();
      cached++;
    } else {
      body = await _fetchDay(client, ds);
      cacheFile.writeAsStringSync(body);
      fetched++;
      await Future.delayed(const Duration(milliseconds: 1600)); // be gentle
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final events = json['events'];
    if (events is! List) continue;
    for (final e in events) {
      if (e is! Map) continue;
      final h = '${e['strHomeTeam'] ?? ''}', a = '${e['strAwayTeam'] ?? ''}';
      if (h.isEmpty || a.isEmpty) continue;
      feedCount++;
      final sc = (e['intHomeScore'] != null && e['intAwayScore'] != null)
          ? ' ${e['intHomeScore']}-${e['intAwayScore']}'
          : '';
      feedByKey[_key(h, a)] =
          '$h v $a  (${e['dateEvent']})  ${e['strStatus']}$sc';
    }
  }
  client.close();

  final covered = <Map<String, dynamic>>[];
  final missing = <Map<String, dynamic>>[];
  for (final f in appNamed) {
    final k = _key('${f['homeName']}', '${f['awayName']}');
    (feedByKey.containsKey(k) ? covered : missing).add(f);
  }

  // Feed events that don't map to any app fixture.
  final appKeys = appNamed
      .map((f) => _key('${f['homeName']}', '${f['awayName']}'))
      .toSet();
  final feedOnly = feedByKey.entries
      .where((e) => !appKeys.contains(e.key))
      .map((e) => e.value)
      .toList()
    ..sort();

  final out = StringBuffer();
  out.writeln('FEED RECONCILIATION — app fixtures vs TheSportsDB (league $_league)');
  out.writeln('days: $fetched fetched, $cached cached | feed events seen: $feedCount');
  out.writeln('app fixtures with named teams: ${appNamed.length} '
      '(of ${fixtures.length} total)');
  out.writeln('  COVERED by feed : ${covered.length}');
  out.writeln('  MISSING in feed : ${missing.length}');
  out.writeln('');
  out.writeln('--- MISSING (admin must enter results for these) ---');
  for (final f in missing) {
    out.writeln('  ${f['id']}  ${f['homeName']} v ${f['awayName']}  '
        '(${f['stage']}, kickoff ${f['kickoff']})');
  }
  out.writeln('');
  out.writeln('--- FEED-ONLY events (in TheSportsDB, no matching app fixture) ---');
  for (final s in feedOnly) {
    out.writeln('  $s');
  }

  final report = File('${fxFile.parent.path}/feed_reconciliation.txt');
  report.writeAsStringSync(out.toString());
  stdout.write(out.toString());
  stdout.writeln('\nReport written to ${report.path}');
}

Future<String> _fetchDay(http.Client c, String ds) async {
  final uri = Uri.parse('$_base/eventsday.php?d=$ds&l=$_league');
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      final r = await c.get(uri).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return r.body;
      if (r.statusCode == 429) {
        stderr.writeln('  429 for $ds — backing off ${(attempt + 1) * 4}s');
        await Future.delayed(Duration(seconds: (attempt + 1) * 4));
        continue;
      }
      return '{"events":null}';
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }
  return '{"events":null}'; // give up for this day; rerun fills it from cache
}
