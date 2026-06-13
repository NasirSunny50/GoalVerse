import 'package:flutter/material.dart';

/// A national team competing in the FIFA World Cup 2026.
@immutable
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.code,
    required this.flag,
    required this.group,
    required this.confederation,
    required this.rating,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Stable identifier (lowercase code), e.g. "arg".
  final String id;

  /// Display name, e.g. "Argentina".
  final String name;

  /// 3-letter FIFA code, e.g. "ARG".
  final String code;

  /// Flag emoji (used where supported).
  final String flag;

  /// Group letter, e.g. "A".
  final String group;

  /// Confederation, e.g. "CONMEBOL".
  final String confederation;

  /// Relative strength 0-100, used for deterministic score simulation.
  final int rating;

  final Color primaryColor;
  final Color secondaryColor;

  List<Color> get gradient => [primaryColor, secondaryColor];
}
