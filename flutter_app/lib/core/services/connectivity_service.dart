// T086: Network connectivity monitoring service
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for monitoring network connectivity status
class ConnectivityService {
  final Connectivity _connectivity;
  StreamController<bool>? _connectivityController;

  ConnectivityService(this._connectivity);

  /// Stream of connectivity status (true = online, false = offline)
  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectivityController!.stream;
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _startListening() {
    // Check initial connectivity status
    _connectivity.checkConnectivity().then((results) {
      final isOnline = _isConnected(results);
      _connectivityController?.add(isOnline);
    });

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _isConnected(results);
      _connectivityController?.add(isOnline);
    });
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Check if device is connected to the internet
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Get current connectivity status
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
  }
}

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService(Connectivity());
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// Provider for checking if the device is currently online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityStatus = ref.watch(connectivityStatusProvider);
  return connectivityStatus.when(
    data: (isOnline) => isOnline,
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error
  );
});
