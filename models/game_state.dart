// lib/models/game_state.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';

// ============================================================================
// ENUMS & CONFIGURATIONS
// ============================================================================

enum AIDifficulty {
  rookie('Rookie (2.5)', 'Casual play, slow returns', 0.8),
  pro('Pro Tour (4.0)', 'Sharp kitchen dinks & drives', 1.15),
  legend('Titan (5.5+)', 'Relentless speed & pinpoint smashes', 1.45);

  final String label;
  final String description;
  final double speedMultiplier;
  const AIDifficulty(this.label, this.description, this.speedMultiplier);
}

enum PaddleStatType { power, control, spin, agility }

// ============================================================================
// CAMPAIGN STAGE MODEL (100% 2.0 UI Compatibility)
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
  final int coinReward;

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
    this.coinReward = 250,
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
    unlockRewardName: 'Titan Weave 16mm Paddle',
    coinReward: 250,
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
    coinReward: 500,
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
    coinReward: 1000,
  ),
];

// ============================================================================
// CHARACTER MODEL (Re-tuned Grounded Athletic Movement Speeds)
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
  // Aria Vance (Speedster) - Re-tuned to realistic grounded movement
  CharacterModel(
    id: 'aria',
    name: 'Aria Vance',
    gender: 'Female',
    archetype: 'Speedster',
    moveSpeed: 1.20,
    swingPower: 0.90,
    reachFactor: 1.00,
    bodyColor: AppColors.ariaBody,
    accentColor: AppColors.ariaAccent,
    perkDescription: '+20% Sprint Speed, rapid court repositioning',
    abilityName: 'Sonic Drive',
    abilityDesc: 'Supersonic flat missile with near-instant travel time',
  ),

  // Marcus Stone (Powerhouse)
  CharacterModel(
    id: 'marcus',
    name: 'Marcus Stone',
    gender: 'Male',
    archetype: 'Powerhouse',
    moveSpeed: 0.90,
    swingPower: 1.35,
    reachFactor: 1.00,
    bodyColor: AppColors.marcusBody,
    accentColor: AppColors.marcusAccent,
    perkDescription: '+35% Smash & Drive kinetic exit velocity',
    abilityName: 'Meteor Spike',
    abilityDesc: 'Flaming heavy spike that crushes through defense',
  ),

  // Elena Cruz (Tactician)
  CharacterModel(
    id: 'elena',
    name: 'Elena Cruz',
    gender: 'Female',
    archetype: 'Tactician',
    moveSpeed: 1.05,
    swingPower: 1.00,
    reachFactor: 1.25,
    bodyColor: AppColors.elenaBody,
    accentColor: AppColors.elenaAccent,
    perkDescription: '+25% Active strike reach & kitchen diving',
    abilityName: 'Vortex Curve',
    abilityDesc: 'Aerodynamic Magnus slice that sharply curves in air',
  ),

  // Jax Cooper (All-Rounder)
  CharacterModel(
    id: 'jax',
    name: 'Jax Cooper',
    gender: 'Male',
    archetype: 'All-Rounder',
    moveSpeed: 1.00,
    swingPower: 1.05,
    reachFactor: 1.08,
    bodyColor: AppColors.jaxBody,
    accentColor: AppColors.jaxAccent,
    perkDescription: 'Balanced attributes with +15% control consistency',
    abilityName: 'Laser Dink',
    abilityDesc: 'Pinpoint precision dink skimming millimeters over the tape',
  ),
];

// ============================================================================
// PADDLE MODEL (Streamlined 4 + 2 Prototypes, 100% 2.0 Stat Compatibility)
// ============================================================================
class PaddleModel {
  final String id;
  final String name;
  final String brand;
  final Color primaryColor;
  final Color accentColor;
  final String skinPattern;

  // 2.0 Legacy Stat Fields (Retained so all existing stat rows/meters compile)
  final int statSpin;
  final int statSwing;
  final int statAgility;
  final int statAccuracy;
  final int statStamina;
  final int statPower;
  final int statSpeed;

