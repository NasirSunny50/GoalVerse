// Wipes ALL accounts, sessions and predictions (keeps the table structure),
// then RE-SEEDS the permanent admin row so it can never be lost.
// Run from the server folder:  dart run bin/reset_db.dart
import 'dart:ffi';
import 'dart:io';

import 'package:goalverse_server/util.dart';
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
    stdout.writeln('No database to reset.');
    return;
  }
  final db = sqlite3.open(path);
  for (final t in [
    'match_predictions',
    'tournament_predictions',
    'sessions',
    'users',
  ]) {
    db.execute('DELETE FROM $t');
  }
  // Re-seed the permanent admin (hashed) so it survives the wipe.
  final email =
      (Platform.environment['GV_ADMIN_EMAIL'] ?? 'admin@gmail.com').toLowerCase();
  final pw = Platform.environment['GV_ADMIN_PASSWORD'] ?? 'Admin@123';
  final salt = genSalt();
  db.execute(
    'INSERT OR REPLACE INTO users (email, name, employee_id, pw_hash, salt, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [
      email,
      'Admin',
      'ADMIN',
      hashPassword(pw, salt),
      salt,
      DateTime.now().toUtc().toIso8601String(),
    ],
  );
  db.dispose();
  stdout.writeln('Reset complete — all accounts & predictions cleared; '
      'admin re-seeded.');
}
