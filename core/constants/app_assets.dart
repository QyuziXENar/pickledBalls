// lib/core/constants/app_assets.dart

/// Enum representing the 2.5D billboard camera perspective view.
enum SpriteView {
  front,
  back,
}

typedef CharacterView = SpriteView;

/// Enum representing the 6 distinct 4-frame animation states.
enum SpriteAction {
  idle,
  walk,
  serve,
  hit,
  defend,
  loss,
}

typedef CharacterAction = SpriteAction;

/// Centralized, type-safe asset catalog for Paddle Blitz 3.0.
class AppAssets {
  AppAssets._();

  // ==========================================================================
  // 1. BRAND & ENGINE LOGOS (XCCR & Canzed Dual Compatibility)
  // ==========================================================================
  static const String logoXccr = 'lib/assets/images/logos/xccr_logo.png';
  static const String logoCanzed = 'lib/assets/images/logos/canzed_logo.png';
  static const String logoGame = 'lib/assets/images/logos/game_logo.png';

  // ==========================================================================
  // 2. PILLAR 7 EXHAUSTIVE SFX CATALOG (Every In-Game Event Has a Constant)
  // ==========================================================================
  static const String sfxFolder = 'lib/assets/sounds/sfx/';

  // Serve & Fault Hooks
  static const String sfxServeToss = 'serve_toss.mp3';
  static const String sfxReticleLock = 'reticle_lock.mp3';
  static const String sfxServeDrive = 'serve_drive.mp3';
  static const String sfxServeLob = 'serve_lob.mp3';
  static const String sfxFaultBuzzer = 'fault_buzzer.mp3';
  static const String sfxOutOfBounds = 'out_of_bounds.mp3';
  static const String sfxKitchenFault = 'kitchen_fault.mp3';

  // Ball & Paddle Contact Foley
  static const String sfxPaddleDrive = 'paddle_drive.mp3';
  static const String sfxPaddleSmash = 'paddle_smash.mp3';
  static const String sfxDinkPop = 'dink_pop.mp3';
  static const String sfxBlitzSuper = 'blitz_super.mp3';
  static const String sfxBallBounce = 'ball_bounce.mp3';
  static const String sfxNetCord = 'net_cord.mp3';
  static const String sfxPlayerDive = 'player_dive.mp3';
  static const String sfxShoeSqueak = 'shoe_squeak.mp3';

  // Atmosphere, Rallies & Match Scoring
  static const String sfxPointCheer = 'point_cheer.mp3';
  static const String sfxRoundLose = 'round_lose.mp3';
  static const String sfxRallyStreak = 'rally_streak.mp3';
  static const String sfxMatchWinner = 'match_winner.mp3';
  static const String sfxMatchWin = sfxMatchWinner;
  static const String sfxMatchLose = 'match_lose.mp3';
  static const String sfxCrowdGroan = 'crowd_groan.mp3';
  static const String sfxRoundWinner = 'round_winner.mp3';

  // Menu, Pro Shop & RPG Upgrades
  static const String sfxClick = 'click.mp3';
  static const String sfxSwipe = 'swipe.mp3';
  static const String sfxTabSwipe = 'tab_swipe.mp3';
  static const String sfxCardTap = 'card_tap.mp3';
  static const String sfxCharacterSelect = 'character_select.mp3';
  static const String sfxPaddleEquip = 'equip.mp3';
  static const String sfxStatUpgrade = 'stat_upgrade.mp3';
  static const String sfxStatReset = 'stat_reset.mp3';
  static const String sfxCrateOpen = 'crate_open.mp3';
  static const String sfxRewardReveal = 'reward_reveal.mp3';
  static const String sfxError = 'error.mp3';
  static const String sfxBeep = 'beep.mp3';

  // ==========================================================================
  // 3. MUSIC & INTROS
  // ==========================================================================
  static const String musicFolder = 'lib/assets/sounds/music/';

  static const String musicXccrIntro = 'xccr_intro.mp3';
  static const String musicCanzedIntro = 'canzed_intro.mp3';
  static const String musicClashJingle = 'clash_start_jingle.mp3';
  static const String musicBattleStart = 'battle_start.mp3';

  // ==========================================================================
  // 4. ATHLETES & 192-FRAME SPRITE TAXONOMY
  // ==========================================================================
  static const String athleteAria = 'aria';
  static const String athleteMarcus = 'marcus';
  static const String athleteElena = 'elena';
  static const String athleteJax = 'jax';

  static const List<String> allAthletes = [
    athleteAria,
    athleteMarcus,
    athleteElena,
    athleteJax,
  ];

  static const String spriteBasePath = 'lib/assets/images/characters';

  /// Primary helper: looks up any frame path using strings or enums.
  /// Format: `lib/assets/images/characters/{char_id}/{char_id}_{view}_{action}_{frame}.png`
  static String getCharacterFrame(
    String charId,
    dynamic view,
    dynamic action,
    dynamic frameNumber,
  ) {
    final viewStr = view is SpriteView ? view.name : view.toString().toLowerCase();
    final actionStr = action is SpriteAction ? action.name : action.toString().toLowerCase();

    final int frameInt = frameNumber is int
        ? frameNumber
        : int.tryParse(frameNumber.toString()) ?? 1;
    final frameStr = frameInt.clamp(1, 4).toString().padLeft(2, '0');

    return '$spriteBasePath/$charId/${charId}_${viewStr}_${actionStr}_$frameStr.png';
  }

  static String characterSprite({
    required String characterId,
    required dynamic view,
    required dynamic action,
    required dynamic frame,
  }) {
    return getCharacterFrame(characterId, view, action, frame);
  }

  static String playerFrame(String charId, SpriteAction action, int frame) {
    return getCharacterFrame(charId, SpriteView.back, action, frame);
  }

  static String opponentFrame(String charId, SpriteAction action, int frame) {
    return getCharacterFrame(charId, SpriteView.front, action, frame);
  }

  /// Asset Bridge Helper: Maps to placeholder PNGs if sliced frames are not yet on disk
  static String? getLegacyPlaceholderKey(String charId, SpriteAction action, int frameIndex) {
    String legacyId = charId.toUpperCase();
    if (charId == 'aria') legacyId = 'FEMALE';
    if (charId == 'marcus') legacyId = 'MALE';

    if (legacyId != 'FEMALE' && legacyId != 'MALE') return null;

    String legacyFrame = 'frame_0_ready';
    if (action == SpriteAction.hit) {
      if (frameIndex == 1) legacyFrame = 'frame_1_backswing';
      if (frameIndex == 2) legacyFrame = 'frame_2_contact';
      if (frameIndex >= 3) legacyFrame = 'frame_3_followthrough';
    }
    return '${legacyFrame}_$legacyId';
  }

  /// Full manifest of all 192 individual frame asset paths
  static List<String> getAllSpritePaths() {
    final List<String> paths = [];
    for (final charId in allAthletes) {
      for (final view in SpriteView.values) {
        for (final action in SpriteAction.values) {
          for (int f = 1; f <= 4; f++) {
            paths.add(getCharacterFrame(charId, view, action, f));
          }
        }
      }
    }
    return paths;
  }
}