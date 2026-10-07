// lib/screens/multiplayer/online_leaderboard_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../models/online_profile_models.dart';
import '../../services/online_repository.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/game_components.dart';

class OnlineLeaderboardScreen extends StatefulWidget {
  const OnlineLeaderboardScreen({super.key});

  @override
  State<OnlineLeaderboardScreen> createState() => _OnlineLeaderboardScreenState();
}

class _OnlineLeaderboardScreenState extends State<OnlineLeaderboardScreen> {
  LeaderboardCategory _activeCategory = LeaderboardCategory.globalDupr;
  final OnlineRepository _repository = MockOnlineRepository.instance;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategory(_activeCategory);
  }

  Future<void> _loadCategory(LeaderboardCategory category) async {
    setState(() => _isLoading = true);
    final data = await _repository.fetchLeaderboard(category);
    if (!mounted) return;
    setState(() {
      _activeCategory = category;
      _entries = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AmbientCourtBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    BouncyButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LEADERBOARDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                        Text('GLOBAL DUPR & REGIONAL TOUR', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.opticYellow, letterSpacing: 0.8)),
                      ],
                    ),
                  ],
                ),
              ),

              // Segmented Category Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B26),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      _tabChip('GLOBAL DUPR', LeaderboardCategory.globalDupr),
                      _tabChip('LOCAL WINS', LeaderboardCategory.localDivision),
                      _tabChip('RALLIES', LeaderboardCategory.weeklyRallies),
                    ],
                  ),
                ),
              ),

              // Rankings List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.opticYellow))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _buildRankRow(entry);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip(String title, LeaderboardCategory category) {
    final isSelected = _activeCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => _loadCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.opticYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry) {
    Color rankColor = Colors.white70;
    Widget? rankBadge;

    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankBadge = const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFFFD700));
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankBadge = const Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFFC0C0C0));
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankBadge = const Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFFCD7F32));
    }

    final charModel = kCharacters.firstWhere(
      (c) => c.id == entry.athleteId,
      orElse: () => kCharacters[0],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentPlayer ? AppColors.opticYellow.withValues(alpha: 0.15) : const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isCurrentPlayer ? AppColors.opticYellow : Colors.white10,
          width: entry.isCurrentPlayer ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Row(
              children: [
                if (rankBadge != null) rankBadge else Text('#${entry.rank}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: rankColor)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: charModel.bodyColor,
            child: Text(charModel.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.username, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: entry.isCurrentPlayer ? AppColors.opticYellow : Colors.white)),
                    if (entry.isCurrentPlayer) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: AppColors.opticYellow, borderRadius: BorderRadius.circular(4)), child: const Text('YOU', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.black))),
                    ],
                  ],
                ),
                Text(entry.title, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF0277BD).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF0288D1))),
                child: Text('${entry.duprRating.toStringAsFixed(2)} DUPR', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF4FC3F7))),
              ),
              const SizedBox(height: 2),
              Text(
                _activeCategory == LeaderboardCategory.weeklyRallies
                    ? '${entry.metricValue} Hits'
                    : (_activeCategory == LeaderboardCategory.localDivision ? '${entry.metricValue} Wins' : '${entry.metricValue} Trophies'),
                style: const TextStyle(fontSize: 8.5, color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}