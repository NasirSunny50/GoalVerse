import 'dart:convert';
import 'dart:io';

/// One fixture (loaded from data/fixtures.json, exported by the app so IDs and
/// deterministic results match exactly).
class Fixture {
  Fixture(Map<String, dynamic> j)
      : id = j['id'] as String,
        number = j['number'] as int,
        stage = j['stage'] as String,
        group = j['group'] as String?,
        homeId = j['homeId'] as String?,
        awayId = j['awayId'] as String?,
        homeName = j['homeName'] as String?,
        awayName = j['awayName'] as String?,
        homeCode = j['homeCode'] as String?,
        awayCode = j['awayCode'] as String?,
        kickoff = DateTime.parse(j['kickoff'] as String).toUtc(),
        ftHome = j['ftHome'] as int?,
        ftAway = j['ftAway'] as int?,
        redCard = j['redCard'] as bool?;

  final String id;
  final int number;
  final String stage;
  final String? group;
  final String? homeId;
  final String? awayId;
  final String? homeName;
  final String? awayName;
  final String? homeCode;
  final String? awayCode;
  final DateTime kickoff;
  final int? ftHome;
  final int? ftAway;
  final bool? redCard;

  bool get hasTeams => homeId != null && awayId != null;

  Map<String, dynamic> toMini() => {
        'id': id,
        'number': number,
        'stage': stage,
        'group': group,
        'homeId': homeId,
        'awayId': awayId,
        'homeName': homeName,
        'awayName': awayName,
        'homeCode': homeCode,
        'awayCode': awayCode,
        'kickoff': kickoff.toIso8601String(),
      };
}

/// Holds the fixture list. Compete scoring does NOT depend on any live data —
/// results come exclusively from the admin (see `Store.matchResults`).
class Fixtures {
  Fixtures(this.all) {
    byId = {for (final f in all) f.id: f};
  }

  final List<Fixture> all;
  late final Map<String, Fixture> byId;

  static Fixtures load(String path) {
    final raw = File(path).readAsStringSync();
    final list = (jsonDecode(raw) as List)
        .map((e) => Fixture(e as Map<String, dynamic>))
        .toList();
    return Fixtures(list);
  }

  Fixture? operator [](String id) => byId[id];

  /// The Final's kick-off (for the tournament deadline).
  DateTime get finalKickoff => all
      .firstWhere((f) => f.stage == 'finalMatch', orElse: () => all.last)
      .kickoff;

  /// A prediction is locked once the match has kicked off — purely time-based,
  /// with no dependency on any live feed.
  bool isLocked(String id, DateTime now) {
    final f = byId[id];
    if (f == null) return true;
    return !now.isBefore(f.kickoff);
  }
}
