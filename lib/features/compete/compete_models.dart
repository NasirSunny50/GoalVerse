// Models for the GoalVerse prediction & competition system.
import 'package:flutter/widgets.dart';

enum Outcome { home, draw, away }

/// A user's prediction for a single match. Only the fields the user filled in
/// are non-null. Locked once the match starts.
class MatchPrediction {
  MatchPrediction({required this.matchId});

  final String matchId;
  Outcome? winner;
  int? homeScore;
  int? awayScore;
  String? firstScorerSide; // 'home' | 'away' | 'none'
  String? overUnder; // 'over' | 'under' (2.5 goals)
  bool? btts; // both teams to score?
  bool? penalties; // knockout only — decided on penalties?

  int points = 0;
  bool scored = false;

  bool get isEmpty =>
      winner == null &&
      homeScore == null &&
      firstScorerSide == null &&
      overUnder == null &&
      btts == null &&
      penalties == null;

  Map<String, dynamic> toJson() => {
        'm': matchId,
        'w': winner?.index,
        'hs': homeScore,
        'as': awayScore,
        'fs': firstScorerSide,
        'ou': overUnder,
        'bt': btts,
        'pe': penalties,
        'p': points,
        'sc': scored,
      };

  static MatchPrediction fromJson(Map<String, dynamic> j) {
    final p = MatchPrediction(matchId: '${j['m']}');
    final w = j['w'];
    p.winner = w is int ? Outcome.values[w] : null;
    p.homeScore = j['hs'];
    p.awayScore = j['as'];
    p.firstScorerSide = j['fs'];
    p.overUnder = j['ou'];
    p.btts = j['bt'];
    p.penalties = j['pe'];
    p.points = j['p'] ?? 0;
    p.scored = j['sc'] ?? false;
    return p;
  }
}

/// Tournament-long predictions, graded after the final.
class TournamentPrediction {
  String? winnerTeamId;
  String? runnerUpTeamId;
  String? goldenBootTeamId;
  String? goldenGloveTeamId;

  Map<String, dynamic> toJson() => {
        'w': winnerTeamId,
        'ru': runnerUpTeamId,
        'gb': goldenBootTeamId,
        'gg': goldenGloveTeamId,
      };

  static TournamentPrediction fromJson(Map<String, dynamic> j) {
    final t = TournamentPrediction();
    t.winnerTeamId = j['w'];
    t.runnerUpTeamId = j['ru'];
    t.goldenBootTeamId = j['gb'];
    t.goldenGloveTeamId = j['gg'];
    return t;
  }
}

/// A leaderboard row.
class LeaderboardEntry {
  LeaderboardEntry({
    required this.name,
    required this.points,
    required this.predictions,
    required this.correct,
    required this.isUser,
  });
  final String name;
  final int points;
  final int predictions;
  final int correct;
  final bool isUser;

  int get accuracy =>
      predictions == 0 ? 0 : ((correct / predictions) * 100).round();

  static LeaderboardEntry fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        name: '${j['name'] ?? '?'}',
        points: j['points'] ?? 0,
        predictions: j['predictions'] ?? 0,
        correct: j['correct'] ?? 0,
        isUser: j['isMe'] == true,
      );
}

/// An earnable achievement badge.
class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
  final String id;
  final String name;
  final String description;
  final IconData icon;
}

/// An in-app notification (deadline / achievement / rank).
class AppNotification {
  AppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.kind,
  });
  final String title;
  final String body;
  final IconData icon;
  final String kind; // deadline | achievement | rank | event
}

/// Point values for each scorable prediction market.
class Points {
  // Per-match markets.
  static const winner = 10;
  static const exact = 25;
  static const firstScorer = 12;
  static const overUnder = 8; // Over/Under 2.5 goals
  static const btts = 8; // Both Teams To Score
  static const penalties = 10; // knockout only — decided on penalties?

  // Tournament-long markets.
  static const champion = 50;
  static const runnerUp = 30;
  static const goldenBoot = 20;
  static const goldenGlove = 20;

  static const perPredictionXp = 10;
}
