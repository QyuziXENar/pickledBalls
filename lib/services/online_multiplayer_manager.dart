// lib/services/online_multiplayer_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

enum OnlineStatus {
  disconnected,
  connecting,
  inQueue,
  roomCreated,
  roomJoined,
  connected,
  error,
}

enum OnlineMatchMode { quickMatch, privateRoom }

class OnlineMultiplayerManager extends ChangeNotifier {
  static final OnlineMultiplayerManager instance = OnlineMultiplayerManager._();
  OnlineMultiplayerManager._();

  // ==========================================================================
  // BACKEND SWITCH (FOR JOHNMARK ON BRANCH-2)
  // ==========================================================================
  /// Set to false when your groupmate's server / database is live!
  static bool useMockBackend = true;
  static String cloudServerUrl = 'wss://relay.paddleblitz.com/ws';

  OnlineStatus _status = OnlineStatus.disconnected;
  OnlineMatchMode _matchMode = OnlineMatchMode.quickMatch;
  String _activeRoomCode = '';
  String _errorMessage = '';
  int _estimatedPingMs = 34;

  WebSocket? _cloudSocket;
  StreamSubscription? _socketSub;

  String _opponentName = 'Online Rival';
  String _opponentAthleteId = 'marcus';
  String _opponentPaddleId = 'volt_strike';
  bool _isOpponentReady = false;

  final StreamController<Map<String, dynamic>> _incomingPacketController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _mockMatchmakingTimer;
  Timer? _mockRivalChatTimer;

  // Getters
  OnlineStatus get status => _status;
  OnlineMatchMode get matchMode => _matchMode;
  String get activeRoomCode => _activeRoomCode;
  String get errorMessage => _errorMessage;
  int get estimatedPingMs => _estimatedPingMs;
  bool get isConnected => _status == OnlineStatus.connected;
  String get opponentName => _opponentName;
  String get opponentAthleteId => _opponentAthleteId;
  String get opponentPaddleId => _opponentPaddleId;
  bool get isOpponentReady => _isOpponentReady;
  Stream<Map<String, dynamic>> get packetStream => _incomingPacketController.stream;

  // ==========================================================================
  // 1. QUICK MATCH (GLOBAL SEARCH)
  // ==========================================================================
  Future<void> startQuickMatch() async {
    await disconnect();
    _matchMode = OnlineMatchMode.quickMatch;
    _status = OnlineStatus.inQueue;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      _mockMatchmakingTimer?.cancel();
      _mockMatchmakingTimer = Timer(const Duration(milliseconds: 2400), () {
        _opponentName = 'Alex_DinkKing';
        _opponentAthleteId = 'aria';
        _opponentPaddleId = 'titan_carbon';
        _status = OnlineStatus.connected;
        _estimatedPingMs = 32 + math.Random().nextInt(14);
        _scheduleMockRivalResponses();
        notifyListeners();
      });
      return;
    }