  final int level;
  final int cardsCollected;
  final int cardsNeeded;
  final int unlockLevel;
  final bool isPrototype;

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
    this.cardsCollected = 10,
    this.cardsNeeded = 20,
    required this.unlockLevel,
    this.isPrototype = false,
  });

  // 3.0 RPG Base Stat Aliases
  int get basePower => statPower;
  int get baseControl => statAccuracy;
  int get baseSpin => statSpin;
  int get baseAgility => statAgility;

  // 2.0 Multipliers
  double get power => 0.70 + (statPower * 0.015);
  double get control => 0.70 + (statAccuracy * 0.015);
  double get spin => 0.65 + (statSpin * 0.018);
  double get agilityBonus => statAgility * 0.012;

  // 3.0 Dynamic Multipliers (Base Stat + Allocated UP Bonus)
  double computePower(int bonus) => 0.70 + ((basePower + bonus) * 0.018);
  double computeControl(int bonus) => 0.70 + ((baseControl + bonus) * 0.016);
  double computeSpin(int bonus) => 0.65 + ((baseSpin + bonus) * 0.020);
  double computeAgility(int bonus) => (baseAgility + bonus) * 0.014;
}

const List<PaddleModel> kPaddles = [
  // 1. Starter (Level 1 Unlock)
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
    level: 1,
    cardsCollected: 14,
    cardsNeeded: 25,
    unlockLevel: 1,
  ),

  // 2. Titan Carbon (Level 3 Unlock)
  PaddleModel(
    id: 'titan_carbon',
    name: 'Titan Weave 16mm',
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
    unlockLevel: 3,
  ),

  // 3. Cyber Shatter (Level 6 Unlock)
  PaddleModel(
    id: 'cyber_shatter',
    name: 'Cyber Shatter Pro',
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
    unlockLevel: 6,
  ),

  // 4. Grand Slam Starburst (Level 10 Unlock)
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
    unlockLevel: 10,
  ),

  // 5. Mystery Prototype Alpha (Locked, Coming Soon in v3.1)
  PaddleModel(
    id: 'classified_alpha',
    name: 'AeroVortex X-1',
    brand: 'CLASSIFIED LABS',
    primaryColor: Color(0xFF263238),
    accentColor: Color(0xFF76FF03),
    skinPattern: 'prototype',
    statSpin: 25,
    statSwing: 24,
    statAgility: 20,
    statAccuracy: 22,
    statStamina: 20,
    statPower: 24,
    statSpeed: 24,
    level: 1,
    cardsCollected: 0,
    cardsNeeded: 100,
    unlockLevel: 999,
    isPrototype: true,
  ),

  // 6. Mystery Prototype Beta (Locked, Coming Soon in v3.1)
  PaddleModel(
    id: 'classified_beta',
    name: 'Quantum Core 00',
    brand: 'CLASSIFIED LABS',
    primaryColor: Color(0xFF212121),
    accentColor: Color(0xFFE040FB),
    skinPattern: 'quantum',
    statSpin: 24,
    statSwing: 25,
    statAgility: 22,
    statAccuracy: 25,
    statStamina: 24,
    statPower: 25,
    statSpeed: 25,
    level: 1,
    cardsCollected: 0,
    cardsNeeded: 100,
    unlockLevel: 999,
    isPrototype: true,
  ),
];

// ============================================================================
// PADDLE STAT ALLOCATION RECORD
// ============================================================================
class PaddleStatAllocation {
  int power;
  int control;
  int spin;
  int agility;

  PaddleStatAllocation({
    this.power = 0,
    this.control = 0,
    this.spin = 0,
    this.agility = 0,
  });

  int get totalAllocated => power + control + spin + agility;

  Map<String, int> toMap() => {
    'power': power,
    'control': control,
    'spin': spin,
    'agility': agility,
  };

