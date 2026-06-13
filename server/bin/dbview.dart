// Prints every table in the GoalVerse database.
// Run from the server folder:  dart run bin/dbview.dart
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
    stdout.writeln('No database yet at $path — start the server first.');
    return;
  }

  final db = sqlite3.open(path);
  stdout.writeln('GoalVerse database: $path\n');
  final tables = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name");
  for (final t in tables) {
    final name = t['name'] as String;
    final rs = db.select('SELECT * FROM $name');
    stdout.writeln('================ $name (${rs.length} rows) ================');
    stdout.writeln('columns: ${rs.columnNames.join(' | ')}');
    for (final row in rs.rows) {
      stdout.writeln(
          '  ${row.map((v) => v == null ? 'NULL' : '$v').join(' | ')}');
    }
    stdout.writeln('');
  }
  db.dispose();
}
