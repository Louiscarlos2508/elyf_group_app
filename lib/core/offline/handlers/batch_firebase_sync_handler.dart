import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../drift_service.dart';
import '../security/data_sanitizer.dart';
import '../sync_manager.dart';
import '../sync_status.dart';

/// Batch Firebase Firestore sync handler for processing multiple operations efficiently.
///
/// Uses Firestore batch writes (up to 500 operations per batch) to reduce
/// network requests and costs.
///
/// Benefits:
/// - ⚡ Performance: 1 network request instead of N
/// - 💰 Cost: Reduced Firestore read/write operations
/// - ⏱️ Speed: Faster sync for large batches
class BatchFirebaseSyncHandler {
  BatchFirebaseSyncHandler({
    required this.firestore,
    required this.collectionPaths,
    this.conflictResolver = const ConflictResolver(),
    DriftService? driftService,
  }) : _driftService = driftService;

  final FirebaseFirestore firestore;
  final Map<String, String Function(String? enterpriseId)> collectionPaths;
  final ConflictResolver conflictResolver;
  final DriftService? _driftService;

  /// Maximum operations per batch (Firestore limit: 500).
  static const int maxBatchSize = 500;

  /// Processes a batch of sync operations efficiently.
  ///
  /// Groups operations by collection and processes them in batches.
  /// Returns a map of operation IDs to results (success or error).
  Future<Map<int, BatchOperationResult>> processBatch(
    List<SyncOperation> operations,
  ) async {
    if (operations.isEmpty) {
      return {};
    }

    final results = <int, BatchOperationResult>{};
    
    // Group operations by collection and enterprise for efficient batching
    final grouped = _groupOperations(operations);
    
    for (final group in grouped.entries) {
      final collectionName = group.key;
      final collectionOps = group.value;
      
      // Process in batches of maxBatchSize
      for (int i = 0; i < collectionOps.length; i += maxBatchSize) {
        final batch = collectionOps.skip(i).take(maxBatchSize).toList();
        final batchResults = await _processBatchGroup(collectionName, batch);
        results.addAll(batchResults);
      }
    }
    
    return results;
  }

  /// Groups operations by collection name and enterprise ID.
  Map<String, List<SyncOperation>> _groupOperations(
    List<SyncOperation> operations,
  ) {
    final grouped = <String, List<SyncOperation>>{};
    
    for (final op in operations) {
      final key = '${op.collectionName}:${op.enterpriseId}';
      grouped.putIfAbsent(key, () => []).add(op);
    }
    
    return grouped;
  }

  /// Processes a batch of operations for the same collection.
  Future<Map<int, BatchOperationResult>> _processBatchGroup(
    String groupKey,
    List<SyncOperation> operations,
  ) async {
    final results = <int, BatchOperationResult>{};
    
    if (operations.isEmpty) return results;
    
    // Extract collection name and enterprise ID from group key
    final parts = groupKey.split(':');
    final collectionName = parts[0];
    final enterpriseId = parts.length > 1 ? parts[1] : '';
    
    final pathBuilder = collectionPaths[collectionName];
    if (pathBuilder == null) {
      // Mark all as failed
      for (final op in operations) {
        results[op.id] = BatchOperationResult.failed(
          'No path configured for collection: $collectionName',
        );
      }
      return results;
    }

    final collectionPath = pathBuilder(enterpriseId);
    final collection = firestore.collection(collectionPath);

    try {
      // Separate operations by type for batch processing
      final creates = <SyncOperation>[];
      final updates = <SyncOperation>[];
      final deletes = <SyncOperation>[];

      for (final op in operations) {
        switch (op.operationType) {
          case 'create':
            creates.add(op);
            break;
          case 'update':
            updates.add(op);
            break;
          case 'delete':
            deletes.add(op);
            break;
        }
      }

      // Process creates in batch
      if (creates.isNotEmpty) {
        final createResults = await _processBatchCreates(collection, creates);
        results.addAll(createResults);
      }

      // Process updates in batch (need to check conflicts first)
      if (updates.isNotEmpty) {
        final updateResults = await _processBatchUpdates(collection, updates);
        results.addAll(updateResults);
      }

      // Process deletes in batch
      if (deletes.isNotEmpty) {
        final deleteResults = await _processBatchDeletes(collection, deletes);
        results.addAll(deleteResults);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error processing batch for $collectionName: $e',
        name: 'offline.firebase.batch',
        error: e,
        stackTrace: stackTrace,
      );
      // Mark all as failed
      for (final op in operations) {
        if (!results.containsKey(op.id)) {
          results[op.id] = BatchOperationResult.failed(e.toString());
        }
      }
    }

    return results;
  }

