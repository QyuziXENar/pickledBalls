import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

enum LanRole { none, host, guest }

enum LanStatus {
  disconnected,
  discovering,
  hosting,
  connecting,
  connected,
  error,
}

class LanMultiplayerManager extends ChangeNotifier {
  static final LanMultiplayerManager instance = LanMultiplayerManager._();
  LanMultiplayerManager._();

  static const int kDefaultPort = 8080;

  LanRole _role = LanRole.none;
  LanStatus _status = LanStatus.disconnected;
  String _localIp = 'Searching...';
  String _errorMessage = '';

  // Active sockets
  HttpServer? _server;
  WebSocket? _socket;
  StreamSubscription? _socketSub;

  // Remote Opponent Profile Data
  String _opponentName = 'Opponent';
  String _opponentAthleteId = 'aria';
  String _opponentPaddleId = 'volt_strike';

  // Packet Stream Controllers for Gameplay Screen
  final StreamController<Map<String, dynamic>> _incomingPacketController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  LanRole get role => _role;
  LanStatus get status => _status;
  String get localIp => _localIp;
  String get errorMessage => _errorMessage;
  bool get isConnected => _status == LanStatus.connected;
  bool get isHost => _role == LanRole.host;
  bool get isGuest => _role == LanRole.guest;

  String get opponentName => _opponentName;
  String get opponentAthleteId => _opponentAthleteId;
  String get opponentPaddleId => _opponentPaddleId;

  Stream<Map<String, dynamic>> get packetStream => _incomingPacketController.stream;

  // ==========================================================================
  // 1. DISCOVER LOCAL IP (Wi-Fi or Hotspot)
  // ==========================================================================
  Future<String> refreshLocalIp() async {
    _status = LanStatus.discovering;
    notifyListeners();

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _localIp = addr.address;
            _status = LanStatus.disconnected;
            notifyListeners();
            return _localIp;
          }
        }
      }

      _localIp = '127.0.0.1';
      _status = LanStatus.disconnected;
      notifyListeners();
      return _localIp;
    } catch (e) {
      _localIp = 'Unavailable';
      _status = LanStatus.error;
      _errorMessage = 'Could not find local Wi-Fi/Hotspot IP: $e';
      notifyListeners();
      return _localIp;
    }
  }

  // ==========================================================================
  // 2. START HOSTING (Phone 1 spins up the server)
  // ==========================================================================
  Future<void> startHost({int port = kDefaultPort}) async {
    await disconnect();

    _role = LanRole.host;
    _status = LanStatus.hosting;
    _errorMessage = '';
    notifyListeners();

    try {
      await refreshLocalIp();

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('LAN Match Server listening on $_localIp:$port');

      // Listen for incoming WebSocket upgrades from Player 2 (Guest)
      _server!.transform(WebSocketTransformer()).listen(
        (WebSocket clientSocket) {
          if (_socket != null) {
            // Only allow 1 opponent in a 1v1 duel
            clientSocket.close(WebSocketStatus.normalClosure, 'Room is full (1v1 only)');
            return;
          }

          _socket = clientSocket;
          _status = LanStatus.connected;
          notifyListeners();

          _setupSocketListener();

          // Send Host Profile Handshake
          _sendHandshake();
        },
        onError: (err) {
          _status = LanStatus.error;
          _errorMessage = 'Server error: $err';
          notifyListeners();
        },
      );
    } catch (e) {
      _status = LanStatus.error;
      _errorMessage = 'Failed to bind port $port. Is another app using it?';
      notifyListeners();
    }
  }

  // ==========================================================================
  // 3. JOIN AS GUEST (Phone 2 connects to Phone 1's IP)
  // ==========================================================================
  Future<bool> joinMatch(String hostIp, {int port = kDefaultPort}) async {
    await disconnect();

    _role = LanRole.guest;
    _status = LanStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    final cleanIp = hostIp.trim();

    try {
      final wsUrl = 'ws://$cleanIp:$port';
      debugPrint('Connecting to host at $wsUrl...');

      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 6),
      );

      _status = LanStatus.connected;
      notifyListeners();

      _setupSocketListener();

      // Send Guest Profile Handshake
      _sendHandshake();
      return true;
    } on TimeoutException {
      _status = LanStatus.error;
      _errorMessage = 'Connection timed out. Check IP & ensure both phones are on same Wi-Fi/Hotspot.';
      notifyListeners();
      return false;
    } catch (e) {
      _status = LanStatus.error;
      _errorMessage = 'Could not connect to $cleanIp:$port. Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 4. SOCKET LISTENER & PACKET DECODER
  // ==========================================================================
  void _setupSocketListener() {
    _socketSub = _socket?.listen(
      (data) {
        try {
          final Map<String, dynamic> packet = jsonDecode(data.toString());

          // Handle Internal Handshakes
          if (packet['type'] == 'handshake') {
            _opponentName = packet['name'] ?? 'Rival Player';
            _opponentAthleteId = packet['athleteId'] ?? 'jax';
            _opponentPaddleId = packet['paddleId'] ?? 'volt_strike';
            notifyListeners();
          }

          // Broadcast to gameplay listener
          _incomingPacketController.add(packet);
        } catch (e) {
          debugPrint('Error parsing LAN packet: $e');
        }
      },
      onDone: () {
        debugPrint('LAN Socket closed by peer.');
        _handlePeerDisconnected();
      },
      onError: (err) {
        debugPrint('LAN Socket error: $err');
        _handlePeerDisconnected();
      },
      cancelOnError: true,
    );
  }

  void _sendHandshake() {
    final state = GameState.instance;
    sendPacket({
      'type': 'handshake',
      'name': 'Player ${isHost ? '1 (Host)' : '2 (Guest)'}',
      'athleteId': state.selectedCharacter.id,
      'paddleId': state.selectedPaddle.id,
    });
  }

  void _handlePeerDisconnected() {
    _status = isHost ? LanStatus.hosting : LanStatus.disconnected;
    _socketSub?.cancel();
    _socket = null;
    notifyListeners();
  }

  // ==========================================================================
  // 5. PACKET SENDER (Used by Gameplay Engine at 30-60 FPS)
  // ==========================================================================
  void sendPacket(Map<String, dynamic> data) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _socket!.add(jsonEncode(data));
      } catch (e) {
        debugPrint('Error sending packet: $e');
      }
    }
  }

  // ==========================================================================
  // 6. TEARDOWN & CLEANUP
  // ==========================================================================
  Future<void> disconnect() async {
    await _socketSub?.cancel();
    _socketSub = null;

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }

    _role = LanRole.none;
    _status = LanStatus.disconnected;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _incomingPacketController.close();
    super.dispose();
  }
}