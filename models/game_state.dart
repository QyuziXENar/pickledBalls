import 'package:flutter/material.dart';

enum AIDifficulty {
  rookie('Rookie (2.5)', 'Casual play, slow returns', 0.8),
  pro('Pro Tour (4.0)', 'Sharp kitchen dinks & drives', 1.15),
  legend('Titan (5.5+)', 'Relentless speed & pinpoint smashes', 1.45);

  final String label;
  final String description;
  final double speedMultiplier;
  const AIDifficulty(this.label, this.description, this.speedMultiplier);
}

// ============================================================================
// CAMPAIGN STAGES
// ============================================================================
class CampaignStage {
  final int stageNumber;
  final String title;
  final String subtitle;
  final String opponentId;
  final AIDifficulty difficulty;
  final int targetScore;
  final String venue;
  final int requiredPlayerLevel;
  final int xpReward;
  final String unlockRewardName;

  const CampaignStage({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.opponentId,
    required this.difficulty,
    required this.targetScore,
    required this.venue,
    required this.requiredPlayerLevel,
    required this.xpReward,
    required this.unlockRewardName,
  });
}

const List<CampaignStage> kCampaignStages = [
  CampaignStage(
    stageNumber: 1,
    title: 'Stage 1: Local Rec Park',
    subtitle: 'Warmup match against local all-rounder Jax Cooper',
    opponentId: 'jax',
    difficulty: AIDifficulty.rookie,
    targetScore: 5,
    venue: 'Sunlit Beach',
    requiredPlayerLevel: 1,
    xpReward: 120,
    unlockRewardName: 'Titan Carbon 16mm Paddle',
  ),
  CampaignStage(
    stageNumber: 2,
    title: 'Stage 2: Regional Qualifier',
    subtitle: 'Tactical duel against spin specialist Elena Cruz',
    opponentId: 'elena',
    difficulty: AIDifficulty.pro,
    targetScore: 11,
    venue: 'Tournament Arena',
    requiredPlayerLevel: 2,
    xpReward: 250,
    unlockRewardName: 'Cyber Shatter Pro Paddle',
  ),
  CampaignStage(
    stageNumber: 3,
    title: 'Stage 3: Midnight Grand Slam',
    subtitle: 'Championship final against power hitter Marcus Stone',
    opponentId: 'marcus',
    difficulty: AIDifficulty.legend,
    targetScore: 11,
    venue: 'Midnight Stadium',
    requiredPlayerLevel: 3,
    xpReward: 500,
    unlockRewardName: 'Pro Starburst & Grand Slam Trophy',
  ),
];

// ============================================================================
// CHARACTER MODELS
// ============================================================================
class CharacterModel {
  final String id;
  final String name;
  final String gender;
  final String archetype;
  final double moveSpeed;
  final double swingPower;
  final double reachFactor;
  final Color bodyColor;
  final Color accentColor;
  final String perkDescription;
  final String abilityName;
  final String abilityDesc;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.archetype,
    required this.moveSpeed,
    required this.swingPower,
    required this.reachFactor,
    required this.bodyColor,
    required this.accentColor,
    required this.perkDescription,
    required this.abilityName,
    required this.abilityDesc,
  });
}