  /// Processes batch creates using Firestore batch writes.
  Future<Map<int, BatchOperationResult>> _processBatchCreates(
    CollectionReference collection,
    List<SyncOperation> operations,
  ) async {
    final results = <int, BatchOperationResult>{};
    final batch = firestore.batch();
    final remoteIdUpdates = <String, String>{}; // localId -> remoteId

    for (final op in operations) {
      try {
        final rawData = op.payloadMap ?? {};
        final sanitizedData = DataSanitizer.sanitizeMap(rawData);
        
        // Validate size
        try {
          DataSanitizer.validateJsonSize(jsonEncode(sanitizedData));
        } on DataSizeException catch (e) {
          results[op.id] = BatchOperationResult.failed(
            'Données trop volumineuses: ${e.message}',
          );
          continue;
        }

        sanitizedData['createdAt'] = FieldValue.serverTimestamp();
        sanitizedData['updatedAt'] = FieldValue.serverTimestamp();
        sanitizedData['localId'] = op.documentId;

        // Add to batch (Firestore will generate ID)
        final docRef = collection.doc();
        batch.set(docRef, sanitizedData);
        remoteIdUpdates[op.documentId] = docRef.id;
      } catch (e) {
        results[op.id] = BatchOperationResult.failed(e.toString());
      }
    }

    // Commit batch
    try {
      await batch.commit();
      
      // Update remoteIds in local database
      final driftService = _driftService;
      if (driftService != null) {
        for (final entry in remoteIdUpdates.entries) {
          try {
            await driftService.records.updateRemoteId(
              collectionName: operations.first.collectionName,
              localId: entry.key,
              remoteId: entry.value,
              serverUpdatedAt: DateTime.now(),
            );
          } catch (e) {
            developer.log(
              'Error updating remoteId after batch create: $e',
              name: 'offline.firebase.batch',
            );
          }
        }
      }

      // Mark successful operations
      for (final op in operations) {
        if (!results.containsKey(op.id)) {
          results[op.id] = BatchOperationResult.success();
        }
      }

      developer.log(
        'Batch created ${remoteIdUpdates.length} documents',
        name: 'offline.firebase.batch',
      );
    } on FirebaseException catch (e) {
      // Batch failed - mark all as failed
      final errorMsg = _handleFirestoreError(e, operations.first);
      for (final op in operations) {
        if (!results.containsKey(op.id)) {
          results[op.id] = BatchOperationResult.failed(errorMsg);
        }
      }
    }

    return results;
  }

  /// Processes batch updates (with conflict checking).
  Future<Map<int, BatchOperationResult>> _processBatchUpdates(
    CollectionReference collection,
    List<SyncOperation> operations,
  ) async {
    final results = <int, BatchOperationResult>{};
    
    // For updates, we need to check conflicts first
    // Firestore batch doesn't support conditional updates easily,
    // so we process them individually but can optimize with parallel requests
    
    final futures = <Future<void>>[];
    
    for (final op in operations) {
      futures.add(
        _processSingleUpdate(collection, op).then((result) {
          results[op.id] = result;
        }).catchError((e) {
          results[op.id] = BatchOperationResult.failed(e.toString());
        }),
      );
    }
    
    await Future.wait(futures);
    return results;
  }

  /// Processes a single update operation (used by batch updates).
  Future<BatchOperationResult> _processSingleUpdate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final docRef = collection.doc(operation.documentId);
    
    try {
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        return BatchOperationResult.failed(
          'Document ${operation.documentId} not found for update',
        );
      }

