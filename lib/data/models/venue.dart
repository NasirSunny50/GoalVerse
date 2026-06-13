import 'package:flutter/material.dart';

/// A host stadium / venue for the FIFA World Cup 2026.
@immutable
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.capacity,
    required this.timeZone,
    required this.utcOffset,
    required this.latitude,
    required this.longitude,
    required this.accent,
  });

  final String id;

  /// Stadium name, e.g. "MetLife Stadium".
  final String name;

  /// Host city, e.g. "New York / New Jersey".
  final String city;

  /// Host country: "USA", "Canada" or "Mexico".
  final String country;

  final int capacity;

  /// Short label for display, e.g. "ET".
  final String timeZone;

  /// Venue's UTC offset (hours) during the tournament (summer DST applied),
  /// e.g. -4 for Eastern, -7 for Pacific, -6 for Mexico.
  final int utcOffset;

  /// Normalised 0..1 position on the stylised map (x).
  final double longitude;

  /// Normalised 0..1 position on the stylised map (y).
  final double latitude;

  final Color accent;

  String get countryFlag {
    switch (country) {
      case 'USA':
        return '🇺🇸';
      case 'Canada':
        return '🇨🇦';
      case 'Mexico':
        return '🇲🇽';
      default:
        return '🏟️';
    }
  }
}