const List<CharacterModel> kCharacters = [
  CharacterModel(
    id: 'alyx',
    name: 'Alyx Vance',
    gender: 'Female',
    archetype: 'Speedster',
    moveSpeed: 1.32,
    swingPower: 0.90,
    reachFactor: 1.00,
    bodyColor: Color(0xFF00B4D8),
    accentColor: Color(0xFF90E0EF),
    perkDescription: '+32% Sprint Speed, rapid court repositioning',
    abilityName: 'Sonic Drive',
    abilityDesc: 'Supersonic flat missile with near-instant travel time',
  ),
  CharacterModel(
    id: 'marcus',
    name: 'Marcus Stone',
    gender: 'Male',
    archetype: 'Powerhouse',
    moveSpeed: 0.92,
    swingPower: 1.36,
    reachFactor: 1.00,
    bodyColor: Color(0xFFE63946),
    accentColor: Color(0xFFFFB703),
    perkDescription: '+36% Smash & Drive kinetic exit velocity',
    abilityName: 'Meteor Smash',
    abilityDesc: 'Flaming heavy spike that crushes through defense',
  ),
  CharacterModel(
    id: 'elena',
    name: 'Elena Cruz',
    gender: 'Female',
    archetype: 'Tactician',
    moveSpeed: 1.15,
    swingPower: 1.00,
    reachFactor: 1.25,
    bodyColor: Color(0xFF7209B7),
    accentColor: Color(0xFFF72585),
    perkDescription: '+25% Larger active hit window & dive reach',
    abilityName: 'Vortex Slice',
    abilityDesc: 'Aerodynamic Magnus spin that sharply curves in air',
  ),
  CharacterModel(
    id: 'jax',
    name: 'Jax Cooper',
    gender: 'Male',
    archetype: 'All-Rounder',
    moveSpeed: 1.05,
    swingPower: 1.08,
    reachFactor: 1.05,
    bodyColor: Color(0xFF2A9D8F),
    accentColor: Color(0xFFE9C46A),
    perkDescription: 'Balanced attributes across all metrics',
    abilityName: 'Laser Beam',
    abilityDesc: 'Pinpoint baseline drive skimming millimeters over the net',
  ),
];

// ============================================================================
// EXPANDED 9 PADDLE SKINS WITH 7 DETAILED STATS (REFERENCE IMAGES 2 & 3)
// ============================================================================
class PaddleModel {
  final String id;
  final String name;
  final String brand;
  final Color primaryColor;
  final Color accentColor;
  final String skinPattern; // Visual style tag

  // 7 Detailed RPG Stats (Values from 4 to 25)
  final int statSpin;
  final int statSwing;
  final int statAgility;
  final int statAccuracy;
  final int statStamina;
  final int statPower;
  final int statSpeed;

  // Upgrade & Level State
  final int level;
  final int cardsCollected;
  final int cardsNeeded;
  final int unlockLevel;

  const PaddleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.primaryColor,
    required this.accentColor,
    required this.skinPattern,
    required this.statSpin,
    required this.statSwing,
    required this.statAgility,
    required this.statAccuracy,
    required this.statStamina,
    required this.statPower,
    required this.statSpeed,
    this.level = 1,
    this.cardsCollected = 7,
    this.cardsNeeded = 20,
    this.unlockLevel = 1,
  });

  // Normalized Multipliers for Physics Engine
  double get power => 0.70 + (statPower * 0.015);
  double get control => 0.70 + (statAccuracy * 0.015);
  double get spin => 0.65 + (statSpin * 0.018);
  double get agilityBonus => statAgility * 0.012;
}

