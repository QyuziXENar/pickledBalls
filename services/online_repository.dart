// lib/services/online_repository.dart

import '../models/online_profile_models.dart';

enum LeaderboardCategory { globalDupr, localDivision, weeklyRallies }

abstract class OnlineRepository {
  Future<OnlineUserProfile> fetchUserProfile();
  Future<List<LeaderboardEntry>> fetchLeaderboard(LeaderboardCategory category);
  Future<void> submitMatchResult(MatchPerformanceStats stats);
}

/// Standalone Sandbox Provider: Works immediately on your device
/// without needing a live internet database. Johnmark will replace
/// this implementation with Firebase Realtime Database on branch-2!
class MockOnlineRepository implements OnlineRepository {
  static final MockOnlineRepository instance = MockOnlineRepository._();
  MockOnlineRepository._();

  OnlineUserProfile _localProfile = const OnlineUserProfile(
    uid: 'pb_user_local',
    username: 'You',
    title: 'Kitchen Tactician',
    duprRating: 3.42,
    trophies: 1240,
    careerWins: 28,
    careerLosses: 12,
    equippedAthleteId: 'aria',
    equippedPaddleId: 'volt_strike',
  );

  @override
  Future<OnlineUserProfile> fetchUserProfile() async {
    return _localProfile;
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(LeaderboardCategory category) async {
    await Future.delayed(const Duration(milliseconds: 280)); // Realistic fetch delay

    switch (category) {
      case LeaderboardCategory.globalDupr:
        return [
          const LeaderboardEntry(rank: 1, username: 'Tyson_M', title: 'Grand Slam Champion', duprRating: 5.95, metricValue: 3420, athleteId: 'marcus', paddleId: 'pro_starburst'),
          const LeaderboardEntry(rank: 2, username: 'Anna_Leigh', title: 'Apex Volley Queen', duprRating: 5.88, metricValue: 3180, athleteId: 'aria', paddleId: 'cyber_shatter'),
          const LeaderboardEntry(rank: 3, username: 'Ben_J', title: 'Baseline Maestro', duprRating: 5.82, metricValue: 2950, athleteId: 'jax', paddleId: 'titan_carbon'),
          const LeaderboardEntry(rank: 4, username: 'Elena_Vortex', title: 'Spin Specialist', duprRating: 5.25, metricValue: 2410, athleteId: 'elena', paddleId: 'ocean_splash'),
          const LeaderboardEntry(rank: 5, username: 'DinkMaster_99', title: 'Kitchen Camper', duprRating: 4.80, metricValue: 2150, athleteId: 'jax', paddleId: 'volt_strike'),
          LeaderboardEntry(rank: 18, username: _localProfile.username, title: _localProfile.title, duprRating: _localProfile.duprRating, metricValue: _localProfile.trophies, athleteId: _localProfile.equippedAthleteId, paddleId: _localProfile.equippedPaddleId, isCurrentPlayer: true),
        ];

      case LeaderboardCategory.localDivision:
        return [
          const LeaderboardEntry(rank: 1, username: 'Manila_Slammer', title: 'Tour Pro', duprRating: 4.90, metricValue: 142, athleteId: 'marcus', paddleId: 'pro_starburst'),
          const LeaderboardEntry(rank: 2, username: 'Cebu_Dinker', title: 'Speedster', duprRating: 4.65, metricValue: 128, athleteId: 'aria', paddleId: 'cyber_shatter'),
          LeaderboardEntry(rank: 3, username: _localProfile.username, title: _localProfile.title, duprRating: _localProfile.duprRating, metricValue: _localProfile.careerWins, athleteId: _localProfile.equippedAthleteId, paddleId: _localProfile.equippedPaddleId, isCurrentPlayer: true),
          const LeaderboardEntry(rank: 4, username: 'Davao_Smash', title: 'All-Rounder', duprRating: 3.85, metricValue: 24, athleteId: 'jax', paddleId: 'volt_strike'),
        ];

      case LeaderboardCategory.weeklyRallies:
        return [
          const LeaderboardEntry(rank: 1, username: 'RallyGod', title: 'Iron Wall', duprRating: 5.10, metricValue: 48, athleteId: 'elena', paddleId: 'ocean_splash'),
          const LeaderboardEntry(rank: 2, username: 'Unbroken_Chain', title: 'Patience Master', duprRating: 4.75, metricValue: 36, athleteId: 'jax', paddleId: 'titan_carbon'),
          LeaderboardEntry(rank: 6, username: _localProfile.username, title: _localProfile.title, duprRating: _localProfile.duprRating, metricValue: 22, athleteId: _localProfile.equippedAthleteId, paddleId: _localProfile.equippedPaddleId, isCurrentPlayer: true),
        ];
    }
  }

  @override
  Future<void> submitMatchResult(MatchPerformanceStats stats) async {
    _localProfile = OnlineUserProfile(
      uid: _localProfile.uid,
      username: _localProfile.username,
      title: stats.newDupr >= 4.0 ? 'Pro Tour Athlete' : _localProfile.title,
      duprRating: stats.newDupr,
      trophies: _localProfile.trophies + (stats.won ? 35 : -15),
      careerWins: _localProfile.careerWins + (stats.won ? 1 : 0),
      careerLosses: _localProfile.careerLosses + (stats.won ? 0 : 1),
      equippedAthleteId: _localProfile.equippedAthleteId,
      equippedPaddleId: _localProfile.equippedPaddleId,
    );
  }
}