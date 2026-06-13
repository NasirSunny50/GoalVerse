import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'package:goalverse_server/api.dart';
import 'package:goalverse_server/fixtures.dart';
import 'package:goalverse_server/store.dart';
import 'package:goalverse_server/tournament_result.dart';
import 'package:goalverse_server/util.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;

  final localData = File('data/fixtures.json').existsSync();
  final fixturesPath =
      localData ? 'data/fixtures.json' : 'server/data/fixtures.json';
  final storePath =
      localData ? 'data/goalverse.db' : 'server/data/goalverse.db';
  final resultPath = localData
      ? 'data/tournament_result.json'
      : 'server/data/tournament_result.json';

  final fixtures = Fixtures.load(fixturesPath);
  final store = Store(storePath);
  final api = GoalVerseApi(store, fixtures,
      tournamentResult: () => TournamentResult.loadFromFile(resultPath));

  // NOTE: Compete scoring is intentionally decoupled from any live feed —
  // results are entered by the admin only. No TheSportsDB polling here.

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(api.router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('GoalVerse backend listening on http://localhost:${server.port}');
  stdout.writeln('Fixtures: ${fixtures.all.length} • Users: ${store.userCount}');
  stdout.writeln('Database: $storePath');
}
