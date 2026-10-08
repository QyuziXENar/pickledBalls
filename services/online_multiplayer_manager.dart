// lib/services/online_multiplayer_manager.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import 'firebase_multiplayer_service.dart';

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

  final FirebaseMultiplayerService _firebaseService = FirebaseMultiplayerService.instance;

  static bool useMockBackend = false;

  OnlineStatus _status = OnlineStatus.disconnected;
  OnlineMatchMode _matchMode = OnlineMatchMode.quickMatch;
  String _activeRoomCode = '';
  String _errorMessage = '';
  int _estimatedPingMs = 34;

  bool _isHost = false;
  String _opponentName = 'Online Rival';
  String _opponentAthleteId = 'marcus';
  String _opponentPaddleId = 'volt_strike';
  bool _isOpponentReady = false;

  // Authoritative Persistent Room Settings
  int _roomVenueIdx = 0;
  String _roomVenueName = 'Tournament Arena';
  int _roomTargetScore = 11;

  StreamSubscription<Map<String, dynamic>>? _roomSubscription;
  StreamSubscription? _remotePlayerSub;
  StreamSubscription? _ballSub;
  StreamSubscription? _remoteActionSub;

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
  bool get isHost => _isHost;
  String get opponentName => _opponentName;
  String get opponentAthleteId => _opponentAthleteId;
  String get opponentPaddleId => _opponentPaddleId;
  bool get isOpponentReady => _isOpponentReady;

  int get roomVenueIdx => _roomVenueIdx;
  String get roomVenueName => _roomVenueName;
  int get roomTargetScore => _roomTargetScore;

  Stream<Map<String, dynamic>> get packetStream => _incomingPacketController.stream;

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
      final queueSnapshot = await _firebaseService.matchmakingQueueRef.get();

      if (queueSnapshot.exists && queueSnapshot.value != null) {
        final queueMap = queueSnapshot.value as Map<dynamic, dynamic>;

        for (final entry in queueMap.entries) {
          final ticketKey = entry.key.toString();
          final ticketData = entry.value;

          if (ticketData is Map && ticketData['roomCode'] != null) {
            final candidateCode = ticketData['roomCode'].toString();
            final joined = await joinPrivateRoom(candidateCode);

            if (joined) {
              await _firebaseService.matchmakingQueueRef.child(ticketKey).remove();
              return;
            }
          }
        }
      }

      final roomCode = await createPrivateRoom();
      if (roomCode.isNotEmpty) {
        _status = OnlineStatus.inQueue;
        notifyListeners();

        final ticketRef = _firebaseService.matchmakingQueueRef.push();
        await ticketRef.set({
          'roomCode': roomCode,
          'createdAt': ServerValue.timestamp,
        });

        try {
          await ticketRef.onDisconnect().remove();
        } catch (_) {}
      }
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Quick match error: $e';
      notifyListeners();
    }
  }

  Future<String> createPrivateRoom() async {
    await disconnect();
    _matchMode = OnlineMatchMode.privateRoom;
    _isHost = true;

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    _activeRoomCode = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();

    _status = OnlineStatus.roomCreated;
    _errorMessage = '';
    notifyListeners();

    if (useMockBackend) {
      return _activeRoomCode;
    }

    final state = GameState.instance;

    final initialRoomData = {
      'roomCode': _activeRoomCode,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'venue': state.courtVenue,
      'targetScore': state.targetScore,
      'settings': {
        'venueIdx': 0,
        'venueName': state.courtVenue,
        'targetScore': state.targetScore,
      },
      'host': {
        'id': 'host_${state.selectedCharacter.id}',
        'name': state.selectedCharacter.name.split(' ')[0],
        'athleteId': state.selectedCharacter.id,
        'paddleId': state.selectedPaddle.id,
        'ready': false,
      },
      'guest': null,
      'matchState': {
        'scores': {'host': 0, 'guest': 0},
      },
    };

    try {
      await _firebaseService.createRoomRecord(_activeRoomCode, initialRoomData);
      _subscribeToRoom(_activeRoomCode);
      return _activeRoomCode;
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Failed to create room: $e';
      notifyListeners();
      return '';
    }
  }

  Future<bool> joinPrivateRoom(String roomCode) async {
    await disconnect();
    final cleanCode = roomCode.trim().toUpperCase();

    if (cleanCode.length != 4) {
      _errorMessage = 'Code must be exactly 4 letters';
      _status = OnlineStatus.error;
      notifyListeners();
      return false;
    }

    _matchMode = OnlineMatchMode.privateRoom;
    _activeRoomCode = cleanCode;
    _isHost = false;
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

    final state = GameState.instance;

    final guestData = {
      'id': 'guest_${state.selectedCharacter.id}',
      'name': state.selectedCharacter.name.split(' ')[0],
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
      'ready': false,
    };

    try {
      final success = await _firebaseService.joinRoomRecord(_activeRoomCode, guestData);

      if (!success) {
        _status = OnlineStatus.error;
        _errorMessage = 'Room not found or already full.';
        notifyListeners();
        return false;
      }

      _subscribeToRoom(_activeRoomCode);
      return true;
    } catch (e) {
      _status = OnlineStatus.error;
      _errorMessage = 'Failed to join: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateRoomSettings({
    required int venueIdx,
    required String venueName,
    required int targetScore,
  }) async {
    if (_activeRoomCode.isEmpty) return;
    _roomVenueIdx = venueIdx;
    _roomVenueName = venueName;
    _roomTargetScore = targetScore;
    try {
      await _firebaseService.updateRoomSettings(_activeRoomCode, {
        'venueIdx': venueIdx,
        'venueName': venueName,
        'targetScore': targetScore,
      });
    } catch (e) {
      debugPrint('[RTDB] Failed to update room settings: $e');
    }
  }

  // ==========================================================================
  // DEDICATED CHANNEL SUBSCRIPTION LOGIC (ZERO CLOBBERING)
  // ==========================================================================
  void _subscribeToRoom(String roomCode) {
    _roomSubscription?.cancel();
    _roomSubscription = _firebaseService.listenToRoom(roomCode).listen(
      (roomData) {
        if (!roomData['exists'] && _status == OnlineStatus.connected) {
          _handlePeerDisconnected('Match closed by host.');
          return;
        }

        // Authoritative Room Settings Sync from database
        if (roomData['settings'] != null) {
          final settings = roomData['settings'] as Map<String, dynamic>;
          _roomVenueIdx = (settings['venueIdx'] as num?)?.toInt() ?? _roomVenueIdx;
          _roomVenueName = (settings['venueName'] as String?) ?? _roomVenueName;
          _roomTargetScore = (settings['targetScore'] as num?)?.toInt() ?? _roomTargetScore;
        }

        if (_isHost) {
          if (roomData['guest'] != null) {
            final guest = roomData['guest'] as Map<String, dynamic>;
            _opponentName = guest['name'] ?? 'Challenger';
            _opponentAthleteId = guest['athleteId'] ?? 'marcus';
            _opponentPaddleId = guest['paddleId'] ?? 'volt_strike';
            _isOpponentReady = guest['ready'] == true;

            if (_status != OnlineStatus.connected) {
              _status = OnlineStatus.connected;
            }
          } else {
            _isOpponentReady = false;
            if (_status == OnlineStatus.connected) {
              _status = OnlineStatus.roomCreated;
            }
          }
        } else {
          if (roomData['host'] != null) {
            final host = roomData['host'] as Map<String, dynamic>;
            _opponentName = host['name'] ?? 'Host';
            _opponentAthleteId = host['athleteId'] ?? 'aria';
            _opponentPaddleId = host['paddleId'] ?? 'volt_strike';
            _isOpponentReady = host['ready'] == true;

            if (_status != OnlineStatus.connected) {
              _status = OnlineStatus.connected;
            }
          }
        }

        notifyListeners();
      },
      onError: (err) {
        _status = OnlineStatus.error;
        _errorMessage = 'Room synchronization error: $err';
        notifyListeners();
      },
    );

    // Bind real-time isolated telemetry streams
    final remoteRole = _isHost ? 'guest' : 'host';

    _remotePlayerSub?.cancel();
    _remotePlayerSub = _firebaseService.listenToPlayerTelemetry(roomCode, remoteRole).listen((data) {
      if (data.isNotEmpty) {
        _incomingPacketController.add(data);
      }
    });

    if (!_isHost) {
      _ballSub?.cancel();
      _ballSub = _firebaseService.listenToBallTelemetry(roomCode).listen((data) {
        if (data.isNotEmpty) {
          _incomingPacketController.add(data);
        }
      });
    }

    _remoteActionSub?.cancel();
    _remoteActionSub = _firebaseService.listenToGameAction(roomCode, remoteRole).listen((data) {
      if (data.isNotEmpty) {
        _incomingPacketController.add(data);
      }
    });
  }

  // ==========================================================================
  // DISPATCH OVER DEDICATED CHANNELS
  // ==========================================================================
  void sendPacket(Map<String, dynamic> data) {
    if (_activeRoomCode.isEmpty) return;

    if (useMockBackend) {
      _processMockSandboxPacket(data);
      return;
    }

    final role = _isHost ? 'host' : 'guest';
    final type = data['type'];

    if (type == 'pos') {
      _firebaseService.updatePlayerTelemetry(_activeRoomCode, role, data);
    } else if (type == 'ball_sync') {
      if (_isHost) {
        _firebaseService.updateBallTelemetry(_activeRoomCode, data);
      }
    } else {
      // Actions: serve_toss, serve_strike, ball_hit, point_resolved, chat, challenger_ready, start_match
      _firebaseService.sendGameAction(_activeRoomCode, role, data);
    }
  }

  void _processMockSandboxPacket(Map<String, dynamic> packet) {
    if (packet['type'] == 'chat') {
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
    if (_activeRoomCode.isEmpty) return;
    final role = _isHost ? 'host' : 'guest';
    _firebaseService.sendGameAction(_activeRoomCode, role, {
      'type': 'challenger_ready',
      'isReady': isReady,
    });
  }

  void _handlePeerDisconnected(String message) {
    _status = OnlineStatus.disconnected;
    _errorMessage = message;
    _roomSubscription?.cancel();
    _remotePlayerSub?.cancel();
    _ballSub?.cancel();
    _remoteActionSub?.cancel();
    notifyListeners();
  }

  Future<void> disconnect() async {
    _mockMatchmakingTimer?.cancel();
    _mockRivalChatTimer?.cancel();

    await _roomSubscription?.cancel();
    _roomSubscription = null;
    await _remotePlayerSub?.cancel();
    _remotePlayerSub = null;
    await _ballSub?.cancel();
    _ballSub = null;
    await _remoteActionSub?.cancel();
    _remoteActionSub = null;

    if (_isHost && _activeRoomCode.isNotEmpty && !useMockBackend) {
      await _firebaseService.closeRoom(_activeRoomCode);
    }

    _status = OnlineStatus.disconnected;
    _activeRoomCode = '';
    _errorMessage = '';
    _isOpponentReady = false;
    _roomVenueIdx = 0;
    _roomVenueName = 'Tournament Arena';
    _roomTargetScore = 11;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _incomingPacketController.close();
    super.dispose();
  }
}