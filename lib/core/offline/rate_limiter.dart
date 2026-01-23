import 'dart:async';
import 'dart:developer' as developer;

/// Rate limiter pour éviter trop de requêtes simultanées.
///
/// Limite le nombre d'opérations par seconde pour éviter de surcharger
/// Firestore ou le réseau.
class RateLimiter {
  RateLimiter({
    this.maxOperationsPerSecond = 10,
    this.maxConcurrentOperations = 5,
  });

  /// Nombre maximum d'opérations par seconde.
  final int maxOperationsPerSecond;

  /// Nombre maximum d'opérations simultanées.
  final int maxConcurrentOperations;

  final List<DateTime> _operationTimestamps = [];
  int _concurrentOperations = 0;
  final _operationQueue = <Completer<void>>[];
  Timer? _cleanupTimer;

  /// Exécute une opération avec rate limiting.
  ///
  /// Attend si nécessaire pour respecter les limites.
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Vérifier le nombre d'opérations simultanées
    while (_concurrentOperations >= maxConcurrentOperations) {
      final completer = Completer<void>();
      _operationQueue.add(completer);
      await completer.future;
    }

    // Vérifier le rate limit par seconde
    _cleanupOldTimestamps();
    while (_operationTimestamps.length >= maxOperationsPerSecond) {
      final oldestTimestamp = _operationTimestamps.first;
      final waitTime = DateTime.now().difference(oldestTimestamp);
      if (waitTime.inMilliseconds < 1000) {
        final waitMs = 1000 - waitTime.inMilliseconds;
        developer.log(
          'Rate limit reached, waiting ${waitMs}ms',
          name: 'rate.limiter',
        );
        await Future<void>.delayed(Duration(milliseconds: waitMs));
        _cleanupOldTimestamps();
      }
    }

    _concurrentOperations++;
    _operationTimestamps.add(DateTime.now());

    try {
      return await operation();
    } finally {
      _concurrentOperations--;
      _operationTimestamps.removeWhere(
        (timestamp) => DateTime.now().difference(timestamp).inSeconds > 1,
      );

      // Débloquer la prochaine opération en attente
      if (_operationQueue.isNotEmpty) {
        final nextCompleter = _operationQueue.removeAt(0);
        nextCompleter.complete();
      }
    }
  }

  void _cleanupOldTimestamps() {
    _operationTimestamps.removeWhere(
      (timestamp) => DateTime.now().difference(timestamp).inSeconds > 1,
    );
  }

  /// Initialise le cleanup timer.
  void initialize() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _cleanupOldTimestamps(),
    );
  }

  /// Arrête le rate limiter.
  void dispose() {
    _cleanupTimer?.cancel();
    _operationTimestamps.clear();
    _operationQueue.clear();
    _concurrentOperations = 0;
  }
}