  factory PaddleStatAllocation.fromMap(Map<String, dynamic> map) {
    return PaddleStatAllocation(
      power: (map['power'] as num?)?.toInt() ?? 0,
      control: (map['control'] as num?)?.toInt() ?? 0,
      spin: (map['spin'] as num?)?.toInt() ?? 0,
      agility: (map['agility'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================================
// GAME STATE SINGLETON (Tri-Currency Wallets & RPG Progression)
// ============================================================================
class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  // Storage Persistence Keys
  static const String _kLevel = 'pb_v3_player_level';
  static const String _kXp = 'pb_v3_player_xp';
  static const String _kNextXp = 'pb_v3_xp_to_next';
  static const String _kGoldCoins = 'pb_v3_gold_coins';
  static const String _kDiamonds = 'pb_v3_diamonds';
  static const String _kUpgradePoints = 'pb_v3_upgrade_points';
  static const String _kWins = 'pb_v3_career_wins';
  static const String _kMatches = 'pb_v3_career_matches';
  static const String _kStages = 'pb_v3_completed_stages';
  static const String _kCharId = 'pb_v3_selected_char_id';
  static const String _kPaddleId = 'pb_v3_selected_paddle_id';
  static const String _kAllocations = 'pb_v3_paddle_allocations';
  static const String _kSound = 'pb_v3_sound_enabled';
  static const String _kHaptics = 'pb_v3_haptics_enabled';
  static const String _kShake = 'pb_v3_shake_enabled';
  static const String _kVenue = 'pb_v3_court_venue';
  static const String _kTargetScore = 'pb_v3_target_score';
  static const String _kPace = 'pb_v3_game_pace';

  // Tri-Currency Wallets
  int _goldCoins = 1450;
  int _diamonds = 40;
  int _upgradePoints = 3;

  // Level Progression
  int _playerLevel = 1;
  int _playerXp = 0;
  int _xpToNextLevel = 100;
  int _careerWins = 0;
  int _careerMatches = 0;
  int _completedStages = 0;

  // Active Selections
  CharacterModel _selectedCharacter = kCharacters[0];
  CharacterModel _opponentCharacter = kCharacters[3];
  PaddleModel _selectedPaddle = kPaddles[0];

  // RPG Stat Point Allocations per paddle
  final Map<String, PaddleStatAllocation> _paddleAllocations = {
    'volt_strike': PaddleStatAllocation(),
    'titan_carbon': PaddleStatAllocation(),
    'cyber_shatter': PaddleStatAllocation(),
    'pro_starburst': PaddleStatAllocation(),
  };

  // Match Preferences & Configs
  AIDifficulty _difficulty = AIDifficulty.pro;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _screenShakeEnabled = true;
  int _targetScore = 11;
  String _courtVenue = 'Tournament Arena';
  double _gamePace = 1.0;
  bool _isCampaignMatch = false;
  int _activeCampaignStageIndex = 0;

  // --------------------------------------------------------------------------
  // GETTERS
  // --------------------------------------------------------------------------
  int get goldCoins => _goldCoins;
  int get diamonds => _diamonds;
  int get upgradePoints => _upgradePoints;

  // Convenience aliases for existing 2.0 UI
  int get coins => _goldCoins;
  int get gems => _diamonds;

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
  bool get screenShakeEnabled => _screenShakeEnabled;
  int get targetScore => _targetScore;
  String get courtVenue => _courtVenue;
  double get gamePace => _gamePace;
  bool get isCampaignMatch => _isCampaignMatch;
  int get activeCampaignStageIndex => _activeCampaignStageIndex;

  // Effective Paddle Multipliers
  double get effectivePaddlePower {
    final bonus = _paddleAllocations[_selectedPaddle.id]?.power ?? 0;
    return _selectedPaddle.computePower(bonus);
  }

  double get effectivePaddleControl {
    final bonus = _paddleAllocations[_selectedPaddle.id]?.control ?? 0;
    return _selectedPaddle.computeControl(bonus);
  }

  double get effectivePaddleSpin {
    final bonus = _paddleAllocations[_selectedPaddle.id]?.spin ?? 0;
    return _selectedPaddle.computeSpin(bonus);
  }

  double get effectivePaddleAgility {
    final bonus = _paddleAllocations[_selectedPaddle.id]?.agility ?? 0;
    return _selectedPaddle.computeAgility(bonus);
  }

  PaddleStatAllocation getAllocation(String paddleId) {
    return _paddleAllocations.putIfAbsent(paddleId, () => PaddleStatAllocation());
  }

  // --------------------------------------------------------------------------
  // DISK PERSISTENCE (SharedPreferences)
  // --------------------------------------------------------------------------
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _playerLevel = prefs.getInt(_kLevel) ?? 1;
      _playerXp = prefs.getInt(_kXp) ?? 0;
      _xpToNextLevel = prefs.getInt(_kNextXp) ?? 100;
      _goldCoins = prefs.getInt(_kGoldCoins) ?? 1450;
      _diamonds = prefs.getInt(_kDiamonds) ?? 40;
      _upgradePoints = prefs.getInt(_kUpgradePoints) ?? 3;
      _careerWins = prefs.getInt(_kWins) ?? 0;
      _careerMatches = prefs.getInt(_kMatches) ?? 0;
      _completedStages = prefs.getInt(_kStages) ?? 0;

      final savedCharId = prefs.getString(_kCharId);
      if (savedCharId != null) {
        _selectedCharacter = kCharacters.firstWhere(
          (c) => c.id == savedCharId,
          orElse: () => kCharacters[0],
        );
      }

      final savedPaddleId = prefs.getString(_kPaddleId);
      if (savedPaddleId != null) {
        _selectedPaddle = kPaddles.firstWhere(
          (p) => p.id == savedPaddleId,
          orElse: () => kPaddles[0],
        );
      }

      final allocJson = prefs.getString(_kAllocations);
      if (allocJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(allocJson);
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            _paddleAllocations[key] = PaddleStatAllocation.fromMap(val);
          }
        });
      }

      _soundEnabled = prefs.getBool(_kSound) ?? true;
      _hapticsEnabled = prefs.getBool(_kHaptics) ?? true;
      _screenShakeEnabled = prefs.getBool(_kShake) ?? true;
      _courtVenue = prefs.getString(_kVenue) ?? 'Tournament Arena';
      _targetScore = prefs.getInt(_kTargetScore) ?? 11;
      _gamePace = prefs.getDouble(_kPace) ?? 1.0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved GameState: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLevel, _playerLevel);
      await prefs.setInt(_kXp, _playerXp);
      await prefs.setInt(_kNextXp, _xpToNextLevel);
      await prefs.setInt(_kGoldCoins, _goldCoins);
      await prefs.setInt(_kDiamonds, _diamonds);
      await prefs.setInt(_kUpgradePoints, _upgradePoints);
      await prefs.setInt(_kWins, _careerWins);
      await prefs.setInt(_kMatches, _careerMatches);
      await prefs.setInt(_kStages, _completedStages);

