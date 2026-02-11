import 'dart:async';

import '../logging/app_logger.dart';

/// Métriques de synchronisation pour monitoring et analytics.
///
/// Collecte des statistiques détaillées sur les opérations de synchronisation
/// pour permettre le monitoring de la santé du système et l'optimisation.
class SyncMetrics {
  SyncMetrics();

  /// Nombre total d'opérations traitées.
  int totalOperations = 0;

  /// Nombre d'opérations réussies.
  int successfulOperations = 0;

  /// Nombre d'opérations échouées.
  int failedOperations = 0;

  /// Temps total de synchronisation.
  Duration totalSyncTime = Duration.zero;

  /// Temps moyen de synchronisation par opération.
  Duration get averageSyncTime {
    if (totalOperations == 0) return Duration.zero;
    return Duration(
      microseconds: totalSyncTime.inMicroseconds ~/ totalOperations,
    );
  }

  /// Temps de la dernière synchronisation.
  DateTime? lastSyncTime;

  /// Durée de la dernière synchronisation.
  Duration? lastSyncDuration;

  /// Erreurs par type (code d'erreur -> nombre d'occurrences).
  final Map<String, int> errorsByType = {};

  /// Erreurs par collection (collectionName -> nombre d'erreurs).
  final Map<String, int> errorsByCollection = {};

  /// Opérations par priorité (priority -> nombre).
  final Map<String, int> operationsByPriority = {};

  /// Opérations par type (create/update/delete -> nombre).
  final Map<String, int> operationsByType = {};

  /// Taille totale des payloads synchronisés (en bytes).
  int totalPayloadSize = 0;

  /// Taille moyenne des payloads (en bytes).
  int get averagePayloadSize {
    if (totalOperations == 0) return 0;
    return totalPayloadSize ~/ totalOperations;
  }

  /// Nombre de retries effectués.
  int totalRetries = 0;

  /// Nombre de batch operations effectuées.
  int batchOperationsCount = 0;

  /// Nombre d'opérations traitées en batch.
  int batchOperationsSize = 0;

  /// Taux de succès (0.0 à 1.0).
  double get successRate {
    if (totalOperations == 0) return 0.0;
    return successfulOperations / totalOperations;
  }

  /// Taux d'échec (0.0 à 1.0).
  double get failureRate {
    if (totalOperations == 0) return 0.0;
    return failedOperations / totalOperations;
  }

  /// Enregistre une opération réussie.
  void recordSuccess({
    required String operationType,
    required String collectionName,
    required String priority,
    int? payloadSize,
    Duration? duration,
  }) {
    totalOperations++;
    successfulOperations++;

    operationsByType[operationType] = (operationsByType[operationType] ?? 0) + 1;
    operationsByPriority[priority] =
        (operationsByPriority[priority] ?? 0) + 1;

    if (payloadSize != null) {
      totalPayloadSize += payloadSize;
    }

    if (duration != null) {
      totalSyncTime += duration;
    }

    lastSyncTime = DateTime.now();
    if (duration != null) {
      lastSyncDuration = duration;
    }
  }

  /// Enregistre une opération échouée.
  void recordFailure({
    required String operationType,
    required String collectionName,
    required String priority,
    required String errorType,
    int? payloadSize,
    Duration? duration,
    int? retryCount,
  }) {
    totalOperations++;
    failedOperations++;

    operationsByType[operationType] = (operationsByType[operationType] ?? 0) + 1;
    operationsByPriority[priority] =
        (operationsByPriority[priority] ?? 0) + 1;

    errorsByType[errorType] = (errorsByType[errorType] ?? 0) + 1;
    errorsByCollection[collectionName] =
        (errorsByCollection[collectionName] ?? 0) + 1;

    if (payloadSize != null) {
      totalPayloadSize += payloadSize;
    }

    if (duration != null) {
      totalSyncTime += duration;
    }

    if (retryCount != null && retryCount > 0) {
      totalRetries += retryCount;
    }

    lastSyncTime = DateTime.now();
    if (duration != null) {
      lastSyncDuration = duration;
    }
  }

  /// Enregistre une opération batch.
  void recordBatch({
    required int operationsCount,
    required int successfulCount,
    required int failedCount,
    Duration? duration,
  }) {
    batchOperationsCount++;
    batchOperationsSize += operationsCount;

    totalOperations += operationsCount;
    successfulOperations += successfulCount;
    failedOperations += failedCount;

    if (duration != null) {
      totalSyncTime += duration;
    }

    lastSyncTime = DateTime.now();
    if (duration != null) {
      lastSyncDuration = duration;
    }
  }

