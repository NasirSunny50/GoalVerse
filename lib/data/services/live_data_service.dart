import 'dart:convert';

import 'package:http/http.dart' as http;

/// A live fixture pulled from TheSportsDB (real FIFA World Cup 2026 data).
class RemoteEvent {
  RemoteEvent({
    required this.id,
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.progress,
    required this.kickoffUtc,
  });

  final String id;
  final String homeName;
  final String awayName;
  final int? homeScore;
  final int? awayScore;
  final String status; // NS, 1H, HT, 2H, ET, FT, AET, PEN, ...
  final String? progress; // sometimes the live minute
  final DateTime? kickoffUtc;

  bool get isFinished {
    final s = status.toUpperCase();
    return s.contains('FT') ||
        s.contains('FINISH') ||
        s == 'AET' ||
        s == 'PEN' ||
        s == 'AWARDED';
  }

  bool get isNotStarted {
    final s = status.toUpperCase();
    return s.isEmpty ||
        s == 'NS' ||
        s == 'TBD' ||
        s.contains('POSTP') ||
        s.contains('CANC');
  }

  bool get isLive => !isFinished && !isNotStarted;
  bool get isHalfTime => status.toUpperCase() == 'HT';
}

enum TlType { goal, ownGoal, penalty, yellow, secondYellow, red, sub, varEvent, other }

/// A real match event (goal / card / substitution) from the live feed.
class TimelineEntry {
  TimelineEntry({
    required this.type,
    required this.minute,
    required this.player,
    required this.isHome,
    this.assist,
  });
  final TlType type;
  final int minute;
  final String player;
  final bool isHome;
  final String? assist;
}

/// A real lineup entry from the live feed.
class LineupEntry {
  LineupEntry({
    required this.player,
    required this.position,
    required this.isHome,
    required this.isSub,
    this.number,
  });
  final String player;
  final String position;
  final bool isHome;
  final bool isSub;
  final int? number;
}

/// A real team stat row (e.g. "Possession", 55, 45).
class EventStat {
  EventStat({required this.name, required this.home, required this.away});
  final String name;
  final String home;
  final String away;
}

/// Bundle of real per-match detail.
class EventDetail {
  EventDetail({required this.timeline, required this.lineup, required this.stats});
  final List<TimelineEntry> timeline;
  final List<LineupEntry> lineup;
  final List<EventStat> stats;

  bool get isEmpty => timeline.isEmpty && lineup.isEmpty && stats.isEmpty;
}

/// Fetches real FIFA World Cup 2026 data from TheSportsDB's free API
/// (league id 4429, no API key required for the public `/3/` endpoints).
class LiveDataService {
  LiveDataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://www.thesportsdb.com/api/v1/json/3';
  static const _leagueId = '4429'; // FIFA World Cup

