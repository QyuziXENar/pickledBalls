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
// CAMPAIGN STAGE MODEL
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
    unlockRewardName: 'Titan Emerald 16mm Paddle',
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
    unlockRewardName: 'Solar Flare Pro Paddle',
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
    unlockRewardName: 'Phantom Raw T700 & Grand Slam Trophy',
  ),
];

// ============================================================================
// CHARACTER ARCHETYPES
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
    id: 'aria',
    name: 'Aria Vance',
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
// PADDLE MODELS WITH LEVEL UNLOCKS
// ============================================================================
class PaddleModel {
  final String id;
  final String name;
  final String brand;
  final Color primaryColor;
  final Color accentColor;
  final double power;
  final double control;
  final double spin;
  final int unlockLevel; // Minimum player level to equip

  const PaddleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.primaryColor,
    required this.accentColor,
    required this.power,
    required this.control,
    required this.spin,
    this.unlockLevel = 1,
  });
}

const List<PaddleModel> kPaddles = [
  PaddleModel(
    id: 'volt_strike',
    name: 'VoltStrike Carbon',
    brand: 'BLITZ LABS',
    primaryColor: Color(0xFF1B2822),
    accentColor: Color(0xFFD6F800),
    power: 0.92,
    control: 0.78,
    spin: 0.85,
    unlockLevel: 1, // Starter paddle
  ),
  PaddleModel(
    id: 'emerald_titan',
    name: 'Titan Emerald 16mm',
    brand: 'APEX TOUR',
    primaryColor: Color(0xFF0F3B2E),
    accentColor: Color(0xFF26E098),
    power: 0.80,
    control: 0.95,
    spin: 0.82,
    unlockLevel: 2,
  ),
  PaddleModel(
    id: 'solar_flare',
    name: 'Solar Flare Pro',
    brand: 'IGNITE',
    primaryColor: Color(0xFF2B1616),
    accentColor: Color(0xFFFF5722),
    power: 0.96,
    control: 0.72,
    spin: 0.90,
    unlockLevel: 3,
  ),
  PaddleModel(
    id: 'cyber_ghost',
    name: 'Phantom Raw T700',
    brand: 'MONOLITH',
    primaryColor: Color(0xFF182026),
    accentColor: Color(0xFF00D2FF),
    power: 0.86,
    control: 0.89,
    spin: 0.94,
    unlockLevel: 4,
  ),
];

// ============================================================================
// GLOBAL GAME STATE: CAREER & LEVELING ENGINE
// ============================================================================
class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  // Player Career & Leveling
  int _playerLevel = 1;
  int _playerXp = 0;
  int _xpToNextLevel = 100;
  int _careerWins = 0;
  int _careerMatches = 0;
  int _completedStages = 0;

  // Active Selections
  CharacterModel _selectedCharacter = kCharacters[0];
  CharacterModel _opponentCharacter = kCharacters[3]; // Default vs Jax
  PaddleModel _selectedPaddle = kPaddles[0];
  AIDifficulty _difficulty = AIDifficulty.pro;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  // Match Customization
  int _targetScore = 11;
  String _courtVenue = 'Tournament Arena';
  double _gamePace = 1.0;
  bool _isCampaignMatch = false;
  int _activeCampaignStageIndex = 0;

  // Getters
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

  // Award XP and handle Level Ups
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

    // Pick stage boss
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