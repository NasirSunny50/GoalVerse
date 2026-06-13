import 'team.dart';
import 'venue.dart';

enum MatchStage {
  groupStage,
  roundOf32,
  roundOf16,
  quarterFinal,
  semiFinal,
  thirdPlace,
  finalMatch,
}

extension MatchStageX on MatchStage {
  String get label {
    switch (this) {
      case MatchStage.groupStage:
        return 'Group Stage';
      case MatchStage.roundOf32:
        return 'Round of 32';
      case MatchStage.roundOf16:
        return 'Round of 16';
      case MatchStage.quarterFinal:
        return 'Quarter-final';
      case MatchStage.semiFinal:
        return 'Semi-final';
      case MatchStage.thirdPlace:
        return 'Third Place';
      case MatchStage.finalMatch:
        return 'Final';
    }
  }

  String get shortLabel {
    switch (this) {
      case MatchStage.groupStage:
        return 'GROUP';
      case MatchStage.roundOf32:
        return 'R32';
      case MatchStage.roundOf16:
        return 'R16';
      case MatchStage.quarterFinal:
        return 'QF';
      case MatchStage.semiFinal:
        return 'SF';
      case MatchStage.thirdPlace:
        return '3RD';
      case MatchStage.finalMatch:
        return 'FINAL';
    }
  }

  bool get isKnockout => this != MatchStage.groupStage;
}

enum MatchStatus { upcoming, live, finished }

/// A single fixture in the tournament.
class FootballMatch {
  FootballMatch({
    required this.id,
    required this.matchNumber,
    required this.home,
    required this.away,
    required this.venue,
    required this.kickoff,
    required this.stage,
    required this.group,
    this.homeScore,
    this.awayScore,
    this.homePlaceholder,
    this.awayPlaceholder,
    this.minute,
  });

  final String id;
  final int matchNumber;

  /// Concrete teams; null for unresolved knockout slots. Mutable so the admin's
  /// knockout team assignments (from the backend) can be overlaid at runtime.
  Team? home;
  Team? away;

  final Venue venue;

  /// Absolute kick-off instant, stored in UTC.
  final DateTime kickoff;
  final MatchStage stage;

  /// Bangladesh Standard Time is UTC+6 (no daylight saving).
  static const Duration _bdtOffset = Duration(hours: 6);

  /// Kick-off shown in Bangladesh time (the app's display zone).
  DateTime get kickoffBd => kickoff.toUtc().add(_bdtOffset);

  /// Kick-off in the stadium's own local time.
  DateTime get kickoffLocal =>
      kickoff.toUtc().add(Duration(hours: venue.utcOffset));

  /// Group letter for group-stage matches, else null.
  final String? group;

  int? homeScore;
  int? awayScore;

  /// Label when the team is not yet known, e.g. "Winner Group A".
  final String? homePlaceholder;
  final String? awayPlaceholder;

  /// Live minute, when status == live.
  int? minute;

  // ---- Real data overlaid from the live API (null until fetched) ----
  String? remoteId;
  String? remoteStatus; // raw API status (NS, 1H, HT, 2H, FT, ...)
  int? remoteHomeScore;
  int? remoteAwayScore;
  bool remoteFinished = false;
  bool remoteNotStarted = false;
  bool remoteHalfTime = false;

  /// True once real data from the live source has been applied.
  bool get hasRemote => remoteStatus != null;

  String get homeName => home?.name ?? homePlaceholder ?? 'TBD';
  String get awayName => away?.name ?? awayPlaceholder ?? 'TBD';

  /// Live/finished status reflects ONLY real data from the live source. Without
  /// it the match is shown as its scheduled fixture (upcoming) — the app never
  /// fabricates a live/finished state from the clock alone. ([now] is kept for
  /// call-site compatibility.)
  MatchStatus statusAt(DateTime now) {
    if (hasRemote) {
      if (remoteFinished) return MatchStatus.finished;
      if (remoteNotStarted) return MatchStatus.upcoming;
      return MatchStatus.live;
    }
    return MatchStatus.upcoming;
  }

  bool involvesTeam(String teamId) =>
      home?.id == teamId || away?.id == teamId;

  Duration timeUntil(DateTime now) => kickoff.difference(now);
}
