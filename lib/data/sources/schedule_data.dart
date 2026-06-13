import '../models/match.dart';

/// One scheduled fixture as published by FIFA. Times are the venue's LOCAL
/// kick-off time; the repository converts them to an absolute UTC instant
/// using the venue's [utcOffset], so they can be shown in any time zone
/// (the app displays Bangladesh time, UTC+6).
class FixtureSeed {
  const FixtureSeed({
    required this.stage,
    required this.venueId,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    this.group,
    this.homeId,
    this.awayId,
  });

  final MatchStage stage;
  final String venueId;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final String? group;
  final String? homeId;
  final String? awayId;
}

/// Convenience builder for a group-stage fixture (always June).
FixtureSeed _g(String group, String home, String away, String venue, int day,
        int hour,
        [int minute = 0]) =>
    FixtureSeed(
      stage: MatchStage.groupStage,
      group: group,
      homeId: home,
      awayId: away,
      venueId: venue,
      month: 6,
      day: day,
      hour: hour,
      minute: minute,
    );

/// All 72 group-stage fixtures — real schedule, FIFA World Cup 2026.
final List<FixtureSeed> kGroupSchedule = [
  // Group A
  _g('A', 'mex', 'rsa', 'azteca', 11, 13),
  _g('A', 'kor', 'cze', 'akron', 11, 20),
  _g('A', 'cze', 'rsa', 'mercedes', 18, 12),
  _g('A', 'mex', 'kor', 'akron', 18, 19),
  _g('A', 'cze', 'mex', 'azteca', 24, 19),
  _g('A', 'rsa', 'kor', 'bbva', 24, 19),
  // Group B
  _g('B', 'can', 'bih', 'bmo', 12, 15),
  _g('B', 'qat', 'sui', 'levis', 13, 12),
  _g('B', 'sui', 'bih', 'sofi', 18, 12),
  _g('B', 'can', 'qat', 'bcplace', 18, 15),
  _g('B', 'sui', 'can', 'bcplace', 24, 12),
  _g('B', 'bih', 'qat', 'lumen', 24, 12),
  // Group C
  _g('C', 'bra', 'mar', 'metlife', 13, 18),
  _g('C', 'hai', 'sco', 'gillette', 13, 21),
  _g('C', 'sco', 'mar', 'gillette', 19, 18),
  _g('C', 'bra', 'hai', 'lincoln', 19, 20, 30),
  _g('C', 'sco', 'bra', 'hardrock', 24, 18),
  _g('C', 'mar', 'hai', 'mercedes', 24, 18),
  // Group D
  _g('D', 'usa', 'par', 'sofi', 12, 18),
  _g('D', 'aus', 'tur', 'bcplace', 13, 21),
  _g('D', 'usa', 'aus', 'lumen', 19, 12),
  _g('D', 'tur', 'par', 'levis', 19, 20),
  _g('D', 'tur', 'usa', 'sofi', 25, 19),
  _g('D', 'par', 'aus', 'levis', 25, 19),
  // Group E
  _g('E', 'ger', 'cuw', 'nrg', 14, 12),
  _g('E', 'civ', 'ecu', 'lincoln', 14, 19),
  _g('E', 'ger', 'civ', 'bmo', 20, 16),
  _g('E', 'ecu', 'cuw', 'arrowhead', 20, 19),
  _g('E', 'cuw', 'civ', 'lincoln', 25, 16),
  _g('E', 'ecu', 'ger', 'metlife', 25, 16),
  // Group F
  _g('F', 'ned', 'jpn', 'att', 14, 15),
  _g('F', 'swe', 'tun', 'bbva', 14, 20),
  _g('F', 'ned', 'swe', 'nrg', 20, 12),
  _g('F', 'tun', 'jpn', 'bbva', 20, 22),
  _g('F', 'jpn', 'swe', 'att', 25, 18),
  _g('F', 'tun', 'ned', 'arrowhead', 25, 18),
  // Group G
  _g('G', 'bel', 'egy', 'lumen', 15, 12),
  _g('G', 'irn', 'nzl', 'sofi', 15, 18),
  _g('G', 'bel', 'irn', 'sofi', 21, 12),
  _g('G', 'nzl', 'egy', 'bcplace', 21, 18),
  _g('G', 'egy', 'irn', 'lumen', 26, 20),
  _g('G', 'nzl', 'bel', 'bcplace', 26, 20),
  // Group H
  _g('H', 'esp', 'cpv', 'mercedes', 15, 12),
  _g('H', 'ksa', 'uru', 'hardrock', 15, 18),
  _g('H', 'esp', 'ksa', 'mercedes', 21, 12),
  _g('H', 'uru', 'cpv', 'hardrock', 21, 18),
  _g('H', 'cpv', 'ksa', 'nrg', 26, 19),
  _g('H', 'uru', 'esp', 'akron', 26, 18),
  // Group I
  _g('I', 'fra', 'sen', 'metlife', 16, 15),
  _g('I', 'irq', 'nor', 'gillette', 16, 18),
  _g('I', 'fra', 'irq', 'lincoln', 22, 17),
  _g('I', 'nor', 'sen', 'metlife', 22, 20),
  _g('I', 'nor', 'fra', 'gillette', 26, 15),
  _g('I', 'sen', 'irq', 'bmo', 26, 15),
  // Group J
  _g('J', 'arg', 'alg', 'arrowhead', 16, 20),
  _g('J', 'aut', 'jor', 'levis', 16, 21),
  _g('J', 'arg', 'aut', 'att', 22, 12),
  _g('J', 'jor', 'alg', 'levis', 22, 20),
  _g('J', 'alg', 'aut', 'arrowhead', 27, 21),
  _g('J', 'jor', 'arg', 'att', 27, 21),
  // Group K
  _g('K', 'por', 'cod', 'nrg', 17, 12),
  _g('K', 'uzb', 'col', 'azteca', 17, 20),
  _g('K', 'por', 'uzb', 'nrg', 23, 12),
  _g('K', 'col', 'cod', 'akron', 23, 20),
  _g('K', 'col', 'por', 'hardrock', 27, 19, 30),
  _g('K', 'cod', 'uzb', 'mercedes', 27, 19, 30),
  // Group L
  _g('L', 'eng', 'cro', 'att', 17, 15),
  _g('L', 'gha', 'pan', 'bmo', 17, 19),
  _g('L', 'eng', 'gha', 'gillette', 23, 16),
  _g('L', 'pan', 'cro', 'bmo', 23, 19),
  _g('L', 'pan', 'eng', 'metlife', 27, 17),
  _g('L', 'cro', 'gha', 'lincoln', 27, 17),
];

