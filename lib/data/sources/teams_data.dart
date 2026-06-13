import 'package:flutter/material.dart';

import '../models/team.dart';

Team _t(String id, String name, String code, String flag, String group,
    String conf, int rating, int c1, int c2) {
  return Team(
    id: id,
    name: name,
    code: code,
    flag: flag,
    group: group,
    confederation: conf,
    rating: rating,
    primaryColor: Color(c1),
    secondaryColor: Color(c2),
  );
}

/// The 48 qualified national teams of the FIFA World Cup 2026, as drawn into
/// the 12 groups (A-L) at the Final Draw on 5 December 2025. Ratings drive the
/// deterministic score simulation.
final List<Team> kTeams = [
  // Group A
  _t('mex', 'Mexico', 'MEX', '🇲🇽', 'A', 'CONCACAF', 79, 0xFF006847, 0xFF12A05C),
  _t('rsa', 'South Africa', 'RSA', '🇿🇦', 'A', 'CAF', 68, 0xFF007749, 0xFFFFB81C),
  _t('kor', 'South Korea', 'KOR', '🇰🇷', 'A', 'AFC', 77, 0xFFCD2E3A, 0xFF0047A0),
  _t('cze', 'Czechia', 'CZE', '🇨🇿', 'A', 'UEFA', 75, 0xFFD7141A, 0xFF11457E),
  // Group B
  _t('can', 'Canada', 'CAN', '🇨🇦', 'B', 'CONCACAF', 76, 0xFFC8102E, 0xFFE53935),
  _t('bih', 'Bosnia & Herzegovina', 'BIH', '🇧🇦', 'B', 'UEFA', 72, 0xFF002F6C, 0xFFFFCD00),
  _t('qat', 'Qatar', 'QAT', '🇶🇦', 'B', 'AFC', 68, 0xFF8A1538, 0xFFB3204D),
  _t('sui', 'Switzerland', 'SUI', '🇨🇭', 'B', 'UEFA', 80, 0xFFD52B1E, 0xFFB71C1C),
  // Group C
  _t('bra', 'Brazil', 'BRA', '🇧🇷', 'C', 'CONMEBOL', 90, 0xFFFFDF00, 0xFF009B3A),
  _t('mar', 'Morocco', 'MAR', '🇲🇦', 'C', 'CAF', 84, 0xFFC1272D, 0xFF006233),
  _t('hai', 'Haiti', 'HAI', '🇭🇹', 'C', 'CONCACAF', 62, 0xFF00209F, 0xFFD21034),
  _t('sco', 'Scotland', 'SCO', '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'C', 'UEFA', 75, 0xFF0065BF, 0xFF003C71),
  // Group D
  _t('usa', 'United States', 'USA', '🇺🇸', 'D', 'CONCACAF', 77, 0xFF0A3161, 0xFFB31942),
  _t('par', 'Paraguay', 'PAR', '🇵🇾', 'D', 'CONMEBOL', 74, 0xFFD52B1E, 0xFF0038A8),
  _t('aus', 'Australia', 'AUS', '🇦🇺', 'D', 'AFC', 73, 0xFFFFD200, 0xFF00843D),
  _t('tur', 'Türkiye', 'TUR', '🇹🇷', 'D', 'UEFA', 78, 0xFFE30A17, 0xFFB1000F),
  // Group E
  _t('ger', 'Germany', 'GER', '🇩🇪', 'E', 'UEFA', 87, 0xFF2B2B2B, 0xFFDD0000),
  _t('cuw', 'Curaçao', 'CUW', '🇨🇼', 'E', 'CONCACAF', 60, 0xFF002B7F, 0xFFF9D616),
  _t('civ', 'Ivory Coast', 'CIV', '🇨🇮', 'E', 'CAF', 79, 0xFFFF8200, 0xFF009A44),
  _t('ecu', 'Ecuador', 'ECU', '🇪🇨', 'E', 'CONMEBOL', 80, 0xFFFFCE00, 0xFF0072CE),
  // Group F
  _t('ned', 'Netherlands', 'NED', '🇳🇱', 'F', 'UEFA', 87, 0xFFFF7900, 0xFFAE1C28),
  _t('jpn', 'Japan', 'JPN', '🇯🇵', 'F', 'AFC', 82, 0xFF0B1A6B, 0xFFE60012),
  _t('swe', 'Sweden', 'SWE', '🇸🇪', 'F', 'UEFA', 76, 0xFF006AA7, 0xFFFECC02),
  _t('tun', 'Tunisia', 'TUN', '🇹🇳', 'F', 'CAF', 72, 0xFFE70013, 0xFFB1000F),
  // Group G
  _t('bel', 'Belgium', 'BEL', '🇧🇪', 'G', 'UEFA', 85, 0xFFE30613, 0xFFD4A017),
  _t('egy', 'Egypt', 'EGY', '🇪🇬', 'G', 'CAF', 76, 0xFFC8102E, 0xFF1A1A1A),
  _t('irn', 'Iran', 'IRN', '🇮🇷', 'G', 'AFC', 75, 0xFF239F40, 0xFFDA0000),
  _t('nzl', 'New Zealand', 'NZL', '🇳🇿', 'G', 'OFC', 66, 0xFF1A1A1A, 0xFF6E7073),
  // Group H
  _t('esp', 'Spain', 'ESP', '🇪🇸', 'H', 'UEFA', 92, 0xFFC60B1E, 0xFFFFC400),
  _t('cpv', 'Cape Verde', 'CPV', '🇨🇻', 'H', 'CAF', 65, 0xFF003893, 0xFFCF2027),
  _t('ksa', 'Saudi Arabia', 'KSA', '🇸🇦', 'H', 'AFC', 70, 0xFF006C35, 0xFF12944C),
  _t('uru', 'Uruguay', 'URU', '🇺🇾', 'H', 'CONMEBOL', 84, 0xFF5CBFEB, 0xFF0038A8),
  // Group I
  _t('fra', 'France', 'FRA', '🇫🇷', 'I', 'UEFA', 91, 0xFF002395, 0xFFED2939),
  _t('sen', 'Senegal', 'SEN', '🇸🇳', 'I', 'CAF', 81, 0xFF00853F, 0xFFE0C200),
  _t('irq', 'Iraq', 'IRQ', '🇮🇶', 'I', 'AFC', 69, 0xFF007A3D, 0xFFCE1126),
  _t('nor', 'Norway', 'NOR', '🇳🇴', 'I', 'UEFA', 83, 0xFFBA0C2F, 0xFF00205B),
  // Group J
  _t('arg', 'Argentina', 'ARG', '🇦🇷', 'J', 'CONMEBOL', 92, 0xFF6CACE4, 0xFF4A90D9),
  _t('alg', 'Algeria', 'ALG', '🇩🇿', 'J', 'CAF', 76, 0xFF007A3D, 0xFF12944C),
  _t('aut', 'Austria', 'AUT', '🇦🇹', 'J', 'UEFA', 79, 0xFFED2939, 0xFFB1000F),
  _t('jor', 'Jordan', 'JOR', '🇯🇴', 'J', 'AFC', 68, 0xFF1A1A1A, 0xFF007A3D),
  // Group K
  _t('por', 'Portugal', 'POR', '🇵🇹', 'K', 'UEFA', 88, 0xFF006600, 0xFFCE1126),
  _t('cod', 'DR Congo', 'COD', '🇨🇩', 'K', 'CAF', 74, 0xFF007FFF, 0xFFF7D618),
  _t('uzb', 'Uzbekistan', 'UZB', '🇺🇿', 'K', 'AFC', 71, 0xFF1EB53A, 0xFF0099B5),
  _t('col', 'Colombia', 'COL', '🇨🇴', 'K', 'CONMEBOL', 84, 0xFFFCD116, 0xFF003893),
  // Group L
  _t('eng', 'England', 'ENG', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'L', 'UEFA', 89, 0xFF24408E, 0xFFCF142B),
  _t('cro', 'Croatia', 'CRO', '🇭🇷', 'L', 'UEFA', 82, 0xFFD32F2F, 0xFF1565C0),
  _t('gha', 'Ghana', 'GHA', '🇬🇭', 'L', 'CAF', 75, 0xFFCE1126, 0xFF006B3F),
  _t('pan', 'Panama', 'PAN', '🇵🇦', 'L', 'CONCACAF', 70, 0xFFC8102E, 0xFF005293),
];

final Map<String, Team> kTeamsById = {for (final t in kTeams) t.id: t};

Team teamById(String id) => kTeamsById[id]!;

List<Team> teamsInGroup(String group) =>
    kTeams.where((t) => t.group == group).toList();

const List<String> kGroupLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
];
