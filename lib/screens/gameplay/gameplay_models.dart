// lib/screens/gameplay/gameplay_models.dart

enum MatchPhase {
  cinematicSplash, // Stage 1: Player VS Opponent Card Reveal
  countdown,       // Stage 2: 3... 2... 1... SERVE!
  repositioning,   // Stage 3: Automated glide to regulation service boxes
  serveTossWait,   // Stage 4: Ball tethered in hand, waiting for toss
  serveBallInAir,  // Stage 5: Ball descending toward below-waist strike window
  activeRally,     // Stage 6: Live rally in play
  pointScored,     // Fast 1.4s point beat (toast + loss stumble, zero freeze)
  gameOver,
}

enum ShotType { normal, smash, signatureBlitz, drive, lob }

enum AiCourtZone { kitchen, transition, baseline }