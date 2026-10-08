// lib/screens/multiplayer/vs_online_room_screen.dart

import 'dart:async';
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
import 'widgets/quick_chat_overlay.dart';

class VsOnlineRoomScreen extends StatefulWidget {
  final bool isHost;

  const VsOnlineRoomScreen({super.key, required this.isHost});

  @override
  State<VsOnlineRoomScreen> createState() => _VsOnlineRoomScreenState();
}

class _VsOnlineRoomScreenState extends State<VsOnlineRoomScreen>
    with TickerProviderStateMixin {
  final OnlineMultiplayerManager _online = OnlineMultiplayerManager.instance;
  StreamSubscription? _packetSub;

  String _myUsername = '';
  String _opponentUsername = 'Waiting for challenger...';
  String _opponentAthleteId = 'jax';
  String _opponentPaddleId = 'volt_strike';

  bool _localReady = false;
  bool _remoteReady = false;

  String? _hostChatText;
  Timer? _hostChatTimer;
  String? _challengerChatText;
  Timer? _challengerChatTimer;

  final List<Map<String, dynamic>> _venues = [
    {
      'name': 'Tournament Arena',
      'subtitle': 'USAPA Championship Acrylic',
      'swatch': const Color(0xFF1F598C)
    },
    {
      'name': 'Midnight Stadium',
      'subtitle': 'Cyber LED Synthetic Court',
      'swatch': const Color(0xFF0F1722)
    },
    {
      'name': 'Sunlit Beach',
      'subtitle': 'Golden Coast Hardcourt',
      'swatch': const Color(0xFF2A9D8F)
    },
  ];

  int _selectedVenueIdx = 0;
  int _targetScore = 11;

  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _matchStarting = false;

  @override
  void initState() {
    super.initState();
    final state = GameState.instance;
    _myUsername = widget.isHost
        ? '${state.selectedCharacter.name.split(' ')[0]} (Host)'
        : '${state.selectedCharacter.name.split(' ')[0]} (Challenger)';

    _localReady = widget.isHost;

    // Guest initializes directly from persistent room settings
    if (!widget.isHost) {
      _selectedVenueIdx = _online.roomVenueIdx;
      _targetScore = _online.roomTargetScore;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _online.addListener(_onOnlineStateChanged);
    _packetSub = _online.packetStream.listen(_onPacketReceived);

    if (widget.isHost) {
      _broadcastHostProfile();
    } else {
      _broadcastChallengerProfile();
    }
  }

  void _onOnlineStateChanged() {
    if (!mounted) return;

    // Guest updates directly whenever the room settings document updates
    if (!widget.isHost) {
      setState(() {
        _selectedVenueIdx = _online.roomVenueIdx;
        _targetScore = _online.roomTargetScore;
      });
    }

    if (_online.isConnected) {
      setState(() {
        _opponentUsername = _online.opponentName;
        _opponentAthleteId = _online.opponentAthleteId;
        _opponentPaddleId = _online.opponentPaddleId;
        _remoteReady = _online.isOpponentReady;
      });
    }
  }

  void _onPacketReceived(Map<String, dynamic> packet) {
    if (!mounted) return;

    final type = packet['type'];

    if (type == 'challenger_ready') {
      setState(() {
        if (widget.isHost) {
          _remoteReady = packet['isReady'] == true;
        }
      });
      AppAudio.playFeatureSfx(AppAssets.sfxCardTap);
    } else if (type == 'chat') {
      final role = packet['role'] ?? 'guest';
      final text = packet['text'] ?? '';
      _displayChatBubble(role: role, text: text);
    } else if (type == 'start_match') {
      _startCountdown();
    }
  }

  void _broadcastHostProfile() {
    final state = GameState.instance;
    _online.sendPacket({
      'type': 'host_profile',
      'username': _myUsername,
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
    });
  }

  void _broadcastChallengerProfile() {
    final state = GameState.instance;
    _online.sendPacket({
      'type': 'challenger_profile',
      'username': _myUsername,
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
    });
  }

  void _displayChatBubble({required String role, required String text}) {
    AppAudio.playFeatureSfx(AppAssets.sfxClick);

    if (role == 'host') {
      _hostChatTimer?.cancel();
      setState(() => _hostChatText = text);
      _hostChatTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _hostChatText = null);
      });
    } else {
      _challengerChatTimer?.cancel();
      setState(() => _challengerChatText = text);
      _challengerChatTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _challengerChatText = null);
      });
    }
  }

  void _sendQuickChat(String text) {
    final myRole = widget.isHost ? 'host' : 'guest';
    _online.sendPacket({
      'type': 'chat',
      'role': myRole,
      'text': text,
    });
    _displayChatBubble(role: myRole, text: text);
  }

  void _openChatSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickChatPickerSheet(
        onSend: (call) => _sendQuickChat(call.text),
      ),
    );
  }

  void _toggleChallengerReady() {
    setState(() => _localReady = !_localReady);
    _online.toggleReadyState(_localReady);
    _online.sendPacket({
      'type': 'challenger_ready',
      'isReady': _localReady,
    });
    AppAudio.playFeatureSfx(AppAssets.sfxClick);
  }

  void _startCountdown() {
    setState(() {
      _matchStarting = true;
      _countdown = 3;
    });

    AppAudio.play(context, AppAssets.musicBattleStart, 'Match Starting');
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _launchMatch();
      }
    });
  }

  void _launchMatch() {
    final state = GameState.instance;

    // Both devices load the venue verified from the authoritative settings
    final String chosenVenue = _venues[_selectedVenueIdx]['name'];
    state.setCourtVenue(chosenVenue);
    state.setTargetScore(_targetScore);
    state.startExhibitionMatch();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CourtGameplayScreen(
          matchMode: MatchMode.onlinePvp,
          isHost: widget.isHost,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hostChatTimer?.cancel();
    _challengerChatTimer?.cancel();
    _pulseController.dispose();
    _packetSub?.cancel();
    _online.removeListener(_onOnlineStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AmbientCourtBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRoomCodeHeader(),
                              const SizedBox(height: 12),
                              _buildDualPlayerPods(state),
                              const SizedBox(height: 14),
                              _buildVenueAndScoreSettings(),
                              const SizedBox(height: 16),
                              _buildBottomActionCluster(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_matchStarting) _buildCountdownOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isHost ? 'ONLINE ARENA (HOST)' : 'ONLINE ARENA (GUEST)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Row(
                children: [
                  const CircleAvatar(radius: 3, backgroundColor: AppColors.mintAccent),
                  const SizedBox(width: 5),
                  Text(
                    '${_online.estimatedPingMs}ms • ASIA-SOUTHEAST',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.cyberCyan),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          BouncyButton(
            onTap: _openChatSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.opticYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.opticYellow),
                  SizedBox(width: 6),
                  Text('CHAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.opticYellow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.opticYellow.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRIVATE ROOM CODE',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0),
              ),
              const SizedBox(height: 2),
              Text(
                _online.activeRoomCode.isEmpty ? '....' : _online.activeRoomCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.opticYellow,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
          BouncyButton(
            onTap: () {
              if (_online.activeRoomCode.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: _online.activeRoomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Room code copied to clipboard!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.copy_rounded, color: Colors.white70, size: 15),
                  SizedBox(width: 6),
                  Text('COPY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualPlayerPods(GameState state) {
    final myAthlete = state.selectedCharacter;
    final myPaddle = state.selectedPaddle;

    final oppAthlete = kCharacters.firstWhere(
      (c) => c.id == _opponentAthleteId,
      orElse: () => kCharacters[3],
    );
    final oppPaddle = kPaddles.firstWhere(
      (p) => p.id == _opponentPaddleId,
      orElse: () => kPaddles[0],
    );

    final bool hostIsReady = widget.isHost ? _localReady : _remoteReady;
    final bool challengerIsReady = widget.isHost ? _remoteReady : _localReady;

    return Row(
      children: [
        Expanded(
          child: _buildPlayerPod(
            isMe: widget.isHost,
            roleTag: 'HOST',
            tagColor: AppColors.cyberCyan,
            username: widget.isHost ? _myUsername : _opponentUsername,
            athlete: widget.isHost ? myAthlete : oppAthlete,
            paddle: widget.isHost ? myPaddle : oppPaddle,
            isReady: hostIsReady,
            chatBubbleText: _hostChatText,
            isWaiting: !widget.isHost && !_online.isConnected,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPlayerPod(
            isMe: !widget.isHost,
            roleTag: 'CHALLENGER',
            tagColor: AppColors.electricCoral,
            username: !widget.isHost ? _myUsername : _opponentUsername,
            athlete: !widget.isHost ? myAthlete : oppAthlete,
            paddle: !widget.isHost ? myPaddle : oppPaddle,
            isReady: challengerIsReady,
            chatBubbleText: _challengerChatText,
            isWaiting: widget.isHost && !_online.isConnected,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerPod({
    required bool isMe,
    required String roleTag,
    required Color tagColor,
    required String username,
    required CharacterModel athlete,
    required PaddleModel paddle,
    required bool isReady,
    required String? chatBubbleText,
    required bool isWaiting,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1824),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWaiting
                  ? Colors.white12
                  : (isMe ? tagColor : Colors.white24),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: (isWaiting ? Colors.transparent : tagColor).withValues(alpha: 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      roleTag,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: tagColor),
                    ),
                  ),
                  Text(
                    isWaiting ? 'EMPTY' : (isReady ? 'READY' : 'WAITING'),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isWaiting
                          ? Colors.white38
                          : (isReady ? AppColors.mintAccent : Colors.orangeAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (isWaiting) ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05 + (_pulseController.value * 0.05)),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.person_search_rounded, color: Colors.white38, size: 20),
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Waiting for friend\nto join...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
              ] else ...[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: athlete.bodyColor,
                  child: Text(
                    athlete.name[0],
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  athlete.archetype.toUpperCase(),
                  style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: athlete.accentColor),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PaddleGraphic(paddle: paddle, width: 12, height: 18),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        paddle.name.split(' ')[0],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: paddle.accentColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (chatBubbleText != null)
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: QuickChatBubble(text: chatBubbleText),
            ),
          ),
      ],
    );
  }

  Widget _buildVenueAndScoreSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MATCH VENUE SELECTION',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              if (!widget.isHost)
                const Text(
                  'HOST CONTROLLED',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.opticYellow),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < _venues.length; i++)
            GestureDetector(
              onTap: widget.isHost
                  ? () {
                      setState(() => _selectedVenueIdx = i);
                      // Update authoritative database settings document
                      _online.updateRoomSettings(
                        venueIdx: i,
                        venueName: _venues[i]['name'],
                        targetScore: _targetScore,
                      );
                      AppAudio.playFeatureSfx(AppAssets.sfxClick);
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedVenueIdx == i
                      ? AppColors.cyberCyan.withValues(alpha: 0.15)
                      : Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedVenueIdx == i ? AppColors.cyberCyan : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: _venues[i]['swatch']),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _venues[i]['name'],
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Text(
                      _venues[i]['subtitle'],
                      style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TARGET SCORE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              Row(
                children: [5, 11, 15].map((pts) {
                  final isSelected = _targetScore == pts;
                  return GestureDetector(
                    onTap: widget.isHost
                        ? () {
                            setState(() => _targetScore = pts);
                            // Update authoritative database settings document
                            _online.updateRoomSettings(
                              venueIdx: _selectedVenueIdx,
                              venueName: _venues[_selectedVenueIdx]['name'],
                              targetScore: pts,
                            );
                            AppAudio.playFeatureSfx(AppAssets.sfxClick);
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.opticYellow : Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.opticYellow : Colors.white12),
                      ),
                      child: Text(
                        '$pts PTS',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionCluster() {
    if (widget.isHost) {
      final canStart = _online.isConnected && _remoteReady;

      return BouncyButton(
        onTap: canStart
            ? () {
                _online.updateRoomSettings(
                  venueIdx: _selectedVenueIdx,
                  venueName: _venues[_selectedVenueIdx]['name'],
                  targetScore: _targetScore,
                );
                _online.sendPacket({'type': 'start_match'});
                _startCountdown();
              }
            : () {},
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: canStart ? AppColors.mintAccent : Colors.white12,
            borderRadius: BorderRadius.circular(16),
            boxShadow: canStart
                ? [
                    BoxShadow(
                      color: AppColors.mintAccent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              !_online.isConnected
                  ? 'WAITING FOR CHALLENGER TO JOIN...'
                  : (canStart ? 'START 1v1 MATCH' : 'WAITING FOR CHALLENGER READY...'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                color: canStart ? Colors.black : Colors.white38,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      );
    } else {
      return BouncyButton(
        onTap: _toggleChallengerReady,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _localReady ? AppColors.mintAccent : AppColors.electricCoral,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_localReady ? AppColors.mintAccent : AppColors.electricCoral)
                    .withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _localReady ? 'READY! (WAITING FOR HOST)' : 'TAP WHEN READY!',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Colors.black, letterSpacing: 1.0),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MATCH STARTING IN...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 2.0),
            ),
            const SizedBox(height: 8),
            Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                color: AppColors.opticYellow,
                shadows: [Shadow(color: AppColors.opticYellow, blurRadius: 28)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}