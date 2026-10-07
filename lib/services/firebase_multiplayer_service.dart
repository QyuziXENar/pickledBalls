// lib/services/firebase_multiplayer_service.dart

import 'dart:async';

/// Step 4 Contract: Clean Firebase Realtime Database Service for branch-2.
/// Your groupmate can plug in the Firebase SDK directly here without 
/// altering any game rendering or physics code.
abstract class FirebaseMultiplayerContract {
  Stream<Map<String, dynamic>> listenToRoom(String roomCode);
  Future<void> createRoomRecord(String roomCode, Map<String, dynamic> initialData);
  Future<void> joinRoomRecord(String roomCode, Map<String, dynamic> playerData);
  Future<void> broadcastHitEvent(String roomCode, Map<String, dynamic> hitVector);
  Future<void> broadcastPosition(String roomCode, String playerRole, double x, double y);
  Future<void> updateMatchScore(String roomCode, int hostScore, int guestScore);
  Future<void> closeRoom(String roomCode);
}

/// Standalone Stub implementation that can be replaced with 
/// `FirebaseDatabase.instance.ref()` once Firebase is initialized on branch-2.
class FirebaseMultiplayerService implements FirebaseMultiplayerContract {
  static final FirebaseMultiplayerService instance = FirebaseMultiplayerService._();
  FirebaseMultiplayerService._();

  final StreamController<Map<String, dynamic>> _roomStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> listenToRoom(String roomCode) {
    // Branch-2: return FirebaseDatabase.instance.ref('rooms/$roomCode').onValue.map(...)
    return _roomStreamController.stream;
  }

  @override
  Future<void> createRoomRecord(String roomCode, Map<String, dynamic> initialData) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode').set(initialData);
  }

  @override
  Future<void> joinRoomRecord(String roomCode, Map<String, dynamic> playerData) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode/players/guest').set(playerData);
  }

  @override
  Future<void> broadcastHitEvent(String roomCode, Map<String, dynamic> hitVector) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode/matchState/lastHit').set(hitVector);
  }

  @override
  Future<void> broadcastPosition(String roomCode, String playerRole, double x, double y) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode/players/$playerRole/pos').set({'x': x, 'y': y});
  }

  @override
  Future<void> updateMatchScore(String roomCode, int hostScore, int guestScore) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode/matchState/scores').set({'host': hostScore, 'guest': guestScore});
  }

  @override
  Future<void> closeRoom(String roomCode) async {
    // Branch-2: await FirebaseDatabase.instance.ref('rooms/$roomCode').remove();
  }
}