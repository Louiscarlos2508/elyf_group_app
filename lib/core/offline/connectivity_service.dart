import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../errors/error_handler.dart';
import '../logging/app_logger.dart';

/// Service for monitoring network connectivity status.
///
/// Provides real-time updates on network availability and type.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  /// Current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus.isOnline;

  /// Initializes the connectivity service and starts listening.
  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);

      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateStatus,
        onError: (Object error, StackTrace? stackTrace) {
          final appException = ErrorHandler.instance.handleError(error, stackTrace ?? StackTrace.current);
          AppLogger.warning(
            'Connectivity monitoring error: ${appException.message}',
            name: 'offline.connectivity',
            error: error,
            stackTrace: stackTrace,
          );
          _currentStatus = ConnectivityStatus.unknown;
          _controller.add(_currentStatus);
        },
      );
    } catch (error) {
      AppLogger.error(
        'Failed to initialize connectivity service',
        name: 'offline.connectivity',
        error: error,
      );
      _currentStatus = ConnectivityStatus.unknown;
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus = _mapResultsToStatus(results);
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _controller.add(_currentStatus);
      AppLogger.debug(
        'Connectivity changed: $_currentStatus',
        name: 'offline.connectivity',
      );
    }
  }

  ConnectivityStatus _mapResultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.wifi;
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityStatus.mobile;
    }

    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.ethernet;
    }

    return ConnectivityStatus.other;
  }

  /// Checks current connectivity status.
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _currentStatus;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.warning(
        'Failed to check connectivity: ${appException.message}',
        name: 'offline.connectivity',
        error: error,
        stackTrace: stackTrace,
      );
      return ConnectivityStatus.unknown;
    }
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}

/// Represents the current connectivity status.
enum ConnectivityStatus {
  /// Connected via WiFi.
  wifi,

  /// Connected via mobile data.
  mobile,

  /// Connected via ethernet.
  ethernet,

  /// Connected via other means.
  other,

  /// Not connected to any network.
  offline,

  /// Connectivity status is unknown.
  unknown;

  /// Whether the device has network connectivity.
  bool get isOnline =>
      this == wifi || this == mobile || this == ethernet || this == other;

  /// Whether the connection is considered fast (WiFi or Ethernet).
  bool get isFastConnection => this == wifi || this == ethernet;

  /// Human-readable description.
  String get description {
    switch (this) {
      case wifi:
        return 'WiFi';
      case mobile:
        return 'Mobile Data';
      case ethernet:
        return 'Ethernet';
      case other:
        return 'Other Network';
      case offline:
        return 'Offline';
      case unknown:
        return 'Unknown';
    }
  }
}

/// Notifier for connectivity status changes.
///
/// Use this with `ValueListenableBuilder` for reactive UI updates.
class ConnectivityNotifier extends ValueNotifier<ConnectivityStatus> {
  ConnectivityNotifier(this._service) : super(ConnectivityStatus.unknown);

  final ConnectivityService _service;
  StreamSubscription<ConnectivityStatus>? _subscription;

  /// Starts listening to connectivity changes.
  void startListening() {
    value = _service.currentStatus;
    _subscription = _service.statusStream.listen((status) {
      value = status;
    });
  }

  /// Stops listening to connectivity changes.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