const List<PaddleModel> kPaddles = [
  PaddleModel(
    id: 'volt_strike',
    name: 'VoltStrike Carbon',
    brand: 'BLITZ LABS',
    primaryColor: Color(0xFFFF6D00),
    accentColor: Color(0xFF00E5FF),
    skinPattern: 'lightning',
    statSpin: 18,
    statSwing: 20,
    statAgility: 8,
    statAccuracy: 12,
    statStamina: 10,
    statPower: 16,
    statSpeed: 14,
    level: 2,
    cardsCollected: 14,
    cardsNeeded: 25,
    unlockLevel: 1,
  ),
  PaddleModel(
    id: 'ocean_splash',
    name: 'Ocean Splash Wave',
    brand: 'AQUA TOUR',
    primaryColor: Color(0xFF0277BD),
    accentColor: Color(0xFF4FC3F7),
    skinPattern: 'splash',
    statSpin: 20,
    statSwing: 16,
    statAgility: 10,
    statAccuracy: 18,
    statStamina: 12,
    statPower: 10,
    statSpeed: 12,
    level: 1,
    cardsCollected: 8,
    cardsNeeded: 15,
    unlockLevel: 1,
  ),
  PaddleModel(
    id: 'titan_carbon',
    name: 'Titan Carbon Weave',
    brand: 'APEX PRO',
    primaryColor: Color(0xFF1B5E20),
    accentColor: Color(0xFF69F0AE),
    skinPattern: 'carbon',
    statSpin: 14,
    statSwing: 14,
    statAgility: 12,
    statAccuracy: 22,
    statStamina: 16,
    statPower: 14,
    statSpeed: 12,
    level: 2,
    cardsCollected: 21,
    cardsNeeded: 30,
    unlockLevel: 2,
  ),
  PaddleModel(
    id: 'cyber_shatter',
    name: 'Cyber Shatter Neon',
    brand: 'MONOLITH',
    primaryColor: Color(0xFF0D47A1),
    accentColor: Color(0xFFEEFF41),
    skinPattern: 'cyber',
    statSpin: 22,
    statSwing: 18,
    statAgility: 10,
    statAccuracy: 14,
    statStamina: 14,
    statPower: 18,
    statSpeed: 16,
    level: 1,
    cardsCollected: 4,
    cardsNeeded: 20,
    unlockLevel: 2,
  ),
  PaddleModel(
    id: 'street_graffiti',
    name: 'Street Stencil 90',
    brand: 'URBAN BLITZ',
    primaryColor: Color(0xFFD50000),
    accentColor: Color(0xFF00E5FF),
    skinPattern: 'graffiti',
    statSpin: 16,
    statSwing: 22,
    statAgility: 14,
    statAccuracy: 10,
    statStamina: 10,
    statPower: 20,
    statSpeed: 18,
    level: 1,
    cardsCollected: 3,
    cardsNeeded: 20,
    unlockLevel: 2,
  ),
  PaddleModel(
    id: 'glacier_crack',
    name: 'Glacier Crystalline',
    brand: 'FROST LABS',
    primaryColor: Color(0xFF01579B),
    accentColor: Color(0xFFB3E5FC),
    skinPattern: 'glacier',
    statSpin: 20,
    statSwing: 16,
    statAgility: 8,
    statAccuracy: 20,
    statStamina: 16,
    statPower: 12,
    statSpeed: 10,
    level: 1,
    cardsCollected: 5,
    cardsNeeded: 25,
    unlockLevel: 3,
  ),
  PaddleModel(
    id: 'retro_target',
    name: 'Retro Bullseye 70s',
    brand: 'VINTAGE',
    primaryColor: Color(0xFFC62828),
    accentColor: Color(0xFFFFB300),
    skinPattern: 'target',
    statSpin: 12,
    statSwing: 14,
    statAgility: 10,
    statAccuracy: 16,
    statStamina: 20,
    statPower: 16,
    statSpeed: 14,
    level: 1,
    cardsCollected: 2,
    cardsNeeded: 25,
    unlockLevel: 3,
  ),
  PaddleModel(
    id: 'sunburst_stripe',
    name: 'Sunburst Surf Band',
    brand: 'COASTAL',
    primaryColor: Color(0xFFE65100),
    accentColor: Color(0xFF40C4FF),
    skinPattern: 'stripes',
    statSpin: 16,
    statSwing: 18,
    statAgility: 16,
    statAccuracy: 16,
    statStamina: 14,
    statPower: 14,
    statSpeed: 16,
    level: 1,
    cardsCollected: 6,
    cardsNeeded: 30,
    unlockLevel: 3,
  ),
  PaddleModel(
    id: 'pro_starburst',
    name: 'Grand Slam Starburst',
    brand: 'CHAMPION',
    primaryColor: Color(0xFF1A237E),
    accentColor: Color(0xFF00E5FF),
    skinPattern: 'starburst',
    statSpin: 24,
    statSwing: 22,
    statAgility: 16,
    statAccuracy: 22,
    statStamina: 20,
    statPower: 24,
    statSpeed: 22,
    level: 3,
    cardsCollected: 45,
    cardsNeeded: 45,
    unlockLevel: 4,
  ),
];

