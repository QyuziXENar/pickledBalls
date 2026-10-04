// lib/screens/gameplay/gameplay_models.dart

enum MatchPhase {
  intro,
  serveTossWait,
  serveBallInAir,
  activeRally,
  pointScored,
  gameOver,
}

enum ShotType { normal, smash, signatureBlitz, drive, lob }

class MatchBannerState {
  final String title;
  final String subtitle;
  final double duration;

  const MatchBannerState({
    required this.title,
    this.subtitle = '',
    this.duration = 1.0,
  });
}