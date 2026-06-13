import '../../data/models/standing.dart';
import '../../data/models/team.dart';
import '../../data/repositories/fixtures_repository.dart';
import '../../data/sources/teams_data.dart';

/// One knockout round on a team's projected road to the final.
class RoadRound {
  RoadRound({
    required this.title,
    required this.subtitle,
    required this.possibleOpponents,
  });

  final String title;
  final String subtitle;

  /// Teams the selected team could face at this round, given the projected
  /// bracket. A single entry means a fixed opponent (Round of 16).
  final List<Team> possibleOpponents;
}

/// Projects group qualifiers from current standings and derives a clean
/// 16-team knockout bracket, then computes the "possible opponents" the
/// selected team could meet at each round on the way to the final.
class RoadToFinal {
  RoadToFinal(this.repo);
  final FixturesRepository repo;

  /// Standard 16-team seed bracket order (so seeds 1 & 2 can only meet in
  /// the final). Values are 1-based seeds.
  static const _seedOrder = [
    1, 16, 8, 9, 5, 12, 4, 13, 3, 14, 6, 11, 7, 10, 2, 15,
  ];

  /// Whether [team] is projected to reach the 16-team knockout bracket.
  bool _qualifies(Team team, List<Team> qualified) =>
      qualified.any((t) => t.id == team.id);

  /// Builds the projected qualifier list: 12 group winners + 4 best
  /// runners-up, seeded by projected strength.
  List<Standing> _projectedQualifiers() {
    final winners = <Standing>[];
    final runnersUp = <Standing>[];
    for (final g in kGroupLetters) {
      final table = repo.standingsForGroup(g);
      winners.add(table[0]);
      runnersUp.add(table[1]);
    }
    runnersUp.sort(_standingStrength);
    final bestRunners = runnersUp.take(4).toList();
    final all = [...winners, ...bestRunners];
    all.sort(_standingStrength);
    return all;
  }

  int _standingStrength(Standing a, Standing b) {
    if (b.points != a.points) return b.points - a.points;
    if (b.goalDifference != a.goalDifference) {
      return b.goalDifference - a.goalDifference;
    }
    if (b.goalsFor != a.goalsFor) return b.goalsFor - a.goalsFor;
    return b.team.rating - a.team.rating;
  }

  Result buildFor(Team team) {
    var qualifiers = _projectedQualifiers();
    var qualifiedTeams = qualifiers.map((s) => s.team).toList();
    final qualifies = _qualifies(team, qualifiedTeams);

    // If projected out, swap the selected team in for the weakest qualifier
    // so we can still visualise their potential path.
    if (!qualifies) {
      qualifiers = List.of(qualifiers)..removeLast();
      qualifiers.add(Standing(team: team));
      qualifiers.sort(_standingStrength);
      qualifiedTeams = qualifiers.map((s) => s.team).toList();
    }

    // Map seed (1-based, index in strength-sorted list) -> leaf position.
    final leaves = List<Team>.filled(16, team);
    for (var leaf = 0; leaf < 16; leaf++) {
      final seed = _seedOrder[leaf]; // 1..16
      leaves[leaf] = qualifiedTeams[seed - 1];
    }

    final myLeaf = leaves.indexWhere((t) => t.id == team.id);

    final rounds = <RoadRound>[];
    const titles = ['Round of 16', 'Quarter-final', 'Semi-final', 'Final'];
    const subtitles = [
      'First knockout test',
      'Win to reach the last four',
      'One step from the showpiece',
      'The ultimate prize',
    ];
    for (var k = 1; k <= 4; k++) {
      final blockSize = 1 << k; // 2,4,8,16
      final halfSize = 1 << (k - 1);
      final blockStart = (myLeaf ~/ blockSize) * blockSize;
      final myHalf = (myLeaf - blockStart) ~/ halfSize; // 0 or 1
      final oppHalfStart = blockStart + (myHalf == 0 ? halfSize : 0);
      final opponents = <Team>[];
      for (var i = oppHalfStart; i < oppHalfStart + halfSize; i++) {
        opponents.add(leaves[i]);
      }
      rounds.add(RoadRound(
        title: titles[k - 1],
        subtitle: subtitles[k - 1],
        possibleOpponents: opponents,
      ));
    }

    return Result(
      qualifies: qualifies,
      seed: qualifiedTeams.indexWhere((t) => t.id == team.id) + 1,
      rounds: rounds,
    );
  }
}

class Result {
  Result({
    required this.qualifies,
    required this.seed,
    required this.rounds,
  });

  /// Whether the team is currently projected to qualify.
  final bool qualifies;

  /// Projected overall seed (1 = strongest qualifier).
  final int seed;

  final List<RoadRound> rounds;
}
