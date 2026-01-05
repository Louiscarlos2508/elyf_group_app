import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../sync_manager.dart';
import '../sync_status.dart';

/// Firebase Firestore implementation of [SyncOperationHandler].
///
/// Handles synchronization of local operations to Firebase Firestore.
///
/// Usage:
/// ```dart
/// final handler = FirebaseSyncHandler(
///   firestore: FirebaseFirestore.instance,
///   collectionPaths: {
///     'sales': (enterpriseId) => 'enterprises/$enterpriseId/sales',
///     'products': (enterpriseId) => 'enterprises/$enterpriseId/products',
///   },
/// );
///
/// final syncManager = SyncManager(
///   isarService: isarService,
///   connectivityService: connectivityService,
///   syncHandler: handler,
/// );
/// ```
class FirebaseSyncHandler implements SyncOperationHandler {
  FirebaseSyncHandler({
    required this.firestore,
    required this.collectionPaths,
    this.conflictResolver = const ConflictResolver(),
  });

  final FirebaseFirestore firestore;

  /// Maps collection names to Firestore path builders.
  /// The function receives enterpriseId and returns the full path.
  final Map<String, String Function(String? enterpriseId)> collectionPaths;

  final ConflictResolver conflictResolver;

  @override
  Future<void> processOperation(SyncOperation operation) async {
    final pathBuilder = collectionPaths[operation.collectionName];
    if (pathBuilder == null) {
      throw SyncException(
        'No path configured for collection: ${operation.collectionName}',
      );
    }

    final collectionPath = pathBuilder(operation.enterpriseId);
    final collection = firestore.collection(collectionPath);

    switch (operation.operationType) {
      case 'create':
        await _handleCreate(collection, operation);
        break;
      case 'update':
        await _handleUpdate(collection, operation);
        break;
      case 'delete':
        await _handleDelete(collection, operation);
        break;
      default:
        throw SyncException(
          'Unknown operation type: ${operation.operationType}',
        );
    }
  }

  Future<void> _handleCreate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final data = jsonDecode(operation.data) as Map<String, dynamic>;

    // Add metadata
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['localId'] = operation.localId;

    // Create document
    final docRef = await collection.add(data);

    developer.log(
      'Created document ${docRef.id} for ${operation.localId}',
      name: 'offline.firebase',
    );
  }

  Future<void> _handleUpdate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    if (operation.remoteId == null) {
      throw SyncException('Remote ID required for update operation');
    }

    final docRef = collection.doc(operation.remoteId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw SyncException(
        'Document ${operation.remoteId} not found for update',
      );
    }

    final localData = jsonDecode(operation.data) as Map<String, dynamic>;
    final serverData = docSnapshot.data() as Map<String, dynamic>?;

    // Resolve conflicts
    Map<String, dynamic> finalData;
    if (serverData != null) {
      finalData = conflictResolver.resolve(
        localData: localData,
        serverData: serverData,
      );
    } else {
      finalData = localData;
    }

    // Update metadata
    finalData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(finalData);

    developer.log(
      'Updated document ${operation.remoteId}',
      name: 'offline.firebase',
    );
  }

  Future<void> _handleDelete(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    if (operation.remoteId == null) {
      throw SyncException('Remote ID required for delete operation');
    }

    final docRef = collection.doc(operation.remoteId);

    // Check if document exists before deleting
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      developer.log(
        'Document ${operation.remoteId} already deleted',
        name: 'offline.firebase',
      );
      return;
    }

    await docRef.delete();

    developer.log(
      'Deleted document ${operation.remoteId}',
      name: 'offline.firebase',
    );
  }
}

/// Mock sync handler for testing.
class MockSyncHandler implements SyncOperationHandler {
  MockSyncHandler({
    this.shouldFail = false,
    this.failureRate = 0.0,
    this.delayMs = 100,
  });

  /// If true, all operations will fail.
  final bool shouldFail;

  /// Probability of failure (0.0 to 1.0).
  final double failureRate;

  /// Simulated network delay in milliseconds.
  final int delayMs;

  final List<SyncOperation> processedOperations = [];

  @override
  Future<void> processOperation(SyncOperation operation) async {
    // Simulate network delay
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    // Check for failure
    if (shouldFail) {
      throw SyncException('Mock sync failure');
    }

    if (failureRate > 0) {
      final random = DateTime.now().microsecond / 1000000;
      if (random < failureRate) {
        throw SyncException('Random mock failure');
      }
    }

    processedOperations.add(operation);

    developer.log(
      'Mock processed: ${operation.operationType} '
      '${operation.collectionName}/${operation.localId}',
      name: 'offline.mock',
    );
  }

  void reset() {
    processedOperations.clear();
  }
}