  Future<List<RemoteEvent>> fetchDay(DateTime dayUtc) async {
    final d = '${dayUtc.year.toString().padLeft(4, '0')}-'
        '${dayUtc.month.toString().padLeft(2, '0')}-'
        '${dayUtc.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_base/eventsday.php?d=$d&l=$_leagueId');
    final res = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return const [];
    return _parseEvents(res.body);
  }

  /// Fetches every day in [start]..[end] (inclusive) in parallel.
  Future<List<RemoteEvent>> fetchRange(DateTime start, DateTime end) async {
    final days = <DateTime>[];
    var d = DateTime.utc(start.year, start.month, start.day);
    final last = DateTime.utc(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    final results = await Future.wait(
      days.map((day) => fetchDay(day).catchError((_) => <RemoteEvent>[])),
    );
    return results.expand((e) => e).toList();
  }

  List<RemoteEvent> _parseEvents(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final events = json['events'];
    if (events is! List) return const [];
    final out = <RemoteEvent>[];
    for (final e in events) {
      if (e is! Map) continue;
      out.add(RemoteEvent(
        id: '${e['idEvent'] ?? ''}',
        homeName: '${e['strHomeTeam'] ?? ''}',
        awayName: '${e['strAwayTeam'] ?? ''}',
        homeScore: _toInt(e['intHomeScore']),
        awayScore: _toInt(e['intAwayScore']),
        status: '${e['strStatus'] ?? ''}'.trim(),
        progress: e['strProgress']?.toString(),
        kickoffUtc: _parseTs(e['strTimestamp'], e['dateEvent'], e['strTime']),
      ));
    }
    return out;
  }

  /// Real per-match detail: goals, cards, subs, lineups and stats.
  Future<EventDetail> fetchDetail(String idEvent) async {
    final results = await Future.wait([
      _fetchTimeline(idEvent),
      _fetchLineup(idEvent),
      _fetchStats(idEvent),
    ]);
    return EventDetail(
      timeline: results[0] as List<TimelineEntry>,
      lineup: results[1] as List<LineupEntry>,
      stats: results[2] as List<EventStat>,
    );
  }

  Future<List<TimelineEntry>> _fetchTimeline(String id) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/lookuptimeline.php?id=$id'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['timeline'];
      if (list is! List) return const [];
      final out = <TimelineEntry>[];
      for (final e in list) {
        if (e is! Map) continue;
        final player = '${e['strPlayer'] ?? ''}'.trim();
        if (player.isEmpty) continue;
        out.add(TimelineEntry(
          type: _tlType('${e['strTimeline'] ?? ''}'),
          minute: _toInt(e['intTime']) ?? 0,
          player: player,
          assist: _nonEmpty('${e['strAssist'] ?? ''}'),
          isHome: '${e['strHome'] ?? ''}'.toLowerCase() == 'yes',
        ));
      }
      out.sort((a, b) => a.minute.compareTo(b.minute));
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<LineupEntry>> _fetchLineup(String id) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/lookuplineup.php?id=$id'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['lineup'];
      if (list is! List) return const [];
      final out = <LineupEntry>[];
      for (final e in list) {
        if (e is! Map) continue;
        final player = '${e['strPlayer'] ?? ''}'.trim();
        if (player.isEmpty) continue;
        final pos = '${e['strPosition'] ?? ''}'.trim();
        final subFlag = '${e['strSubstitute'] ?? ''}'.toLowerCase() == 'yes';
        out.add(LineupEntry(
          player: player,
          position: pos,
          isHome: '${e['strHome'] ?? ''}'.toLowerCase() == 'yes',
          isSub: subFlag || pos.toLowerCase().contains('substitut'),
          number: _toInt(e['intSquadNumber']),
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<EventStat>> _fetchStats(String id) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/lookupeventstats.php?id=$id'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['eventstats'];
      if (list is! List) return const [];
      final out = <EventStat>[];
      for (final e in list) {
        if (e is! Map) continue;
        final name = '${e['strStat'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        out.add(EventStat(
          name: name,
          home: '${e['intHome'] ?? ''}'.trim(),
          away: '${e['intAway'] ?? ''}'.trim(),
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static String? _nonEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  static TlType _tlType(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('own')) return TlType.ownGoal;
    if (s.contains('penalty') && s.contains('miss')) return TlType.other;
    if (s.contains('penalty')) return TlType.penalty;
    if (s.contains('goal')) return TlType.goal;
    if (s.contains('red')) return TlType.red;
    if (s.contains('second') && s.contains('yellow')) return TlType.secondYellow;
    if (s.contains('yellow')) return TlType.yellow;
    if (s.contains('subst')) return TlType.sub;
    if (s.contains('var')) return TlType.varEvent;
    return TlType.other;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  static DateTime? _parseTs(dynamic ts, dynamic date, dynamic time) {
    if (ts is String && ts.isNotEmpty) {
      final s = ts.endsWith('Z') ? ts : '${ts}Z';
      return DateTime.tryParse(s)?.toUtc();
    }
    if (date is String && date.isNotEmpty) {
      final t = (time is String && time.isNotEmpty) ? time : '00:00:00';
      return DateTime.tryParse('${date}T${t}Z')?.toUtc();
    }
    return null;
  }

  void dispose() => _client.close();
}
