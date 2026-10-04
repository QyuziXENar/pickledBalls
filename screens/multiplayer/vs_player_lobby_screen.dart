import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_state.dart';
import '../../services/lan_multiplayer_manager.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import 'vs_player_room_screen.dart';

class VsPlayerLobbyScreen extends StatefulWidget {
  const VsPlayerLobbyScreen({super.key});

  @override
  State<VsPlayerLobbyScreen> createState() => _VsPlayerLobbyScreenState();
}

class _VsPlayerLobbyScreenState extends State<VsPlayerLobbyScreen> {
  final LanMultiplayerManager _lan = LanMultiplayerManager.instance;
  final TextEditingController _ipController = TextEditingController();

  int _tabIndex = 0; // 0 = Host, 1 = Join
  bool _isHostingAction = false;
  bool _isJoiningAction = false;

  // Local settings toggles for in-lobby popup
  bool _highFpsEnabled = true;
  bool _screenShakeEnabled = true;

  @override
  void initState() {
    super.initState();
    _lan.addListener(_onLanStateChanged);
    _initNetwork();
  }

  Future<void> _initNetwork() async {
    await _lan.refreshLocalIp();

    if (_lan.localIp.contains('.')) {
      final parts = _lan.localIp.split('.');
      if (parts.length == 4) {
        _ipController.text = '${parts[0]}.${parts[1]}.${parts[2]}.';
      }
    }
  }

  void _onLanStateChanged() {
    if (mounted) setState(() {});
  }

