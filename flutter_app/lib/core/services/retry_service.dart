// T091: Retry mechanism for failed syncs when connection restored
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

/// Service for managing retry logic when connection is restored
class RetryService {
  final Ref _ref;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;

  RetryService(this._ref) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    final connectivityService = _ref.read(connectivityServiceProvider);
    
    _connectivitySubscription = connectivityService.connectivityStream.listen((isOnline) {
      if (_wasOffline && isOnline) {
        // Connection restored, trigger retry
        _handleConnectionRestored();
      }
      _wasOffline = !isOnline;
    });
  }

  void _handleConnectionRestored() {
    // Firestore automatically retries pending writes when connection is restored
    // We just need to ensure persistence is enabled (already done in T085)
    
    // T089: Last Write Wins strategy is Firestore's default behavior
    // No additional conflict resolution needed
    
    // Optional: Log reconnection event
    print('[RetryService] Connection restored - Firestore will automatically sync pending writes');
    
    // Optional: Trigger a manual retry for specific operations if needed
    _triggerManualRetry();
  }

  void _triggerManualRetry() {
    // This is a placeholder for any manual retry logic
    // Firestore handles most retries automatically
    
    // Example: You could re-query critical data here
    // final projectRepo = _ref.read(projectRepositoryProvider);
    // projectRepo.refreshProjects();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Provider for RetryService
final retryServiceProvider = Provider<RetryService>((ref) {
  final service = RetryService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Extension to enable the retry service
/// Call this in main() or app initialization
extension RetryServiceInitializer on WidgetRef {
  void initializeRetryService() {
    read(retryServiceProvider);
  }
}
