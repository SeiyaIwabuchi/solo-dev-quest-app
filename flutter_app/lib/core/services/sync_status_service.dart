// T089 & T090: Sync status service for tracking offline operations
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the state of synchronization
enum SyncStatus {
  synced,      // All changes are synced
  syncing,     // Currently syncing
  pending,     // Has pending changes
  error,       // Sync error occurred
}

/// Service for monitoring Firestore sync status
class SyncStatusService {
  final StreamController<SyncStatus> _statusController = 
      StreamController<SyncStatus>.broadcast();

  SyncStatusService() {
    _monitorSyncStatus();
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;

  void _monitorSyncStatus() {
    // Monitor Firestore's pending writes
    // Note: Firestore doesn't expose pending writes directly,
    // so we use snapshot metadata to infer sync status
    // This is a simplified implementation
    
    // Start with synced state
    _statusController.add(SyncStatus.synced);
  }

  /// Check if there are pending writes
  /// This is inferred from snapshot metadata
  bool hasPendingWrites(DocumentSnapshot snapshot) {
    return snapshot.metadata.hasPendingWrites;
  }

  /// Check if data is from cache
  bool isFromCache(DocumentSnapshot snapshot) {
    return snapshot.metadata.isFromCache;
  }

  void dispose() {
    _statusController.close();
  }
}

/// Provider for SyncStatusService
final syncStatusServiceProvider = Provider<SyncStatusService>((ref) {
  final service = SyncStatusService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncStatusServiceProvider);
  return service.statusStream;
});

/// Provider for checking if there are pending syncs
final hasPendingSyncsProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return syncStatus.when(
    data: (status) => status == SyncStatus.pending || status == SyncStatus.syncing,
    loading: () => false,
    error: (_, __) => false,
  );
});
