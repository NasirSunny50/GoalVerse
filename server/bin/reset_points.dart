// Clears only the POINT-related data — match predictions, admin match results
// and tournament predictions — so every score resets to 0. Accounts and login
// sessions are KEPT. Run from the server folder:  dart run bin/reset_points.dart
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  open.overrideForAll(() {
    for (final c in ['sqlite3.dll', 'server/sqlite3.dll']) {
      if (File(c).existsSync()) return DynamicLibrary.open(File(c).absolute.path);
    }
    return DynamicLibrary.open('sqlite3.dll');
  });

  final path = File('data/goalverse.db').existsSync()
      ? 'data/goalverse.db'
      : 'server/data/goalverse.db';
  if (!File(path).existsSync()) {
    stdout.writeln('No database found.');
    return;
  }
  final db = sqlite3.open(path);
  for (final t in [
    'match_predictions',
    'match_results',
    'tournament_predictions',
  ]) {
    db.execute('DELETE FROM $t');
  }
  final users =
      db.select('SELECT COUNT(*) AS c FROM users').first['c'];
  db.dispose();
  stdout.writeln('Point data cleared — predictions, results & tournament picks '
      'reset to 0. $users account(s) kept.');
}
