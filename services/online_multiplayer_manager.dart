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
  // BACKEND INTEGRATION CONFIGURATION (FOR YOUR GROUPMATE)
  // ==========================================================================
  /// Set to false when your groupmate's WebSocket / Cloud server is deployed!
  static bool useMockBackend = true;

  /// Replace with your groupmate's server URL (e.g. wss://api.paddleblitz.com/ws)
  static String cloudServerUrl = 'wss://relay.paddleblitz.com/ws';

  OnlineStatus _status = OnlineStatus.disconnected;
  OnlineMatchMode _matchMode = OnlineMatchMode.quickMatch;
  String _activeRoomCode = '';
  String _errorMessage = '';
  int _estimatedPingMs = 32;

  // Active WebSocket Connection
  WebSocket? _cloudSocket;
  StreamSubscription? _socketSub;

  // Remote Rival Profile
  String _opponentName = 'Online Rival';
  String _opponentAthleteId = 'marcus';
  String _opponentPaddleId = 'volt_strike';
  bool _isOpponentReady = false;

  // Packet Stream for Gameplay Engine
  final StreamController<Map<String, dynamic>> _incomingPacketController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _mockMatchmakingTimer;

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
  // 1. QUICK MATCH QUEUE (AUTOMATIC MATCHMAKING)
  // ==========================================================================
  Future<void> startQuickMatch() async {
    await disconnect();
    _matchMode = OnlineMatchMode.quickMatch;
    _status = OnlineStatus.inQueue;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      // Simulates real-world cloud server handshake after 2.5 seconds
      _mockMatchmakingTimer?.cancel();
      _mockMatchmakingTimer = Timer(const Duration(milliseconds: 2600), () {
        _opponentName = 'Speedster_Alex';
        _opponentAthleteId = 'aria';
        _opponentPaddleId = 'titan_carbon';
        _status = OnlineStatus.connected;
        _estimatedPingMs = 28 + math.Random().nextInt(16);
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
      _errorMessage = 'Cloud server connection failed: $e';
      notifyListeners();
    }
  }

  // ==========================================================================
  // 2. PRIVATE CUSTOM ROOM: CREATE (GENERATES 4-LETTER CODE)
  // ==========================================================================
  Future<String> createPrivateRoom() async {
    await disconnect();
    _matchMode = OnlineMatchMode.privateRoom;

    // Generates a readable 4-letter room code (e.g. BLTZ, ACES, SLAM)
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
      _errorMessage = 'Could not create private room: $e';
      notifyListeners();
      return '';
    }
  }

  // ==========================================================================
  // 3. PRIVATE CUSTOM ROOM: JOIN (WITH 4-LETTER CODE)
  // ==========================================================================
  Future<bool> joinPrivateRoom(String roomCode) async {
    await disconnect();
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.length != 4) {
      _errorMessage = 'Room code must be 4 characters';
      notifyListeners();
      return false;
    }

    _matchMode = OnlineMatchMode.privateRoom;
    _activeRoomCode = cleanCode;
    _status = OnlineStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1400));
      _opponentName = 'Challenger_Dan';
      _opponentAthleteId = 'jax';
      _opponentPaddleId = 'volt_strike';
      _status = OnlineStatus.connected;
      _isOpponentReady = true;
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
      _errorMessage = 'Could not connect to room $cleanCode: $e';
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 4. REAL-TIME PACKET PIPELINE (SAME SCHEMA AS LAN MANAGER)
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
          debugPrint('Error parsing online packet: $e');
        }
      },
      onDone: () => _handleServerDisconnected(),
      onError: (err) => _handleServerError(err.toString()),
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
    }
  }

  void toggleReadyState(bool isReady) {
    sendPacket({
      'type': 'player_ready',
      'isReady': isReady,
      'roomCode': _activeRoomCode,
    });
  }

  void _handleServerDisconnected() {
    _status = OnlineStatus.disconnected;
    _socketSub?.cancel();
    _cloudSocket = null;
    notifyListeners();
  }

  void _handleServerError(String error) {
    _status = OnlineStatus.error;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _mockMatchmakingTimer?.cancel();
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