    try {
      _cloudSocket = await WebSocket.connect(cloudServerUrl).timeout(
        const Duration(seconds: 8),
      );
      _setupSocketListener();

      sendPacket({
        'action': 'quick_match_queue',
        'playerId': GameState.instance.selectedCharacter.id,
        'level': GameState.instance.playerLevel,
      });
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Cloud connection error: $e';
      notifyListeners();
    }
  }

  // ==========================================================================
  // 2. PRIVATE ROOM: CREATE (4-LETTER CODE)
  // ==========================================================================
  Future<String> createPrivateRoom() async {
    await disconnect();
    _matchMode = OnlineMatchMode.privateRoom;

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    _activeRoomCode = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();

    _status = OnlineStatus.roomCreated;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      return _activeRoomCode;
    }

    try {
      _cloudSocket = await WebSocket.connect(cloudServerUrl);
      _setupSocketListener();

      sendPacket({
        'action': 'create_private_room',
        'roomCode': _activeRoomCode,
        'hostAthleteId': GameState.instance.selectedCharacter.id,
      });
      return _activeRoomCode;
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Could not create room: $e';
      notifyListeners();
      return '';
    }
  }

  // ==========================================================================
  // 3. PRIVATE ROOM: JOIN WITH CODE
  // ==========================================================================
  Future<bool> joinPrivateRoom(String roomCode) async {
    await disconnect();
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.length != 4) {
      _errorMessage = 'Code must be 4 characters';
      notifyListeners();
      return false;
    }

    _matchMode = OnlineMatchMode.privateRoom;
    _activeRoomCode = cleanCode;
    _status = OnlineStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1200));
      _opponentName = 'Host_BenJ';
      _opponentAthleteId = 'marcus';
      _opponentPaddleId = 'volt_strike';
      _status = OnlineStatus.connected;
      _isOpponentReady = true;
      _scheduleMockRivalResponses();
      notifyListeners();
      return true;
    }

    try {
      _cloudSocket = await WebSocket.connect(cloudServerUrl);
      _setupSocketListener();

      sendPacket({
        'action': 'join_private_room',
        'roomCode': _activeRoomCode,
        'guestAthleteId': GameState.instance.selectedCharacter.id,
      });
      return true;
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 4. REAL-TIME GAMEPLAY PACKET PIPELINE
  // ==========================================================================
  void _setupSocketListener() {
    _socketSub = _cloudSocket?.listen(
      (data) {
        try {
          final Map<String, dynamic> packet = jsonDecode(data.toString());

          if (packet['type'] == 'match_found' || packet['type'] == 'peer_joined') {
            _opponentName = packet['opponentName'] ?? 'Rival Player';
            _opponentAthleteId = packet['athleteId'] ?? 'aria';
            _opponentPaddleId = packet['paddleId'] ?? 'volt_strike';
            _status = OnlineStatus.connected;
            notifyListeners();
          } else if (packet['type'] == 'opponent_ready') {
            _isOpponentReady = packet['isReady'] == true;
            notifyListeners();
          }

          _incomingPacketController.add(packet);
        } catch (e) {
          debugPrint('Online packet error: $e');
        }
      },
      onDone: () => _handleDisconnected(),
      onError: (err) => _handleError(err.toString()),
      cancelOnError: true,
    );
  }

  void sendPacket(Map<String, dynamic> data) {
    if (_cloudSocket != null && _cloudSocket!.readyState == WebSocket.open) {
      try {
        _cloudSocket!.add(jsonEncode(data));
      } catch (e) {
        debugPrint('Error sending online packet: $e');
      }
    } else if (useMockBackend) {
      // In sandbox mode, process local game loop packets
      _processMockSandboxPacket(data);
    }
  }

  void _processMockSandboxPacket(Map<String, dynamic> packet) {
    if (packet['type'] == 'chat') {
      // Rival responds with friendly sportsmanship chat after 2 seconds
      _mockRivalChatTimer?.cancel();
      _mockRivalChatTimer = Timer(const Duration(milliseconds: 1800), () {
        _incomingPacketController.add({
          'type': 'chat',
          'text': math.Random().nextBool() ? 'Paddle Tap! 🤝' : 'Nice dink! 🎯',
        });
      });
    }
  }

  void _scheduleMockRivalResponses() {
    // Intermittent ping fluctuation simulation (28ms - 42ms)
    Timer.periodic(const Duration(seconds: 4), (t) {
      if (_status != OnlineStatus.connected) {
        t.cancel();
        return;
      }
      _estimatedPingMs = 28 + math.Random().nextInt(14);
      notifyListeners();
    });
  }

  void toggleReadyState(bool isReady) {
    sendPacket({
      'type': 'player_ready',
      'isReady': isReady,
      'roomCode': _activeRoomCode,
    });
  }

  void _handleDisconnected() {
    _status = OnlineStatus.disconnected;
    _socketSub?.cancel();
    _cloudSocket = null;
    notifyListeners();
  }

  void _handleError(String error) {
    _status = OnlineStatus.error;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _mockMatchmakingTimer?.cancel();
    _mockRivalChatTimer?.cancel();
    await _socketSub?.cancel();
    _socketSub = null;

    if (_cloudSocket != null) {
      await _cloudSocket!.close();
      _cloudSocket = null;
    }

    _status = OnlineStatus.disconnected;
    _activeRoomCode = '';
    _errorMessage = '';
    _isOpponentReady = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _incomingPacketController.close();
    super.dispose();
  }
}