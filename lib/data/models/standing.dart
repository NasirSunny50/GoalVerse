import 'team.dart';

/// Computed group-stage standing row for a team.
class Standing {
  Standing({required this.team});

  final Team team;

  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  int get points => won * 3 + drawn;
  int get goalDifference => goalsFor - goalsAgainst;

  void record(int scored, int conceded) {
    played++;
    goalsFor += scored;
    goalsAgainst += conceded;
    if (scored > conceded) {
      won++;
    } else if (scored == conceded) {
      drawn++;
    } else {
      lost++;
    }
  }
}
