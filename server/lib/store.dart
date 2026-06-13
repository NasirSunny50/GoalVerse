import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

bool _libReady = false;

/// Point the sqlite3 package at the bundled `sqlite3.dll` (sits next to the
/// server). Works from both `server/` (server + tests) cwd.
void _ensureLib() {
  if (_libReady) return;
  open.overrideForAll(() {
    for (final c in ['sqlite3.dll', 'server/sqlite3.dll']) {
      if (File(c).existsSync()) return DynamicLibrary.open(File(c).absolute.path);
    }
    return DynamicLibrary.open('sqlite3.dll');
  });
  _libReady = true;
}

/// SQLite-backed persistence. Real tables — open `data/goalverse.db` in any
/// SQLite viewer (DB Browser for SQLite, DBeaver, VS Code SQLite, …).
class Store {
  Store(this.path) {
    _ensureLib();
    Directory(File(path).parent.path).createSync(recursive: true);
    _db = sqlite3.open(path);
    _migrate();
  }

  final String path;
  late final Database _db;

  void _migrate() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        email        TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        employee_id  TEXT,
        pw_hash      TEXT NOT NULL,
        salt         TEXT NOT NULL,
        created_at   TEXT
      );
      CREATE TABLE IF NOT EXISTS sessions (
        token       TEXT PRIMARY KEY,
        email       TEXT NOT NULL,
        created_at  TEXT
      );
      CREATE TABLE IF NOT EXISTS match_predictions (
        email        TEXT NOT NULL,
        match_id     TEXT NOT NULL,
        winner       TEXT,
        home_score   INTEGER,
        away_score   INTEGER,
        first_scorer TEXT,
        motm         TEXT,
        red_card     INTEGER,
        over_under   TEXT,
        btts         INTEGER,
        penalties    INTEGER,
        PRIMARY KEY (email, match_id)
      );
      CREATE TABLE IF NOT EXISTS tournament_predictions (
        email             TEXT PRIMARY KEY,
        winner_team       TEXT,
        runner_up_team    TEXT,
        golden_boot_team  TEXT,
        golden_glove_team TEXT
      );
      CREATE TABLE IF NOT EXISTS match_results (
        match_id     TEXT PRIMARY KEY,
        home_team_id TEXT,
        away_team_id TEXT,
        winner       TEXT,
        home_score   INTEGER,
        away_score   INTEGER,
        first_scorer TEXT,
        motm         TEXT,
        red_card     INTEGER,
        over_under   TEXT,
        btts         INTEGER,
        penalties    INTEGER,
        confirmed_at TEXT
      );
    ''');
    // Migrate older DBs to the current columns.
    _ensureColumn('match_results', 'home_team_id', 'TEXT');
    _ensureColumn('match_results', 'away_team_id', 'TEXT');
    _ensureColumn('match_results', 'over_under', 'TEXT');
    _ensureColumn('match_results', 'btts', 'INTEGER');
    _ensureColumn('match_results', 'penalties', 'INTEGER');
    _ensureColumn('match_predictions', 'over_under', 'TEXT');
    _ensureColumn('match_predictions', 'btts', 'INTEGER');
    _ensureColumn('match_predictions', 'penalties', 'INTEGER');
  }

  void _ensureColumn(String table, String column, String type) {
    final cols = _db
        .select('PRAGMA table_info($table)')
        .map((r) => r['name'] as String)
        .toSet();
    if (!cols.contains(column)) {
      _db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  // ---- admin match results (the ONLY source scoring grades against) -------

  Map<String, dynamic> _resultRow(Row r) => {
        'homeTeamId': r['home_team_id'],
        'awayTeamId': r['away_team_id'],
        'winner': r['winner'],
        'homeScore': r['home_score'],
        'awayScore': r['away_score'],
        'firstScorer': r['first_scorer'],
        'overUnder': r['over_under'],
        'btts': r['btts'] == null ? null : (r['btts'] as int) == 1,
        'penalties':
            r['penalties'] == null ? null : (r['penalties'] as int) == 1,
        'confirmedAt': r['confirmed_at'],
      };

  /// All admin-confirmed match results, keyed by match id.
  Map<String, Map<String, dynamic>> matchResults() {
    final out = <String, Map<String, dynamic>>{};
    for (final r in _db.select('SELECT * FROM match_results')) {
      out[r['match_id'] as String] = _resultRow(r);
    }
    return out;
  }

  Map<String, dynamic>? matchResult(String matchId) {
    final r =
        _db.select('SELECT * FROM match_results WHERE match_id = ?', [matchId]);
    return r.isEmpty ? null : _resultRow(r.first);
  }

  void saveMatchResult(String matchId, Map<String, dynamic> r) {
    _db.execute(
      'INSERT OR REPLACE INTO match_results '
      '(match_id, home_team_id, away_team_id, winner, home_score, away_score, first_scorer, over_under, btts, penalties, confirmed_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        matchId,
        r['homeTeamId'],
        r['awayTeamId'],
        r['winner'],
        r['homeScore'],
        r['awayScore'],
        r['firstScorer'],
        r['overUnder'],
        r['btts'] == null ? null : (r['btts'] == true ? 1 : 0),
        r['penalties'] == null ? null : (r['penalties'] == true ? 1 : 0),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  void deleteMatchResult(String matchId) =>
      _db.execute('DELETE FROM match_results WHERE match_id = ?', [matchId]);

  // ---- users --------------------------------------------------------------

  int get userCount =>
      _db.select('SELECT COUNT(*) AS c FROM users').first['c'] as int;

  bool userExists(String email) => _db
      .select('SELECT 1 FROM users WHERE email = ?', [email.toLowerCase()])
      .isNotEmpty;

  Map<String, dynamic>? user(String email) {
    final r =
        _db.select('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
    return r.isEmpty ? null : _userRow(r.first);
  }

  Map<String, dynamic> _userRow(Row r) => {
        'name': r['name'],
        'email': r['email'],
        'eid': r['employee_id'],
        'pwHash': r['pw_hash'],
        'salt': r['salt'],
        'created': r['created_at'],
      };

  void saveUser(Map<String, dynamic> u) {
    _db.execute(
      'INSERT OR REPLACE INTO users (email, name, employee_id, pw_hash, salt, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        (u['email'] as String).toLowerCase(),
        u['name'],
        u['eid'],
        u['pwHash'],
        u['salt'],
        u['created'],
      ],
    );
  }

  List<Map<String, dynamic>> allUsers() =>
      _db.select('SELECT * FROM users').map(_userRow).toList();

  // ---- sessions -----------------------------------------------------------

  String? emailForToken(String token) {
    final r = _db.select('SELECT email FROM sessions WHERE token = ?', [token]);
    return r.isEmpty ? null : r.first['email'] as String;
  }

  String issueToken(String token, String email) {
    _db.execute(
      'INSERT OR REPLACE INTO sessions (token, email, created_at) VALUES (?, ?, ?)',
      [token, email.toLowerCase(), DateTime.now().toUtc().toIso8601String()],
    );
    return token;
  }

  void revokeToken(String token) =>
      _db.execute('DELETE FROM sessions WHERE token = ?', [token]);

  // ---- predictions --------------------------------------------------------

  /// Returns {match: {matchId: {...}}, tournament: {...}} — the same shape the
  /// API and scorer expect.
  Map<String, dynamic> predsFor(String email) {
    email = email.toLowerCase();
    final match = <String, dynamic>{};
    for (final r in _db
        .select('SELECT * FROM match_predictions WHERE email = ?', [email])) {
      match[r['match_id'] as String] = {
        'winner': r['winner'],
        'homeScore': r['home_score'],
        'awayScore': r['away_score'],
        'firstScorerSide': r['first_scorer'],
        'overUnder': r['over_under'],
        'btts': r['btts'] == null ? null : (r['btts'] as int) == 1,
        'penalties':
            r['penalties'] == null ? null : (r['penalties'] as int) == 1,
      };
    }
    final tr = _db.select(
        'SELECT * FROM tournament_predictions WHERE email = ?', [email]);
    final tournament = tr.isEmpty
        ? <String, dynamic>{}
        : {
            'winnerTeamId': tr.first['winner_team'],
            'runnerUpTeamId': tr.first['runner_up_team'],
            'goldenBootTeamId': tr.first['golden_boot_team'],
            'goldenGloveTeamId': tr.first['golden_glove_team'],
          };
    return {'match': match, 'tournament': tournament};
  }

  void savePredsFor(String email, Map<String, dynamic> data) {
    email = email.toLowerCase();
    final match = (data['match'] as Map?)?.cast<String, dynamic>() ?? {};
    match.forEach((matchId, raw) {
      final p = (raw as Map).cast<String, dynamic>();
      _db.execute(
        'INSERT OR REPLACE INTO match_predictions '
        '(email, match_id, winner, home_score, away_score, first_scorer, over_under, btts, penalties) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          email,
          matchId,
          p['winner'],
          p['homeScore'],
          p['awayScore'],
          p['firstScorerSide'],
          p['overUnder'],
          p['btts'] == null ? null : (p['btts'] == true ? 1 : 0),
          p['penalties'] == null ? null : (p['penalties'] == true ? 1 : 0),
        ],
      );
    });
    final t = (data['tournament'] as Map?)?.cast<String, dynamic>();
    if (t != null && t.isNotEmpty) {
      _db.execute(
        'INSERT OR REPLACE INTO tournament_predictions '
        '(email, winner_team, runner_up_team, golden_boot_team, golden_glove_team) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          email,
          t['winnerTeamId'],
          t['runnerUpTeamId'],
          t['goldenBootTeamId'],
          t['goldenGloveTeamId'],
        ],
      );
    }
  }

  void close() => _db.dispose();
}
