import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/memory_item.dart';
import 'local_database_service.dart';

enum CloudSyncState { synced, syncing, pending, offline, error }

class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._internal();
  FirebaseSyncService._internal();

  bool _isInitialized = false;
  CloudSyncState _syncState = CloudSyncState.offline;
  DateTime? _lastSyncedAt;
  StreamSubscription? _remoteSubscription;

  final _syncStateController = StreamController<CloudSyncState>.broadcast();
  Stream<CloudSyncState> get syncStateStream => _syncStateController.stream;
  CloudSyncState get syncState => _syncState;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isInitialized => _isInitialized;

  void _setSyncState(CloudSyncState state) {
    _syncState = state;
    _syncStateController.add(state);
  }

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      _setSyncState(CloudSyncState.synced);
      _ensureAuth();
    } catch (e) {
      debugPrint(
        "Firebase initialization notice: App running in offline-first mode ($e)",
      );
      _isInitialized = false;
      _setSyncState(CloudSyncState.offline);
    }
  }

  Future<String?> _getUserId() async {
    if (!_isInitialized) return null;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        final credential = await auth.signInAnonymously();
        return credential.user?.uid;
      }
      return auth.currentUser?.uid;
    } catch (e) {
      debugPrint("Firebase auth error: $e");
      return null;
    }
  }

  void _ensureAuth() async {
    await _getUserId();
  }

  Future<void> syncWithCloud({
    required Function(List<MemoryItem>) onLocalDataChanged,
  }) async {
    if (!_isInitialized) {
      _setSyncState(CloudSyncState.offline);
      return;
    }

    final uid = await _getUserId();
    if (uid == null) {
      _setSyncState(CloudSyncState.offline);
      return;
    }

    try {
      _setSyncState(CloudSyncState.syncing);

      final db = LocalDatabaseService.instance;
      final firestore = FirebaseFirestore.instance;
      final userMemoriesRef = firestore
          .collection('users')
          .doc(uid)
          .collection('memories');

      // 1. Push pending local mutations to Firestore
      final pendingItems = await db.getPendingSyncItems();
      for (final item in pendingItems) {
        if (item.syncStatus == SyncStatus.pendingDelete) {
          await userMemoriesRef.doc(item.id).delete();
          await db.permanentDeleteMemory(item.id);
        } else {
          await userMemoriesRef
              .doc(item.id)
              .set(item.toFirestoreMap(), SetOptions(merge: true));
          await db.markSynced(item.id);
        }
      }

      // 2. Pull latest remote records from Firestore
      final snapshot = await userMemoriesRef.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final remoteItem = MemoryItem.fromMap(data);
        await db.insertMemory(
          remoteItem.copyWith(syncStatus: SyncStatus.synced),
        );
      }

      _lastSyncedAt = DateTime.now();
      _setSyncState(CloudSyncState.synced);

      // Refresh memory list in UI
      final freshMemories = await db.getActiveMemories();
      onLocalDataChanged(freshMemories);
    } catch (e) {
      debugPrint("Error during Firebase cloud sync: $e");
      _setSyncState(CloudSyncState.error);
    }
  }

  void startRealtimeSync({
    required Function(List<MemoryItem>) onLocalDataChanged,
  }) async {
    if (!_isInitialized) return;
    final uid = await _getUserId();
    if (uid == null) return;

    _remoteSubscription?.cancel();
    _remoteSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('memories')
        .snapshots()
        .listen(
          (snapshot) async {
            final db = LocalDatabaseService.instance;
            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;

              if (change.type == DocumentChangeType.removed) {
                await db.permanentDeleteMemory(change.doc.id);
              } else {
                final memory = MemoryItem.fromMap(data);
                await db.insertMemory(
                  memory.copyWith(syncStatus: SyncStatus.synced),
                );
              }
            }
            final freshMemories = await db.getActiveMemories();
            onLocalDataChanged(freshMemories);
          },
          onError: (e) {
            debugPrint("Firestore realtime listener error: $e");
          },
        );
  }

  void dispose() {
    _remoteSubscription?.cancel();
    _syncStateController.close();
  }
}
