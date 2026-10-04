// lib/core/constants/app_assets.dart

enum SpriteView { front, back }

enum SpriteAction { idle, walk, serve, hit, defend, loss }

class AppAssets {
  // ==========================================================================
  // 1. LOGOS & ICONS
  // ==========================================================================
  static const String logoCanzed = 'lib/assets/images/logos/canzed_logo.png';
  static const String logoGame = 'lib/assets/images/logos/game_logo.png';
  static const String logoXccr = 'lib/assets/images/logos/xccr_logo.png';
  static const String appIcon = 'lib/assets/images/logos/game_logo.png';
  static const String arenaDiorama = 'lib/assets/images/backgrounds/arena_diorama.png';

  // ==========================================================================
  // 2. MUSIC SOUNDTRACK
  // ==========================================================================
  static const String musicBattleStart = 'lib/assets/sounds/music/battle_start.mp3';
  static const String musicCanzedIntro = 'lib/assets/sounds/music/canzed_intro.mp3';
  static const String musicXccrIntro = 'lib/assets/sounds/music/xccr_intro.mp3';

  // ==========================================================================
  // 3. SOUND EFFECTS (SFX)
  // ==========================================================================
  static const String sfxBattleStart = 'lib/assets/sounds/music/battle_start.mp3';
  static const String sfxBallBounce = 'lib/assets/sounds/sfx/ball_bounce.mp3';
  static const String sfxBlitzSuper = 'lib/assets/sounds/sfx/blitz_super.mp3';
  static const String sfxCanzedIntro = 'lib/assets/sounds/sfx/canzed_intro.mp3';
  static const String sfxClick = 'lib/assets/sounds/sfx/click.mp3';
  static const String sfxError = 'lib/assets/sounds/sfx/error.mp3';
  static const String sfxFaultBuzzer = 'lib/assets/sounds/sfx/fault_buzzer.mp3';
  static const String sfxMatchLose = 'lib/assets/sounds/sfx/match_lose.mp3';
  static const String sfxMatchWinner = 'lib/assets/sounds/sfx/match_winner.mp3';
  static const String sfxPaddleDrive = 'lib/assets/sounds/sfx/paddle_drive.mp3';
  static const String sfxPaddleSmash = 'lib/assets/sounds/sfx/paddle_smash.mp3';
  static const String sfxPointCheer = 'lib/assets/sounds/sfx/point_cheer.mp3';
  static const String sfxRoundLose = 'lib/assets/sounds/sfx/round_lose.mp3';
  static const String sfxRoundWinner = 'lib/assets/sounds/sfx/round_winner.mp3';
  static const String sfxSwipe = 'lib/assets/sounds/sfx/swipe.mp3';
  static const String sfxXccrIntro = 'lib/assets/sounds/sfx/xccr_intro.mp3';

  // Gameplay FOLEY Aliases (with safe fallback mapping)
  static const String sfxShoeSqueak = 'lib/assets/sounds/sfx/click.mp3';
  static const String sfxNetCord = 'lib/assets/sounds/sfx/fault_buzzer.mp3';
  static const String sfxOutOfBounds = 'lib/assets/sounds/sfx/fault_buzzer.mp3';
  static const String sfxDinkPop = 'lib/assets/sounds/sfx/paddle_drive.mp3';
  static const String sfxPlayerDive = 'lib/assets/sounds/sfx/swipe.mp3';
  static const String sfxReticleLock = 'lib/assets/sounds/sfx/click.mp3';
  static const String sfxServeToss = 'lib/assets/sounds/sfx/swipe.mp3';
  static const String sfxServeDrive = 'lib/assets/sounds/sfx/paddle_drive.mp3';
  static const String sfxServeLob = 'lib/assets/sounds/sfx/paddle_drive.mp3';
  static const String sfxRallyStreak = 'lib/assets/sounds/sfx/point_cheer.mp3';
  static const String sfxKitchenFault = 'lib/assets/sounds/sfx/fault_buzzer.mp3';
  static const String sfxCardTap = 'lib/assets/sounds/sfx/click.mp3';
  static const String sfxPaddleEquip = 'lib/assets/sounds/sfx/click.mp3';
  static const String sfxTabSwipe = 'lib/assets/sounds/sfx/swipe.mp3';
  static const String sfxCharacterSelect = 'lib/assets/sounds/sfx/click.mp3';

  // ==========================================================================
  // 4. 192-FRAME SPRITE TAXONOMY RESOLVER
  // ==========================================================================
  static String getCharacterFrame(
    String charId,
    SpriteView view,
    SpriteAction action,
    int frameIndex,
  ) {
    final cleanId = charId.toLowerCase();
    final viewStr = view == SpriteView.front ? 'front' : 'back';
    final actionStr = action.name;
    final frameStr = frameIndex.toString().padLeft(2, '0');

    return 'lib/assets/images/characters/$cleanId/${cleanId}_${viewStr}_${actionStr}_$frameStr.png';
  }

  static String? getLegacyPlaceholderKey(String charId, SpriteAction action, int frameIndex) {
    String spriteName = charId.toUpperCase();
    if (charId == 'aria') spriteName = 'FEMALE';
    if (charId == 'marcus') spriteName = 'MALE';

    String frameName = 'frame_0_ready';
    if (action == SpriteAction.hit) {
      if (frameIndex == 1) {
        frameName = 'frame_1_backswing';
      } else if (frameIndex == 2) {
        frameName = 'frame_2_contact';
      } else {
        frameName = 'frame_3_followthrough';
      }
    }

    return '${frameName}_$spriteName';
  }

  static List<String> getAllSpritePaths() {
    const characters = ['aria', 'elena', 'jax', 'marcus'];
    const views = [SpriteView.front, SpriteView.back];
    const actions = SpriteAction.values;
    final List<String> paths = [];

    for (final char in characters) {
      for (final view in views) {
        for (final action in actions) {
          for (int frame = 1; frame <= 4; frame++) {
            paths.add(getCharacterFrame(char, view, action, frame));
          }
        }
      }
    }
    return paths;
  }
}