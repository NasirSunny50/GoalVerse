import 'dart:convert';
import 'dart:io';

/// The real tournament outcome, used to grade tournament-long predictions
/// (champion / runner-up / golden boot / golden glove — each stored as a
/// **team id**).
///
/// Until the Final has been played and an admin records the result with
/// `bin/set_result.dart`, [decided] is `false` and **no tournament points are
/// ever awarded**. A missing or unreadable result file also yields
/// [undecided], so scoring can never crash or award points by accident.
class TournamentResult {
  const TournamentResult({
    this.decided = false,
    this.champion,
    this.runnerUp,
    this.goldenBoot,
    this.goldenGlove,
  });

  /// Whether an admin has recorded a final result. Points are only graded
  /// when this is true.
  final bool decided;

  final String? champion; // team id of the winners
  final String? runnerUp; // team id of the beaten finalists
  final String? goldenBoot; // team id of the tournament top scorer
  final String? goldenGlove; // team id of the best goalkeeper

  static const undecided = TournamentResult();

  /// Normalises a raw team id to the same lower-cased form predictions use,
  /// or null for empty/absent values.
  static String? normId(dynamic v) {
    final s = v?.toString().trim().toLowerCase();
    return (s == null || s.isEmpty) ? null : s;
  }

  Map<String, dynamic> toJson() => {
        'decided': decided,
        'champion': champion,
        'runnerUp': runnerUp,
        'goldenBoot': goldenBoot,
        'goldenGlove': goldenGlove,
      };

  static TournamentResult fromJson(Map<String, dynamic> j) => TournamentResult(
        decided: j['decided'] == true,
        champion: normId(j['champion']),
        runnerUp: normId(j['runnerUp']),
        goldenBoot: normId(j['goldenBoot']),
        goldenGlove: normId(j['goldenGlove']),
      );

  /// Reads the result from [path]; returns [undecided] if the file is missing
  /// or unreadable so scoring never throws and never awards by accident.
  static TournamentResult loadFromFile(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return undecided;
      final raw = f.readAsStringSync().trim();
      if (raw.isEmpty) return undecided;
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return undecided;
    }
  }
}
