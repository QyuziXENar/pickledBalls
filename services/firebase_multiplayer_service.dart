// lib/services/firebase_multiplayer_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

abstract class FirebaseMultiplayerContract {
  Stream<Map<String, dynamic>> listenToRoom(String roomCode);
  Future<void> createRoomRecord(String roomCode, Map<String, dynamic> initialData);
  Future<bool> joinRoomRecord(String roomCode, Map<String, dynamic> playerData);
  Future<void> updateRoomSettings(String roomCode, Map<String, dynamic> settings);
  Future<void> closeRoom(String roomCode);

  // Dedicated real-time channels
  Future<void> updatePlayerTelemetry(String roomCode, String role, Map<String, dynamic> telemetry);
  Stream<Map<String, dynamic>> listenToPlayerTelemetry(String roomCode, String role);

  Future<void> updateBallTelemetry(String roomCode, Map<String, dynamic> telemetry);
  Stream<Map<String, dynamic>> listenToBallTelemetry(String roomCode);

  Future<void> sendGameAction(String roomCode, String role, Map<String, dynamic> action);
  Stream<Map<String, dynamic>> listenToGameAction(String roomCode, String role);

  // Backward-compatible methods
  Future<void> broadcastHitEvent(String roomCode, Map<String, dynamic> hitVector);
  Future<void> broadcastPosition(String roomCode, String playerRole, double x, double y);
  Future<void> updateMatchScore(String roomCode, int hostScore, int guestScore);
  Future<void> sendRoomPacket(String roomCode, String senderRole, Map<String, dynamic> packet);
}

class FirebaseMultiplayerService implements FirebaseMultiplayerContract {
  static final FirebaseMultiplayerService instance = FirebaseMultiplayerService._();
  FirebaseMultiplayerService._();

  static const String singaporeRtdbUrl =
      'https://paddle-blitz-default-rtdb.asia-southeast1.firebasedatabase.app';

  FirebaseDatabase? _customDatabase;