/// Builder for a knockout fixture (teams resolved later → placeholders).
FixtureSeed _k(MatchStage stage, String venue, int month, int day, int hour,
        [int minute = 0]) =>
    FixtureSeed(
      stage: stage,
      venueId: venue,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
    );

/// The 32 knockout fixtures — real dates, venues and kick-off times.
final List<FixtureSeed> kKnockoutSchedule = [
  // Round of 32 (16)
  _k(MatchStage.roundOf32, 'sofi', 6, 28, 12),
  _k(MatchStage.roundOf32, 'nrg', 6, 29, 12),
  _k(MatchStage.roundOf32, 'gillette', 6, 29, 16, 30),
  _k(MatchStage.roundOf32, 'bbva', 6, 29, 19),
  _k(MatchStage.roundOf32, 'att', 6, 30, 12),
  _k(MatchStage.roundOf32, 'metlife', 6, 30, 17),
  _k(MatchStage.roundOf32, 'azteca', 6, 30, 19),
  _k(MatchStage.roundOf32, 'mercedes', 7, 1, 12),
  _k(MatchStage.roundOf32, 'lumen', 7, 1, 13),
  _k(MatchStage.roundOf32, 'levis', 7, 1, 17),
  _k(MatchStage.roundOf32, 'sofi', 7, 2, 12),
  _k(MatchStage.roundOf32, 'bmo', 7, 2, 19),
  _k(MatchStage.roundOf32, 'bcplace', 7, 2, 20),
  _k(MatchStage.roundOf32, 'att', 7, 3, 13),
  _k(MatchStage.roundOf32, 'hardrock', 7, 3, 18),
  _k(MatchStage.roundOf32, 'arrowhead', 7, 3, 20, 30),
  // Round of 16 (8)
  _k(MatchStage.roundOf16, 'nrg', 7, 4, 12),
  _k(MatchStage.roundOf16, 'lincoln', 7, 4, 17),
  _k(MatchStage.roundOf16, 'metlife', 7, 5, 16),
  _k(MatchStage.roundOf16, 'azteca', 7, 5, 18),
  _k(MatchStage.roundOf16, 'att', 7, 6, 14),
  _k(MatchStage.roundOf16, 'lumen', 7, 6, 17),
  _k(MatchStage.roundOf16, 'mercedes', 7, 7, 12),
  _k(MatchStage.roundOf16, 'bcplace', 7, 7, 13),
  // Quarter-finals (4)
  _k(MatchStage.quarterFinal, 'gillette', 7, 9, 16),
  _k(MatchStage.quarterFinal, 'sofi', 7, 10, 12),
  _k(MatchStage.quarterFinal, 'hardrock', 7, 11, 17),
  _k(MatchStage.quarterFinal, 'arrowhead', 7, 11, 20),
  // Semi-finals (2)
  _k(MatchStage.semiFinal, 'att', 7, 14, 14),
  _k(MatchStage.semiFinal, 'mercedes', 7, 15, 15),
  // Third place
  _k(MatchStage.thirdPlace, 'hardrock', 7, 18, 17),
  // Final
  _k(MatchStage.finalMatch, 'metlife', 7, 19, 15),
];
