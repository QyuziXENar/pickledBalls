// lib/screens/vs_player_room_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../services/lan_multiplayer_manager.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import '../gameplay/gameplay_screen.dart';

class VsPlayerRoomScreen extends StatefulWidget {
  final bool isHost;

  const VsPlayerRoomScreen({super.key, required this.isHost});

  @override
  State<VsPlayerRoomScreen> createState() => _VsPlayerRoomScreenState();
}

class _VsPlayerRoomScreenState extends State<VsPlayerRoomScreen>
    with TickerProviderStateMixin {
  final LanMultiplayerManager _lan = LanMultiplayerManager.instance;
  StreamSubscription? _packetSub;

  String _myUsername = '';
  String _opponentUsername = 'Waiting...';
  String _opponentAthleteId = 'aria';
  String _opponentPaddleId = 'volt_strike';

  bool _isChallengerReady = false;

  final List<Map<String, dynamic>> _venues = [
    {'name': 'Tournament Arena', 'subtitle': 'USAPA Regulation', 'swatch': const Color(0xFF1F598C)},
    {'name': 'Midnight Stadium', 'subtitle': 'Cyber LED Cyan Court', 'swatch': const Color(0xFF0F1722)},
    {'name': 'Sunlit Beach', 'subtitle': 'Golden Hardcourt', 'swatch': const Color(0xFF2A9D8F)},
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
    _myUsername = widget.isHost ? 'Host Player' : 'Challenger';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _lan.addListener(_onLanStateChanged);
    _packetSub = _lan.packetStream.listen(_onPacketReceived);

    if (widget.isHost) {
      _broadcastHostProfile();
    } else {
      _broadcastChallengerProfile();
    }
  }

  void _onLanStateChanged() {
    if (mounted) setState(() {});
  }

  void _onPacketReceived(Map<String, dynamic> packet) {
    if (!mounted) return;

    if (packet['type'] == 'challenger_profile') {
      setState(() {
        _opponentUsername = packet['username'] ?? 'Challenger';
        _opponentAthleteId = packet['athleteId'] ?? 'jax';
        _opponentPaddleId = packet['paddleId'] ?? 'volt_strike';
      });
      if (widget.isHost) _broadcastHostProfile();
    } else if (packet['type'] == 'host_profile') {
      setState(() {
        _opponentUsername = packet['username'] ?? 'Host Player';
        _opponentAthleteId = packet['athleteId'] ?? 'aria';
        _opponentPaddleId = packet['paddleId'] ?? 'volt_strike';
      });
    } else if (packet['type'] == 'challenger_ready') {
      setState(() {
        _isChallengerReady = packet['isReady'] == true;
      });
      AppAudio.play(context, 'card_tap.mp3', 'Ready status updated');
    } else if (packet['type'] == 'room_settings') {
      setState(() {
        _selectedVenueIdx = packet['venueIdx'] ?? 0;
        _targetScore = packet['targetScore'] ?? 11;
      });
    } else if (packet['type'] == 'start_match') {
      _startCountdown();
    }
  }

  void _broadcastHostProfile() {
    final state = GameState.instance;
    _lan.sendPacket({
      'type': 'host_profile',
      'username': _myUsername,
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
    });
    _broadcastSettings();
  }

  void _broadcastChallengerProfile() {
    final state = GameState.instance;
    _lan.sendPacket({
      'type': 'challenger_profile',
      'username': _myUsername,
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
    });
  }

  void _broadcastSettings() {
    if (widget.isHost && _lan.isConnected) {
      _lan.sendPacket({
        'type': 'room_settings',
        'venueIdx': _selectedVenueIdx,
        'targetScore': _targetScore,
      });
    }
  }

  void _toggleChallengerReady() {
    setState(() => _isChallengerReady = !_isChallengerReady);
    _lan.sendPacket({
      'type': 'challenger_ready',
      'isReady': _isChallengerReady,
    });
    AppAudio.play(context, 'click.mp3', 'Ready Toggle');
  }

  void _startCountdown() {
    setState(() {
      _matchStarting = true;
      _countdown = 3;
    });

    AppAudio.play(context, 'battle_start.mp3', 'Match Starting');
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
    state.setCourtVenue(_venues[_selectedVenueIdx]['name']);
    state.setTargetScore(_targetScore);
    state.startExhibitionMatch();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _packetSub?.cancel();
    _lan.removeListener(_onLanStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final state = GameState.instance;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: AmbientCourtBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopBar(context, state),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDualBoxes(state),
                                  const SizedBox(height: 16),
                                  _buildHostSettingsArea(state),
                                  const SizedBox(height: 20),
                                  _buildActionButtons(),
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
      },
    );
  }

  Widget _buildTopBar(BuildContext context, GameState state) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          BouncyButton(
            onTap: () {
              _lan.disconnect();
              Navigator.pop(context);
            },
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.close_rounded, size: 17, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isHost ? 'HOST ROOM' : 'CHALLENGER ROOM',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  widget.isHost ? 'IP: ${_lan.localIp}' : 'CONNECTED TO HOST',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.cyberCyan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualBoxes(GameState state) {
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

    return Row(
      children: [
        Expanded(
          child: _buildPlayerBox(
            isMe: widget.isHost,
            roleTag: 'HOST',
            tagColor: AppColors.cyberCyan,
            username: widget.isHost ? _myUsername : _opponentUsername,
            athlete: widget.isHost ? myAthlete : oppAthlete,
            paddle: widget.isHost ? myPaddle : oppPaddle,
            isReady: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPlayerBox(
            isMe: !widget.isHost,
            roleTag: 'CHALLENGER',
            tagColor: AppColors.electricCoral,
            username: !widget.isHost ? _myUsername : _opponentUsername,
            athlete: !widget.isHost ? myAthlete : oppAthlete,
            paddle: !widget.isHost ? myPaddle : oppPaddle,
            isReady: _isChallengerReady,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerBox({
    required bool isMe,
    required String roleTag,
    required Color tagColor,
    required String username,
    required CharacterModel athlete,
    required PaddleModel paddle,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? tagColor : Colors.white12, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(roleTag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: tagColor)),
              Text(isReady ? 'READY' : 'WAITING',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isReady ? AppColors.mintAccent : Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 8),
          Text(username, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: 18,
            backgroundColor: athlete.bodyColor,
            child: Text(athlete.name[0], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(athlete.name.split(' ')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
          Text(paddle.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: paddle.accentColor)),
        ],
      ),
    );
  }

  Widget _buildHostSettingsArea(GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT MATCH VENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          for (int i = 0; i < _venues.length; i++)
            GestureDetector(
              onTap: widget.isHost
                  ? () {
                      setState(() => _selectedVenueIdx = i);
                      _broadcastSettings();
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedVenueIdx == i ? AppColors.cyberCyan.withValues(alpha: 0.15) : Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _selectedVenueIdx == i ? AppColors.cyberCyan : Colors.transparent),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: _venues[i]['swatch']),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_venues[i]['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                    Text(_venues[i]['subtitle'], style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isHost) {
      final canStart = _lan.isConnected && _isChallengerReady;
      return BouncyButton(
        onTap: canStart
            ? () {
                _lan.sendPacket({'type': 'start_match'});
                _startCountdown();
              }
            : () {},
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: canStart ? AppColors.mintAccent : Colors.white12,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              canStart ? 'START 1v1 MATCH' : 'WAITING FOR CHALLENGER...',
              style: TextStyle(fontWeight: FontWeight.w900, color: canStart ? Colors.black : Colors.white38),
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
            color: _isChallengerReady ? AppColors.mintAccent : AppColors.electricCoral,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              _isChallengerReady ? 'READY! (WAITING FOR HOST)' : 'TAP WHEN READY!',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
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
            const Text('STARTING IN...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            Text('$_countdown', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.opticYellow)),
          ],
        ),
      ),
    );
  }
}