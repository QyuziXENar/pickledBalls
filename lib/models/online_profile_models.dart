// lib/models/online_profile_models.dart

import 'dart:math' as math;

/// Official Pickleball DUPR (Dynamic Universal Pickleball Rating) Calculator
class DUPRCalculator {
  static const double minRating = 2.00;
  static const double maxRating = 6.00;

  /// Calculates rating adjustment using an Elo-inspired DUPR differential curve
  static double calculateDelta({
    required double playerRating,
    required double opponentRating,
    required bool won,
    required int scoreDiff,
  }) {
    // Expected win probability based on rating disparity
    final double exponent = (opponentRating - playerRating) / 0.5;
    final double expectedScore = 1.0 / (1.0 + math.pow(10, exponent));
    final double actualScore = won ? 1.0 : 0.0;

    // Weight factor scaled by margin of victory
    final double marginMultiplier = (scoreDiff.abs() / 11.0).clamp(0.5, 1.5);
    final double kFactor = 0.32 * marginMultiplier;

    double delta = kFactor * (actualScore - expectedScore);

    // DUPR ratings move in controlled micro-increments
    return double.parse(delta.clamp(-0.45, 0.45).toStringAsFixed(2));
  }
}

class OnlineUserProfile {
  final String uid;
  final String username;
  final String title;
  final double duprRating;
  final int trophies;
  final int careerWins;
  final int careerLosses;
  final String equippedAthleteId;
  final String equippedPaddleId;

  const OnlineUserProfile({
    required this.uid,
    required this.username,
    required this.title,
    required this.duprRating,
    required this.trophies,
    required this.careerWins,
    required this.careerLosses,
    required this.equippedAthleteId,
    required this.equippedPaddleId,
  });

  double get winRate => (careerWins + careerLosses) == 0
      ? 0.0
      : (careerWins / (careerWins + careerLosses));
}

class MatchPerformanceStats {
  final int playerScore;
  final int opponentScore;
  final int totalDinks;
  final int overheadSmashes;
  final int kitchenFaults;
  final int longestRally;
  final bool won;
  final double previousDupr;
  final double duprDelta;
  final int xpEarned;
  final int coinsEarned;

  const MatchPerformanceStats({
    required this.playerScore,
    required this.opponentScore,
    required this.totalDinks,
    required this.overheadSmashes,
    required this.kitchenFaults,
    required this.longestRally,
    required this.won,
    required this.previousDupr,
    required this.duprDelta,
    required this.xpEarned,
    required this.coinsEarned,
  });

  double get newDupr =>
      (previousDupr + duprDelta).clamp(DUPRCalculator.minRating, DUPRCalculator.maxRating);
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final String title;
  final double duprRating;
  final int metricValue; // Trophies, Wins, or Rally Hits
  final String athleteId;
  final String paddleId;
  final bool isCurrentPlayer;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.title,
    required this.duprRating,
    required this.metricValue,
    required this.athleteId,
    required this.paddleId,
    this.isCurrentPlayer = false,
  });
}

enum QuickChatCall {
  zeroZeroTwo('Zero-Zero-Two! 🏓'),
  niceDink('Nice dink! 🎯'),
  outOfKitchen('Out of the kitchen! ⚠️'),
  whatARally('What a rally! 🔥'),
  paddleTap('Paddle Tap! 🤝');

  final String text;
  const QuickChatCall(this.text);
}