  // ==========================================================================
  // HOST NOW ACTION -> OPENS DEDICATED 1V1 WAITING ROOM
  // ==========================================================================
  Future<void> _onHostNowTapped() async {
    setState(() => _isHostingAction = true);
    AppAudio.play(context, 'click.mp3', 'Spinning up server');

    await _lan.startHost();

    if (!mounted) return;
    setState(() => _isHostingAction = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VsPlayerRoomScreen(isHost: true),
      ),
    );
  }

  // ==========================================================================
  // JOIN NOW ACTION -> CONNECTS AND OPENS DEDICATED 1V1 WAITING ROOM
  // ==========================================================================
  Future<void> _onJoinNowTapped() async {
    setState(() => _isJoiningAction = true);
    AppAudio.play(context, 'click.mp3', 'Connecting to host');

    final success = await _lan.joinMatch(_ipController.text.trim());

    if (!mounted) return;
    setState(() => _isJoiningAction = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VsPlayerRoomScreen(isHost: false),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
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
              child: Column(
                children: [
                  // 1. TOP NAV BAR (FIXED OVERFLOW WITH STRICT 36PX CONSTRAINTS)
                  _buildTopNavBar(state),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              _buildInstructionsHeader(),
                              const SizedBox(height: 12),
                              _buildTabSelector(),
                              const SizedBox(height: 14),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                child: _tabIndex == 0
                                    ? _buildHostTab(state)
                                    : _buildJoinTab(state),
                              ),

                              const SizedBox(height: 14),
                              _buildHotspotHelper(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // TOP NAV BAR (OVERFLOW COMPLETELY ELIMINATED)
  // ==========================================================================
  Widget _buildTopNavBar(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back Button
            BouncyButton(
              onTap: () {
                _lan.disconnect();
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),

            // Title & Subtitle
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1v1 LOCAL DUEL',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white),
                  ),
                  Text(
                    'DIRECT WI-FI & PHONE HOTSPOT',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF00E5FF)),
                  ),
                ],
              ),
            ),

            // QoL 1: Character Quick-Picker (Exact 36x36 Constraint)
            BouncyButton(
              onTap: () => _showAthletePickerModal(context, state),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.glassFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: state.selectedCharacter.accentColor, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: state.selectedCharacter.bodyColor,
                  child: Text(
                    state.selectedCharacter.name[0],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // QoL 2: Paddle Quick-Picker (Exact 36x36 Constraint)
            BouncyButton(
              onTap: () => _showPaddlePickerModal(context, state),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: state.selectedPaddle.accentColor, width: 1.5),
                ),
                child: PaddleGraphic(paddle: state.selectedPaddle, width: 12, height: 18),
              ),
            ),
            const SizedBox(width: 6),

            // QoL 3: Settings Popup (Exact 36x36 Constraint)
            BouncyButton(
              onTap: () => _showSettingsModal(context, state),
              child: Container(
                width: 36,
                height: 36,
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
      ),
    );
  }

  Widget _buildInstructionsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.hub_rounded, color: Color(0xFF00E5FF), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect both phones to the same Wi-Fi or turn on Mobile Hotspot on one phone. One player Hosts, the other Joins.',
              style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1620),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _buildTabButton(label: 'HOST ROOM', icon: Icons.wifi_tethering_rounded, index: 0),
          _buildTabButton(label: 'JOIN ROOM', icon: Icons.login_rounded, index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required IconData icon, required int index}) {
    final isSelected = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabIndex == index) return;
          AppAudio.play(context, 'click.mp3', 'Tab Switch');
          setState(() => _tabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0288D1)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.black : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.black : Colors.white60,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostTab(GameState state) {
    return Container(
      key: const ValueKey('host_tab'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR DEVICE LOCAL IP',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppTheme.textMuted),
              ),
              BouncyButton(
                onTap: () async {
                  AppAudio.play(context, 'click.mp3', 'Refreshing IP');
                  await _lan.refreshLocalIp();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF00E5FF)),
                      SizedBox(width: 4),
                      Text('REFRESH IP', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lan.localIp,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00E5FF),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text('PORT: 8080 (WEBSOCKET)', style: TextStyle(fontSize: 8.5, color: Colors.white38, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lan.localIp));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 IP address copied!'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: state.selectedCharacter.bodyColor,
                  child: Text(state.selectedCharacter.name[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                Text(
                  'LOADOUT: ${state.selectedCharacter.name.split(" ")[0].toUpperCase()} • ${state.selectedPaddle.name}',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HOST NOW BUTTON (TRANSITIONS TO HOSTING STATE)
          BouncyButton(
            onTap: _isHostingAction ? () {} : _onHostNowTapped,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: Center(
                child: _isHostingAction
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black)),
                          SizedBox(width: 8),
                          Text('HOSTING...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cell_tower_rounded, color: Colors.black, size: 20),
                          SizedBox(width: 6),
                          Text('HOST NOW!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab(GameState state) {
    final hasValidNetwork = _lan.localIp != '127.0.0.1' && _lan.localIp != 'Unavailable';

    return Container(
      key: const ValueKey('join_tab'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasValidNetwork ? const Color(0xFF00E676).withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: hasValidNetwork ? const Color(0xFF00E676) : Colors.redAccent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3.5, backgroundColor: hasValidNetwork ? const Color(0xFF00E676) : Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  hasValidNetwork ? 'NETWORK ACTIVE (${_lan.localIp})' : 'NO LOCAL NETWORK DETECTED',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: hasValidNetwork ? const Color(0xFF00E676) : Colors.redAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'ENTER HOST IP ADDRESS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: _ipController,
            keyboardType: TextInputType.datetime,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.5),
              hintText: '192.168.1.XX',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.router_rounded, color: Color(0xFF00E5FF), size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded, color: Colors.white70, size: 18),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    setState(() => _ipController.text = data!.text!.trim());
                  }
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.8)),
            ),
          ),

          if (_lan.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_lan.errorMessage, style: const TextStyle(fontSize: 9.5, color: Colors.redAccent)),
          ],

          const SizedBox(height: 16),

          BouncyButton(
            onTap: _isJoiningAction ? () {} : _onJoinNowTapped,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: Center(
                child: _isJoiningAction
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black)),
                          SizedBox(width: 8),
                          Text('CONNECTING...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_tennis_rounded, color: Colors.black, size: 18),
                          SizedBox(width: 6),
                          Text('JOIN NOW!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotHelper() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0B141C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: AppTheme.opticYellow, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No Wi-Fi? Turn on Mobile Hotspot on one phone, connect with the other. 0ms local ping!',
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // QOL MODALS
  // ==========================================================================
  void _showSettingsModal(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0C1613),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppTheme.opticYellow, width: 1.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PREFERENCES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.opticYellow,
                    title: const Text('Sound Effects (SFX)', style: TextStyle(fontSize: 13)),
                    value: state.soundEnabled,
                    onChanged: (val) {
                      state.toggleSound(val);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.opticYellow,
                    title: const Text('Haptic Vibration', style: TextStyle(fontSize: 13)),
                    value: state.hapticsEnabled,
                    onChanged: (val) {
                      state.toggleHaptics(val);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.mintAccent,
                    title: const Text('60 FPS High Performance', style: TextStyle(fontSize: 13)),
                    value: _highFpsEnabled,
                    onChanged: (val) => setModalState(() => _highFpsEnabled = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.mintAccent,
                    title: const Text('Screen Shake FX', style: TextStyle(fontSize: 13)),
                    value: _screenShakeEnabled,
                    onChanged: (val) => setModalState(() => _screenShakeEnabled = val),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                  const Text('SELECT ATHLETE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              for (final char in kCharacters) ...[
                GestureDetector(
                  onTap: () {
                    state.selectCharacter(char);
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
                        Expanded(
                          child: Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        ),
                        if (state.selectedCharacter.id == char.id)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 18),
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
                  const Text('EQUIP PADDLE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
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