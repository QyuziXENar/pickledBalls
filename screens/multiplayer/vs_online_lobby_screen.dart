// lib/screens/multiplayer/vs_online_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../services/online_multiplayer_manager.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import '../gameplay/gameplay_screen.dart';

class VsOnlineLobbyScreen extends StatefulWidget {
  const VsOnlineLobbyScreen({super.key});

  @override
  State<VsOnlineLobbyScreen> createState() => _VsOnlineLobbyScreenState();
}

class _VsOnlineLobbyScreenState extends State<VsOnlineLobbyScreen>
    with SingleTickerProviderStateMixin {
  final OnlineMultiplayerManager _online = OnlineMultiplayerManager.instance;
  final TextEditingController _joinCodeController = TextEditingController();

  int _selectedTab = 0; // 0 = Quick Match, 1 = Private Room
  late AnimationController _radarController;
  bool _isLocalReady = false;

  @override
  void initState() {
    super.initState();
    _online.addListener(_onOnlineStateChanged);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _joinCodeController.dispose();
    _online.removeListener(_onOnlineStateChanged);
    super.dispose();
  }

  void _onOnlineStateChanged() {
    if (mounted) setState(() {});
  }

  void _launchMatch() {
    AppAudio.play(context, AppAssets.musicBattleStart, 'Match Starting');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AmbientCourtBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    BouncyButton(
                      onTap: () {
                        _online.disconnect();
                        Navigator.pop(context);
                      },
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
                        Text(
                          'ONLINE 1v1 ARENA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                        ),
                        Text(
                          'GLOBAL CELLULAR & WI-FI MATCHMAKING',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.opticYellow, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Estimated Ping Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 3.5, backgroundColor: AppColors.mintAccent),
                          const SizedBox(width: 6),
                          Text(
                            '${_online.estimatedPingMs}ms',
                            style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tab Selector: Quick Match vs Private Room
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B26),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(title: 'QUICK MATCH', index: 0, icon: Icons.flash_on_rounded),
                      _buildTabButton(title: 'PRIVATE ROOM', index: 1, icon: Icons.vpn_key_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _online.isConnected
                          ? _buildConnectedRoomView(state)
                          : (_selectedTab == 0 ? _buildQuickMatchView() : _buildPrivateRoomView(state)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab == index) return;
          _online.disconnect();
          setState(() => _selectedTab = index);
          AppAudio.playFeatureSfx(AppAssets.sfxClick);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.opticYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white60),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.black : Colors.white60,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Match View
  Widget _buildQuickMatchView() {
    final isSearching = _online.status == OnlineStatus.inQueue;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isSearching)
                    Container(
                      width: 110 * _radarController.value,
                      height: 110 * _radarController.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.opticYellow.withValues(alpha: 1.0 - _radarController.value),
                          width: 2.0,
                        ),
                      ),
                    ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.opticYellow.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.opticYellow, width: 2),
                    ),
                    child: Icon(
                      isSearching ? Icons.radar_rounded : Icons.search_rounded,
                      color: AppColors.opticYellow,
                      size: 34,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'SEARCHING FOR RIVAL...' : 'GLOBAL MATCHMAKING',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching ? 'Finding an athlete with similar DUPR rank' : 'Hop into an instant 1v1 match with any online player worldwide.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 20),
          BouncyButton(
            onTap: () {
              if (isSearching) {
                _online.disconnect();
              } else {
                _online.startQuickMatch();
              }
              AppAudio.playFeatureSfx(AppAssets.sfxClick);
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: isSearching ? Colors.red.withValues(alpha: 0.2) : AppColors.opticYellow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSearching ? Colors.redAccent : Colors.transparent),
              ),
              child: Center(
                child: Text(
                  isSearching ? 'CANCEL SEARCH' : 'FIND MATCH NOW',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isSearching ? Colors.redAccent : Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Private Room View
  Widget _buildPrivateRoomView(GameState state) {
    return Column(
      children: [
        // Create Room Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CREATE PRIVATE ARENA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Host a private room and share your 4-letter code with a friend.', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              if (_online.status == OnlineStatus.roomCreated) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.opticYellow),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ROOM CODE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          Text(
                            _online.activeRoomCode,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.opticYellow, letterSpacing: 4.0),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _online.activeRoomCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📋 Room code copied!'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Waiting for friend to enter code...', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ),
              ] else ...[
                BouncyButton(
                  onTap: () {
                    _online.createPrivateRoom();
                    AppAudio.playFeatureSfx(AppAssets.sfxClick);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.lanHostGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('CREATE ROOM CODE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Join Room Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('JOIN WITH CODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _joinCodeController,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.0),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.black45,
                  hintText: 'ABCD',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4.0),
                  prefixIcon: const Icon(Icons.dialpad_rounded, color: AppColors.opticYellow, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.opticYellow)),
                ),
              ),
              const SizedBox(height: 10),
              BouncyButton(
                onTap: () {
                  _online.joinPrivateRoom(_joinCodeController.text.trim());
                  AppAudio.playFeatureSfx(AppAssets.sfxClick);
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.opticYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('JOIN ROOM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Connected Room Match View
  Widget _buildConnectedRoomView(GameState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mintAccent, width: 2.0),
      ),
      child: Column(
        children: [
          const Text('RIVAL FOUND!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.mintAccent, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // You
              Column(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: state.selectedCharacter.bodyColor, child: Text(state.selectedCharacter.name[0], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white))),
                  const SizedBox(height: 6),
                  const Text('YOU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                  Text(state.selectedCharacter.name.split(' ')[0], style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
              const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.opticYellow)),
              // Opponent
              Column(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: const Color(0xFFE63946), child: Text(_online.opponentName[0], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white))),
                  const SizedBox(height: 6),
                  Text(_online.opponentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                  Text(_online.opponentAthleteId.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          BouncyButton(
            onTap: () {
              setState(() => _isLocalReady = true);
              _online.toggleReadyState(true);
              _launchMatch();
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('READY TO SERVE (ENTER MATCH)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}