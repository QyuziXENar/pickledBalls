// lib/Screen/Multiplayer/vs_online_lobby_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../services/online_multiplayer_manager.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import 'vs_online_room_screen.dart';

class VsOnlineLobbyScreen extends StatefulWidget {
  const VsOnlineLobbyScreen({super.key});

  @override
  State<VsOnlineLobbyScreen> createState() => _VsOnlineLobbyScreenState();
}

class _VsOnlineLobbyScreenState extends State<VsOnlineLobbyScreen>
    with SingleTickerProviderStateMixin {
  final OnlineMultiplayerManager _online = OnlineMultiplayerManager.instance;
  final TextEditingController _joinCodeController = TextEditingController();

  int _selectedTab = 1;
  late AnimationController _radarController;
  bool _isCreatingAction = false;
  bool _isJoiningAction = false;

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
    if (!mounted) return;

    if (_selectedTab == 0 && _online.isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VsOnlineRoomScreen(isHost: _online.isHost),
        ),
      );
    } else {
      setState(() {});
    }
  }

  Future<void> _handleCreatePrivateRoom() async {
    setState(() => _isCreatingAction = true);
    AppAudio.playFeatureSfx(AppAssets.sfxClick);

    final roomCode = await _online.createPrivateRoom();

    if (!mounted) return;
    setState(() => _isCreatingAction = false);

    if (roomCode.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VsOnlineRoomScreen(isHost: true),
        ),
      );
    }
  }

  Future<void> _handleJoinPrivateRoom() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length != 4) return;

    setState(() => _isJoiningAction = true);
    AppAudio.playFeatureSfx(AppAssets.sfxClick);

    final success = await _online.joinPrivateRoom(code);

    if (!mounted) return;
    setState(() => _isJoiningAction = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VsOnlineRoomScreen(isHost: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AmbientCourtBackground(
        child: SafeArea(
          child: Column(
            children: [
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _selectedTab == 0 ? _buildQuickMatchView() : _buildPrivateRoomView(),
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

  Widget _buildPrivateRoomView() {
    return Column(
      children: [
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
              const SizedBox(height: 14),

              BouncyButton(
                onTap: _isCreatingAction ? () {} : _handleCreatePrivateRoom,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.lanHostGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isCreatingAction
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                              SizedBox(width: 8),
                              Text('CREATING ROOM...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                            ],
                          )
                        : const Text('CREATE ROOM CODE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
              ),

              if (_online.errorMessage.isNotEmpty && _online.isHost) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_online.errorMessage, style: const TextStyle(fontSize: 9.5, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

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
                onTap: _isJoiningAction ? () {} : _handleJoinPrivateRoom,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.opticYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isJoiningAction
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                              SizedBox(width: 8),
                              Text('CONNECTING...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                            ],
                          )
                        : const Text('JOIN ROOM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
              ),

              if (_online.errorMessage.isNotEmpty && !_online.isHost) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_online.errorMessage, style: const TextStyle(fontSize: 9.5, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}