  /// Réinitialise toutes les métriques.
  void reset() {
    totalOperations = 0;
    successfulOperations = 0;
    failedOperations = 0;
    totalSyncTime = Duration.zero;
    lastSyncTime = null;
    lastSyncDuration = null;
    errorsByType.clear();
    errorsByCollection.clear();
    operationsByPriority.clear();
    operationsByType.clear();
    totalPayloadSize = 0;
    totalRetries = 0;
    batchOperationsCount = 0;
    batchOperationsSize = 0;
  }

  /// Exporte les métriques vers un format JSON pour analytics.
  Map<String, dynamic> toJson() {
    return {
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'successRate': successRate,
      'failureRate': failureRate,
      'averageSyncTimeMs': averageSyncTime.inMilliseconds,
      'totalSyncTimeMs': totalSyncTime.inMilliseconds,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'lastSyncDurationMs': lastSyncDuration?.inMilliseconds,
      'errorsByType': errorsByType,
      'errorsByCollection': errorsByCollection,
      'operationsByPriority': operationsByPriority,
      'operationsByType': operationsByType,
      'averagePayloadSize': averagePayloadSize,
      'totalPayloadSize': totalPayloadSize,
      'totalRetries': totalRetries,
      'batchOperationsCount': batchOperationsCount,
      'batchOperationsSize': batchOperationsSize,
      'batchEfficiency': batchOperationsCount > 0
          ? batchOperationsSize / batchOperationsCount
          : 0.0,
    };
  }

  /// Affiche un résumé des métriques dans les logs.
  void logSummary() {
    AppLogger.info(
      '=== Sync Metrics Summary ===\n'
      'Total Operations: $totalOperations\n'
      'Successful: $successfulOperations (${(successRate * 100).toStringAsFixed(1)}%)\n'
      'Failed: $failedOperations (${(failureRate * 100).toStringAsFixed(1)}%)\n'
      'Average Sync Time: ${averageSyncTime.inMilliseconds}ms\n'
      'Total Retries: $totalRetries\n'
      'Batch Operations: $batchOperationsCount ($batchOperationsSize ops)\n'
      'Average Payload Size: $averagePayloadSize bytes\n'
      'Top Errors: ${_getTopErrors(3)}\n'
      'Top Error Collections: ${_getTopErrorCollections(3)}',
      name: 'sync.metrics',
    );
  }

  String _getTopErrors(int count) {
    final sorted = errorsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => '${e.key}:${e.value}').join(', ');
  }

  String _getTopErrorCollections(int count) {
    final sorted = errorsByCollection.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => '${e.key}:${e.value}').join(', ');
  }
}

/// Service pour exporter les métriques vers Firebase Analytics ou autres services.
class SyncMetricsExporter {
  /// Exporte les métriques vers Firebase Analytics (si disponible).
  ///
  /// Nécessite le package firebase_analytics.
  static Future<void> exportToFirebaseAnalytics(SyncMetrics metrics) async {
    try {
      // Import conditionnel pour éviter la dépendance si non utilisée
      // final analytics = FirebaseAnalytics.instance;
      // await analytics.logEvent(
      //   name: 'sync_metrics',
      //   parameters: metrics.toJson(),
      // );

      AppLogger.info(
        'Metrics export to Firebase Analytics (not implemented - requires firebase_analytics package)',
        name: 'sync.metrics.export',
      );
    } catch (e) {
      AppLogger.error(
        'Error exporting metrics to Firebase Analytics: $e',
        name: 'sync.metrics.export',
        error: e,
      );
    }
  }

  /// Exporte les métriques vers un endpoint HTTP personnalisé.
  static Future<void> exportToHttpEndpoint(
    SyncMetrics metrics,
    String endpointUrl, {
    Map<String, String>? headers,
  }) async {
    try {
      // Import conditionnel pour éviter la dépendance si non utilisée
      // final response = await http.post(
      //   Uri.parse(endpointUrl),
      //   headers: headers ?? {'Content-Type': 'application/json'},
      //   body: jsonEncode(metrics.toJson()),
      // );
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to export metrics: ${response.statusCode}');
      // }

      AppLogger.info(
        'Metrics export to HTTP endpoint (not implemented - requires http package)',
        name: 'sync.metrics.export',
      );
    } catch (e) {
      AppLogger.error(
        'Error exporting metrics to HTTP endpoint: $e',
        name: 'sync.metrics.export',
        error: e,
      );
    }
  }
}