      await prefs.setString(_kCharId, _selectedCharacter.id);
      await prefs.setString(_kPaddleId, _selectedPaddle.id);

      final Map<String, dynamic> rawAlloc = {};
      _paddleAllocations.forEach((k, v) => rawAlloc[k] = v.toMap());
      await prefs.setString(_kAllocations, jsonEncode(rawAlloc));

      await prefs.setBool(_kSound, _soundEnabled);
      await prefs.setBool(_kHaptics, _hapticsEnabled);
      await prefs.setBool(_kShake, _screenShakeEnabled);
      await prefs.setString(_kVenue, _courtVenue);
      await prefs.setInt(_kTargetScore, _targetScore);
      await prefs.setDouble(_kPace, _gamePace);
    } catch (e) {
      debugPrint('Error saving GameState to disk: $e');
    }
  }

  // --------------------------------------------------------------------------
  // TRI-CURRENCY WALLET MUTATIONS
  // --------------------------------------------------------------------------
  void addGoldCoins(int amount) {
    if (amount <= 0) return;
    _goldCoins += amount;
    notifyListeners();
    _saveToStorage();
  }

  bool spendGoldCoins(int amount) {
    if (_goldCoins < amount) return false;
    _goldCoins -= amount;
    notifyListeners();
    _saveToStorage();
    return true;
  }

  void addDiamonds(int amount) {
    if (amount <= 0) return;
    _diamonds += amount;
    notifyListeners();
    _saveToStorage();
  }

  bool spendDiamonds(int amount) {
    if (_diamonds < amount) return false;
    _diamonds -= amount;
    notifyListeners();
    _saveToStorage();
    return true;
  }

  void addUpgradePoints(int amount) {
    if (amount <= 0) return;
    _upgradePoints += amount;
    notifyListeners();
    _saveToStorage();
  }

  // Aliases for 2.0 UI
  void addCoins(int amount) => addGoldCoins(amount);
  bool spendCoins(int amount) => spendGoldCoins(amount);
  void addGems(int amount) => addDiamonds(amount);
  bool spendGems(int amount) => spendDiamonds(amount);

  // --------------------------------------------------------------------------
  // MANUAL STAT ALLOCATION SYSTEM
  // --------------------------------------------------------------------------
  static const int maxAllocatedPerStat = 10;

  /// String-based allocation method (Power, Control, Spin, Agility)
  bool allocateUpgradePoint(String paddleId, String statKey) {
    if (_upgradePoints <= 0) return false;

    final alloc = getAllocation(paddleId);
    bool upgraded = false;

    switch (statKey.toLowerCase().trim()) {
      case 'power':
        if (alloc.power < maxAllocatedPerStat) {
          alloc.power++;
          upgraded = true;
        }
        break;
      case 'control':
      case 'accuracy':
        if (alloc.control < maxAllocatedPerStat) {
          alloc.control++;
          upgraded = true;
        }
        break;
      case 'spin':
        if (alloc.spin < maxAllocatedPerStat) {
          alloc.spin++;
          upgraded = true;
        }
        break;
      case 'agility':
      case 'speed':
        if (alloc.agility < maxAllocatedPerStat) {
          alloc.agility++;
          upgraded = true;
        }
        break;
    }

    if (upgraded) {
      _upgradePoints--;
      notifyListeners();
      _saveToStorage();
      return true;
    }
    return false;
  }

  /// Enum-based allocation method for UI calls
  bool upgradePaddleStat(String paddleId, PaddleStatType stat) {
    return allocateUpgradePoint(paddleId, stat.name);
  }

  void resetPaddleAllocations(String paddleId) {
    final alloc = getAllocation(paddleId);
    final reclaimed = alloc.totalAllocated;
    if (reclaimed > 0) {
      _upgradePoints += reclaimed;
      alloc.power = 0;
      alloc.control = 0;
      alloc.spin = 0;
      alloc.agility = 0;
      notifyListeners();
      _saveToStorage();
    }
  }

  // --------------------------------------------------------------------------
  // ACCOUNT LEVEL PROGRESSION (+3 UP PER LEVEL-UP)
  // --------------------------------------------------------------------------
  void addMatchExperience({
    required bool wonMatch,
    required int rallyHits,
    required int smashes,
  }) {
    _careerMatches++;
    if (wonMatch) _careerWins++;

    int earnedXp = (wonMatch ? 90 : 35) + (rallyHits * 4) + (smashes * 12);
    int earnedCoins = (wonMatch ? 150 : 50) + (rallyHits * 3);

    if (_isCampaignMatch && wonMatch) {
      final stage = kCampaignStages[_activeCampaignStageIndex];
      earnedXp += stage.xpReward;
      earnedCoins += stage.coinReward;
      if (_completedStages <= _activeCampaignStageIndex) {
        _completedStages = _activeCampaignStageIndex + 1;
      }
    }

    _goldCoins += earnedCoins;
    _playerXp += earnedXp;

    // Account Level-Up Loop: awards +3 UP per level-up
    while (_playerXp >= _xpToNextLevel) {
      _playerXp -= _xpToNextLevel;
      _playerLevel++;
      _upgradePoints += 3; // +3 Upgrade Points awarded every level-up
      _xpToNextLevel = (_xpToNextLevel * 1.45).round();
    }

    notifyListeners();
    _saveToStorage();
  }

  // --------------------------------------------------------------------------
  // SELECTION & MATCH CONFIGURATIONS
  // --------------------------------------------------------------------------
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
    _saveToStorage();
  }

  void selectPaddle(PaddleModel paddle) {
    if (!paddle.isPrototype && paddle.unlockLevel <= _playerLevel) {
      _selectedPaddle = paddle;
      notifyListeners();
      _saveToStorage();
    }
  }

  void setDifficulty(AIDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  void toggleSound(bool val) {
    _soundEnabled = val;
    notifyListeners();
    _saveToStorage();
  }

  void toggleHaptics(bool val) {
    _hapticsEnabled = val;
    notifyListeners();
    _saveToStorage();
  }

  void toggleScreenShake(bool val) {
    _screenShakeEnabled = val;
    notifyListeners();
    _saveToStorage();
  }

  void setTargetScore(int score) {
    _targetScore = score;
    notifyListeners();
    _saveToStorage();
  }

  void setCourtVenue(String venue) {
    _courtVenue = venue;
    notifyListeners();
    _saveToStorage();
  }

  void setGamePace(double pace) {
    _gamePace = pace;
    notifyListeners();
    _saveToStorage();
  }
}