      final rawLocalData = operation.payloadMap ?? {};
      final localData = DataSanitizer.sanitizeMap(rawLocalData);
      final serverData = docSnapshot.data() as Map<String, dynamic>?;

      if (serverData == null) {
        final finalData = Map<String, dynamic>.from(localData)
          ..['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(finalData);
        return BatchOperationResult.success();
      }

      // Check for conflicts
      final localUpdatedAtStr = localData['updatedAt'] as String?;
      final serverUpdatedAtStr = serverData['updatedAt'] as String?;

      final localUpdatedAt = localUpdatedAtStr != null
          ? DateTime.tryParse(localUpdatedAtStr)
          : null;
      final serverUpdatedAt = serverUpdatedAtStr != null
          ? DateTime.tryParse(serverUpdatedAtStr)
          : null;

      // If server is newer, update local instead
      if (serverUpdatedAt != null &&
          localUpdatedAt != null &&
          serverUpdatedAt.isAfter(localUpdatedAt)) {
        // Update local with server version
        final driftService = _driftService;
        if (driftService != null) {
          try {
            final serverDataJson = _convertToJsonCompatible(serverData);
            await driftService.records.upsert(
              collectionName: operation.collectionName,
              localId: operation.documentId,
              remoteId: operation.documentId,
              enterpriseId: operation.enterpriseId,
              moduleType: '', // Will be found by the sync handler
              dataJson: jsonEncode(serverDataJson),
              localUpdatedAt: DateTime.now(),
            );
          } catch (e) {
            developer.log(
              'Error updating local with server version: $e',
              name: 'offline.firebase.batch',
            );
          }
        }
        return BatchOperationResult.success(); // Considered success (local updated)
      }

      // Resolve conflict
      final finalData = conflictResolver.resolve(
        localData: localData,
        serverData: serverData,
      );

      if (finalData == serverData) {
        return BatchOperationResult.success(); // No update needed
      }

      final sanitizedFinalData = DataSanitizer.sanitizeMap(finalData);
      sanitizedFinalData['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.update(sanitizedFinalData);
      
      return BatchOperationResult.success();
    } on FirebaseException catch (e) {
      return BatchOperationResult.failed(_handleFirestoreError(e, operation));
    }
  }

  /// Processes batch deletes.
  Future<Map<int, BatchOperationResult>> _processBatchDeletes(
    CollectionReference collection,
    List<SyncOperation> operations,
  ) async {
    final results = <int, BatchOperationResult>{};
    final batch = firestore.batch();

    for (final op in operations) {
      final docRef = collection.doc(op.documentId);
      batch.delete(docRef);
    }

    try {
      await batch.commit();
      
      for (final op in operations) {
        results[op.id] = BatchOperationResult.success();
      }

      developer.log(
        'Batch deleted ${operations.length} documents',
        name: 'offline.firebase.batch',
      );
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e, operations.first);
      for (final op in operations) {
        results[op.id] = BatchOperationResult.failed(errorMsg);
      }
    }

    return results;
  }

  /// Converts Firestore data to JSON-compatible format.
  dynamic _convertToJsonCompatible(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key as String, _convertToJsonCompatible(val)),
      );
    } else if (value is List) {
      return value.map((item) => _convertToJsonCompatible(item)).toList();
    }
    return value;
  }

  /// Handles Firestore errors.
  String _handleFirestoreError(
    FirebaseException e,
    SyncOperation operation,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission refusée pour ${operation.collectionName}';
      case 'resource-exhausted':
        return 'Quota Firestore dépassé';
      case 'unauthenticated':
        return 'Non authentifié';
      default:
        return 'Erreur Firestore (${e.code}): ${e.message ?? "Erreur inconnue"}';
    }
  }
}

/// Result of a batch operation.
class BatchOperationResult {
  const BatchOperationResult({
    required this.success,
    this.error,
  });

  factory BatchOperationResult.success() {
    return const BatchOperationResult(success: true);
  }

  factory BatchOperationResult.failed(String error) {
    return BatchOperationResult(success: false, error: error);
  }

  final bool success;
  final String? error;
}