  FirebaseDatabase get _database {
    if (_customDatabase != null) return _customDatabase!;
    try {
      _customDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: singaporeRtdbUrl,
      );
    } catch (_) {
      _customDatabase = FirebaseDatabase.instance;
    }
    return _customDatabase!;
  }

  DatabaseReference _roomRef(String roomCode) {
    final cleanCode = roomCode.trim().toUpperCase();
    return _database.ref('rooms/$cleanCode');
  }

  DatabaseReference get matchmakingQueueRef {
    return _database.ref('matchmaking_queue');
  }

  @override
  Stream<Map<String, dynamic>> listenToRoom(String roomCode) {
    return _roomRef(roomCode).onValue.map((DatabaseEvent event) {
      final value = event.snapshot.value;
      if (value == null) {
        return <String, dynamic>{'exists': false};
      }
      final converted = _deepConvert(value);
      if (converted is Map<String, dynamic>) {
        converted['exists'] = true;
        return converted;
      }
      return <String, dynamic>{'exists': true, 'data': converted};
    });
  }

  @override
  Future<void> createRoomRecord(String roomCode, Map<String, dynamic> initialData) async {
    final ref = _roomRef(roomCode);
    await ref.set(initialData);

    try {
      await ref.onDisconnect().remove();
    } catch (e) {
      debugPrint('[RTDB] onDisconnect hook notice: $e');
    }
  }

  @override
  Future<bool> joinRoomRecord(String roomCode, Map<String, dynamic> playerData) async {
    final ref = _roomRef(roomCode);
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) {
      return false;
    }

    final data = _deepConvert(snapshot.value);
    if (data is Map && data['guest'] != null) {
      final guestData = data['guest'];
      if (guestData is Map && guestData['id'] != playerData['id']) {
        return false;
      }
    }

    await ref.child('guest').set(playerData);
    await ref.child('status').set('connected');
    return true;
  }

  @override
  Future<void> updateRoomSettings(String roomCode, Map<String, dynamic> settings) async {
    await _roomRef(roomCode).child('settings').update(settings);
  }

  // ==========================================================================
  // DEDICATED DUAL-CHANNEL REALTIME ENGINE METHODS
  // ==========================================================================
  @override
  Future<void> updatePlayerTelemetry(String roomCode, String role, Map<String, dynamic> telemetry) async {
    try {
      await _roomRef(roomCode).child('players/$role').set(telemetry);
    } catch (_) {}
  }

  @override
  Stream<Map<String, dynamic>> listenToPlayerTelemetry(String roomCode, String role) {
    return _roomRef(roomCode).child('players/$role').onValue.map((DatabaseEvent event) {
      final value = event.snapshot.value;
      if (value == null) return <String, dynamic>{};
      final converted = _deepConvert(value);
      if (converted is Map<String, dynamic>) return converted;
      return <String, dynamic>{'data': converted};
    });
  }

  @override
  Future<void> updateBallTelemetry(String roomCode, Map<String, dynamic> telemetry) async {
    try {
      await _roomRef(roomCode).child('ball').set(telemetry);
    } catch (_) {}
  }

  @override
  Stream<Map<String, dynamic>> listenToBallTelemetry(String roomCode) {
    return _roomRef(roomCode).child('ball').onValue.map((DatabaseEvent event) {
      final value = event.snapshot.value;
      if (value == null) return <String, dynamic>{};
      final converted = _deepConvert(value);
      if (converted is Map<String, dynamic>) return converted;
      return <String, dynamic>{'data': converted};
    });
  }

  @override
  Future<void> sendGameAction(String roomCode, String role, Map<String, dynamic> action) async {
    try {
      final payload = Map<String, dynamic>.from(action)
        ..['sender'] = role
        ..['t'] = ServerValue.timestamp;
      await _roomRef(roomCode).child('actions/$role').set(payload);
    } catch (_) {}
  }

  @override
  Stream<Map<String, dynamic>> listenToGameAction(String roomCode, String role) {
    return _roomRef(roomCode).child('actions/$role').onValue.map((DatabaseEvent event) {
      final value = event.snapshot.value;
      if (value == null) return <String, dynamic>{};
      final converted = _deepConvert(value);
      if (converted is Map<String, dynamic>) return converted;
      return <String, dynamic>{'data': converted};
    });
  }

  // ==========================================================================
  // BACKWARD-COMPATIBLE HOOKS
  // ==========================================================================
  @override
  Future<void> broadcastHitEvent(String roomCode, Map<String, dynamic> hitVector) async {
    await _roomRef(roomCode).child('matchState/lastHit').set(hitVector);
  }

  @override
  Future<void> broadcastPosition(String roomCode, String playerRole, double x, double y) async {
    await _roomRef(roomCode).child('positions/$playerRole').set({
      'x': x,
      'y': y,
      't': ServerValue.timestamp,
    });
  }

  @override
  Future<void> updateMatchScore(String roomCode, int hostScore, int guestScore) async {
    await _roomRef(roomCode).child('matchState/scores').set({
      'host': hostScore,
      'guest': guestScore,
    });
  }

  @override
  Future<void> sendRoomPacket(String roomCode, String senderRole, Map<String, dynamic> packet) async {
    final payload = Map<String, dynamic>.from(packet)
      ..['sender'] = senderRole
      ..['timestamp'] = ServerValue.timestamp;

    await _roomRef(roomCode).child('lastPacket').set(payload);
  }

  @override
  Future<void> closeRoom(String roomCode) async {
    try {
      await _roomRef(roomCode).remove();
    } catch (e) {
      debugPrint('[RTDB] Error closing room $roomCode: $e');
    }
  }

  dynamic _deepConvert(dynamic input) {
    if (input is Map) {
      final Map<String, dynamic> result = {};
      input.forEach((key, value) {
        result[key.toString()] = _deepConvert(value);
      });
      return result;
    } else if (input is List) {
      return input.map(_deepConvert).toList();
    }
    return input;
  }
}