// ============================================================================
// GLOBAL GAME STATE
// ============================================================================
class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  int _playerLevel = 1;
  int _playerXp = 0;
  int _xpToNextLevel = 100;
  int _careerWins = 0;
  int _careerMatches = 0;
  int _completedStages = 0;

  CharacterModel _selectedCharacter = kCharacters[0];
  CharacterModel _opponentCharacter = kCharacters[3];
  PaddleModel _selectedPaddle = kPaddles[0];
  AIDifficulty _difficulty = AIDifficulty.pro;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  int _targetScore = 11;
  String _courtVenue = 'Tournament Arena';
  double _gamePace = 1.0;
  bool _isCampaignMatch = false;
  int _activeCampaignStageIndex = 0;

  int get playerLevel => _playerLevel;
  int get playerXp => _playerXp;
  int get xpToNextLevel => _xpToNextLevel;
  double get xpProgress => (_playerXp / _xpToNextLevel).clamp(0.0, 1.0);
  int get careerWins => _careerWins;
  int get careerMatches => _careerMatches;
  int get completedStages => _completedStages;

  CharacterModel get selectedCharacter => _selectedCharacter;
  CharacterModel get opponentCharacter => _opponentCharacter;
  PaddleModel get selectedPaddle => _selectedPaddle;
  AIDifficulty get difficulty => _difficulty;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  int get targetScore => _targetScore;
  String get courtVenue => _courtVenue;
  String get courtTheme => _courtVenue;
  double get gamePace => _gamePace;
  bool get isCampaignMatch => _isCampaignMatch;
  int get activeCampaignStageIndex => _activeCampaignStageIndex;

  void addMatchExperience({
    required bool wonMatch,
    required int rallyHits,
    required int smashes,
  }) {
    _careerMatches++;
    if (wonMatch) _careerWins++;

    int earnedXp = (wonMatch ? 80 : 30) + (rallyHits * 4) + (smashes * 10);

    if (_isCampaignMatch && wonMatch) {
      final stage = kCampaignStages[_activeCampaignStageIndex];
      earnedXp += stage.xpReward;
      if (_completedStages <= _activeCampaignStageIndex) {
        _completedStages = _activeCampaignStageIndex + 1;
      }
    }

    _playerXp += earnedXp;

    while (_playerXp >= _xpToNextLevel) {
      _playerXp -= _xpToNextLevel;
      _playerLevel++;
      _xpToNextLevel = (_xpToNextLevel * 1.5).round();
    }

    notifyListeners();
  }

  void startCampaignStage(int stageIndex) {
    final stage = kCampaignStages[stageIndex];
    _isCampaignMatch = true;
    _activeCampaignStageIndex = stageIndex;
    _targetScore = stage.targetScore;
    _courtVenue = stage.venue;
    _difficulty = stage.difficulty;

    _opponentCharacter = kCharacters.firstWhere(
      (c) => c.id == stage.opponentId,
      orElse: () => kCharacters[1],
    );
    notifyListeners();
  }

  void startExhibitionMatch() {
    _isCampaignMatch = false;
    notifyListeners();
  }

  void selectCharacter(CharacterModel character) {
    _selectedCharacter = character;
    notifyListeners();
  }

  void selectPaddle(PaddleModel paddle) {
    if (paddle.unlockLevel <= _playerLevel) {
      _selectedPaddle = paddle;
      notifyListeners();
    }
  }

  void setDifficulty(AIDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  void toggleSound(bool val) {
    _soundEnabled = val;
    notifyListeners();
  }

  void toggleHaptics(bool val) {
    _hapticsEnabled = val;
    notifyListeners();
  }

  void setTargetScore(int score) {
    _targetScore = score;
    notifyListeners();
  }

  void setCourtVenue(String venue) {
    _courtVenue = venue;
    notifyListeners();
  }

  void setCourtTheme(String theme) => setCourtVenue(theme);

  void setGamePace(double pace) {
    _gamePace = pace;
    notifyListeners();
  }
}