import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../services/lan_multiplayer_manager.dart';
import '../widgets/ambient_background.dart';
import '../widgets/asset_helpers.dart';
import '../widgets/game_components.dart';
import 'gameplay_screen.dart';

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

  // Local Player Profiles
  String _myUsername = '';
  String _opponentUsername = 'Waiting...';
  String _opponentAthleteId = 'aria';
  String _opponentPaddleId = 'volt_strike';

  bool _isChallengerReady = false; // Synced between devices

  // 1v1 Custom Venues
  final List<Map<String, dynamic>> _venues = [
    {
      'name': 'Rivalry Clash',
      'subtitle': 'Red vs Blue Split Arena',
      'accent': const Color(0xFF00E5FF),
      'swatch': const Color(0xFF1565C0),
    },
    {
      'name': 'Monochrome Street',
      'subtitle': 'Black & White Asphalt',
      'accent': Colors.white,
      'swatch': const Color(0xFF212121),
    },
    {
      'name': 'Midnight Stadium',
      'subtitle': 'Cyber LED Cyan Court',
      'accent': const Color(0xFF00E5FF),
      'swatch': const Color(0xFF0F1722),
    },
    {
      'name': 'Tournament Arena',
      'subtitle': 'Official USAPA Regulation',
      'accent': AppTheme.opticYellow,
      'swatch': const Color(0xFF1F598C),
    },
  ];

  int _selectedVenueIdx = 0;
  int _targetScore = 11;

  // Animation & Countdown
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _matchStarting = false;

  // Local settings toggles for in-lobby popup
  bool _highFpsEnabled = true;
  bool _screenShakeEnabled = true;

  @override
  void initState() {
    super.initState();
    final state = GameState.instance;

    _myUsername = widget.isHost ? 'Host Player' : 'Challenger';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _lan.addListener(_onLanStateChanged);
    _packetSub = _lan.packetStream.listen(_onPacketReceived);

    // Initial broadcast if Host
    if (widget.isHost) {
      _broadcastHostProfile();
    } else {
      _broadcastChallengerProfile();
    }
  }

  void _onLanStateChanged() {
    if (mounted) setState(() {});
  }

  // ==========================================================================
  // REAL-TIME ROOM PACKET SYNCHRONIZATION
  // ==========================================================================
  void _onPacketReceived(Map<String, dynamic> packet) {
    if (!mounted) return;

    if (packet['type'] == 'challenger_profile') {
      setState(() {
        _opponentUsername = packet['username'] ?? 'Challenger';
        _opponentAthleteId = packet['athleteId'] ?? 'jax';
        _opponentPaddleId = packet['paddleId'] ?? 'volt_strike';
      });
      // Acknowledge by sending Host profile back
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
          backgroundColor: const Color(0xFF070B0E),
          body: AmbientCourtBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // 1. TOP NAV BAR (COMPACT & NON-OVERFLOWING)
                      _buildTopBar(context, state),

                      // 2. SCROLLABLE LOBBY BODY
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DUAL BOXES: HOST (LEFT) VS CHALLENGER (RIGHT)
                                  _buildDualBoxes(state),

                                  const SizedBox(height: 16),

                                  // HOST-ONLY SETTINGS AREA (VENUE & POINTS)
                                  _buildHostSettingsArea(state),

                                  const SizedBox(height: 20),

                                  // READY / START BUTTON CLUSTER
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. COUNTDOWN OVERLAY
                  if (_matchStarting) _buildCountdownOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 1. TOP NAV BAR
  // ==========================================================================
  Widget _buildTopBar(BuildContext context, GameState state) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                color: AppTheme.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.glassBorder),
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
                  widget.isHost ? 'HOST ROOM (LOBBY)' : 'CHALLENGER ROOM',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  widget.isHost ? 'ROOM IP: ${_lan.localIp}' : 'CONNECTED TO HOST',
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                ),
              ],
            ),
          ),

          // Settings Button (Overflow Completely Prevented)
          BouncyButton(
            onTap: () => _showSettingsModal(context, state),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(Icons.settings_rounded, size: 17, color: AppTheme.opticYellow),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. DUAL BOXES: HOST (LEFT) VS CHALLENGER (RIGHT)
  // ==========================================================================
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------------------
        // LEFT BOX: HOST
        // --------------------------------------------------------------------
        Expanded(
          flex: widget.isHost ? 52 : 48,
          child: _buildPlayerBox(
            isMe: widget.isHost,
            roleTag: 'HOST',
            tagColor: const Color(0xFF00E5FF),
            username: widget.isHost ? _myUsername : _opponentUsername,
            athlete: widget.isHost ? myAthlete : oppAthlete,
            paddle: widget.isHost ? myPaddle : oppPaddle,
            isReady: true,
            onEditAthlete: widget.isHost ? () => _showAthletePickerModal(context, state) : null,
            onEditPaddle: widget.isHost ? () => _showPaddlePickerModal(context, state) : null,
            onEditName: widget.isHost ? _showUsernameDialog : null,
          ),
        ),

        const SizedBox(width: 10),

        // --------------------------------------------------------------------
        // RIGHT BOX: CHALLENGER
        // --------------------------------------------------------------------
        Expanded(
          flex: !widget.isHost ? 52 : 48,
          child: !_lan.isConnected && widget.isHost
              ? _buildWaitingChallengerBox()
              : _buildPlayerBox(
                  isMe: !widget.isHost,
                  roleTag: 'CHALLENGER',
                  tagColor: const Color(0xFFFF7043),
                  username: !widget.isHost ? _myUsername : _opponentUsername,
                  athlete: !widget.isHost ? myAthlete : oppAthlete,
                  paddle: !widget.isHost ? myPaddle : oppPaddle,
                  isReady: _isChallengerReady,
                  onEditAthlete: !widget.isHost ? () => _showAthletePickerModal(context, state) : null,
                  onEditPaddle: !widget.isHost ? () => _showPaddlePickerModal(context, state) : null,
                  onEditName: !widget.isHost ? _showUsernameDialog : null,
                ),
        ),
      ],
    );
  }

  // Individual Fighter Card Box
  Widget _buildPlayerBox({
    required bool isMe,
    required String roleTag,
    required Color tagColor,
    required String username,
    required CharacterModel athlete,
    required PaddleModel paddle,
    required bool isReady,
    VoidCallback? onEditAthlete,
    VoidCallback? onEditPaddle,
    VoidCallback? onEditName,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.all(isMe ? 12 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe ? tagColor : Colors.white12,
          width: isMe ? 2.0 : 1.0,
        ),
        boxShadow: isMe
            ? [BoxShadow(color: tagColor.withValues(alpha: 0.25), blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          // Role & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMe ? '$roleTag (YOU)' : roleTag,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: tagColor, letterSpacing: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isReady ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReady ? 'READY' : 'NOT READY',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: isReady ? const Color(0xFF00E676) : Colors.amber,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Username (Tap to edit if ME)
          GestureDetector(
            onTap: onEditName,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 11, color: Colors.white54),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Athlete Slot
          GestureDetector(
            onTap: onEditAthlete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMe ? athlete.accentColor.withValues(alpha: 0.5) : Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: athlete.bodyColor,
                    child: Text(athlete.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete.name.split(' ')[0].toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(athlete.archetype, style: TextStyle(fontSize: 8, color: athlete.accentColor)),
                      ],
                    ),
                  ),
                  if (isMe) const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white38),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Paddle Slot
          GestureDetector(
            onTap: onEditPaddle,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMe ? paddle.accentColor.withValues(alpha: 0.5) : Colors.white10),
              ),
              child: Row(
                children: [
                  PaddleGraphic(paddle: paddle, width: 14, height: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paddle.name.split(' ')[0].toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text('LVL ${paddle.level}', style: const TextStyle(fontSize: 8, color: AppTheme.opticYellow)),
                      ],
                    ),
                  ),
                  if (isMe) const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty Challenger Waiting Box
  Widget _buildWaitingChallengerBox() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final opacity = 0.4 + (_pulseController.value * 0.4);

        return Container(
          height: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B26).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar_rounded, size: 36, color: const Color(0xFF00E5FF).withValues(alpha: opacity)),
              const SizedBox(height: 10),
              Text(
                'WAITING FOR\nCHALLENGER...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: opacity),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'IP: ${_lan.localIp}',
                style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Color(0xFF00E5FF)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 3. HOST-ONLY SETTINGS AREA (VENUE COMBOS & POINTS)
  // ==========================================================================
  Widget _buildHostSettingsArea(GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ARENA & MATCH RULES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.0)),
              if (!widget.isHost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: const Text('HOST CONTROLLED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 1v1 Arenas
          for (int i = 0; i < _venues.length; i++) ...[
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
                  color: _selectedVenueIdx == i ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedVenueIdx == i ? const Color(0xFF00E5FF) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: _venues[i]['swatch']),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_venues[i]['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    Text(_venues[i]['subtitle'], style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Points Selector
          Row(
            children: [5, 11, 15].map((pts) {
              final isSel = _targetScore == pts;
              return Expanded(
                child: GestureDetector(
                  onTap: widget.isHost
                      ? () {
                          setState(() => _targetScore = pts);
                          _broadcastSettings();
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.opticYellow.withValues(alpha: 0.25) : Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? AppTheme.opticYellow : Colors.white12),
                    ),
                    child: Center(
                      child: Text('$pts PTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.white60)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. READY & START BUTTON CLUSTER
  // ==========================================================================
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: canStart
                ? const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)])
                : const LinearGradient(colors: [Colors.white24, Colors.white12]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canStart
                ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: Text(
              !_lan.isConnected
                  ? 'WAITING FOR CHALLENGER...'
                  : !_isChallengerReady
                      ? 'WAITING FOR CHALLENGER TO READY UP...'
                      : 'START 1v1 MATCH',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: canStart ? Colors.black : Colors.white38,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      );
    } else {
      // Challenger has the READY toggle button!
      return BouncyButton(
        onTap: _toggleChallengerReady,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: _isChallengerReady
                ? const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)])
                : const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFF4511E)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isChallengerReady ? const Color(0xFF00E676) : const Color(0xFFFF7043)).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _isChallengerReady ? 'READY! (WAITING FOR HOST TO START)' : 'TAP WHEN READY!',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0),
            ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // 5. COUNTDOWN OVERLAY
  // ==========================================================================
  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ENTERING COURT IN...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            Text('$_countdown', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppTheme.opticYellow)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // NON-OVERFLOWING SETTINGS MODAL (FIXED WITH SAFEAREA & SCROLLVIEW)
  // ==========================================================================
  void _showSettingsModal(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.70,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1613),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.opticYellow, width: 1.5),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SETTINGS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppTheme.opticYellow,
                        title: const Text('Sound Effects (SFX)', style: TextStyle(fontSize: 12.5)),
                        value: state.soundEnabled,
                        onChanged: (val) {
                          state.toggleSound(val);
                          setModalState(() {});
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppTheme.opticYellow,
                        title: const Text('Haptic Vibration', style: TextStyle(fontSize: 12.5)),
                        value: state.hapticsEnabled,
                        onChanged: (val) {
                          state.toggleHaptics(val);
                          setModalState(() {});
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppTheme.mintAccent,
                        title: const Text('60 FPS High Performance', style: TextStyle(fontSize: 12.5)),
                        value: _highFpsEnabled,
                        onChanged: (val) => setModalState(() => _highFpsEnabled = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppTheme.mintAccent,
                        title: const Text('Screen Shake FX', style: TextStyle(fontSize: 12.5)),
                        value: _screenShakeEnabled,
                        onChanged: (val) => setModalState(() => _screenShakeEnabled = val),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Username Dialog
  void _showUsernameDialog() {
    final controller = TextEditingController(text: _myUsername);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1B26),
          title: const Text('CHANGE USERNAME', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLength: 12,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: 'Enter name...', hintStyle: TextStyle(color: Colors.white24)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() => _myUsername = controller.text.trim());
                  if (widget.isHost) {
                    _broadcastHostProfile();
                  } else {
                    _broadcastChallengerProfile();
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  // Athlete Picker Modal
  void _showAthletePickerModal(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SELECT YOUR ATHLETE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              for (final char in kCharacters) ...[
                GestureDetector(
                  onTap: () {
                    state.selectCharacter(char);
                    if (widget.isHost) {
                      _broadcastHostProfile();
                    } else {
                      _broadcastChallengerProfile();
                    }
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: state.selectedCharacter.id == char.id ? char.bodyColor.withValues(alpha: 0.25) : Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.selectedCharacter.id == char.id ? char.accentColor : Colors.white12,
                        width: state.selectedCharacter.id == char.id ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: char.bodyColor,
                          child: Text(char.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                        if (state.selectedCharacter.id == char.id) const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Paddle Picker Modal
  void _showPaddlePickerModal(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.55,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.opticYellow, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EQUIP YOUR PADDLE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: kPaddles.length,
                  itemBuilder: (context, index) {
                    final p = kPaddles[index];
                    final isEquipped = state.selectedPaddle.id == p.id;
                    final isUnlocked = state.playerLevel >= p.unlockLevel;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () {
                              state.selectPaddle(p);
                              if (widget.isHost) {
                                _broadcastHostProfile();
                              } else {
                                _broadcastChallengerProfile();
                              }
                              Navigator.pop(ctx);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isEquipped ? AppTheme.opticYellow : Colors.white12, width: isEquipped ? 2.0 : 1.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PaddleGraphic(paddle: p, width: 32, height: 46),
                            const SizedBox(height: 3),
                            Text(p.name.split(' ')[0], maxLines: 1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}