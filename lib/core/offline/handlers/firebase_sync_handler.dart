import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../sync_manager.dart';
import '../sync_status.dart';

/// Firebase Firestore implementation of [SyncOperationHandler].
///
/// Handles synchronization of local operations to Firebase Firestore.
class FirebaseSyncHandler implements SyncOperationHandler {
  FirebaseSyncHandler({
    required this.firestore,
    required this.collectionPaths,
    this.conflictResolver = const ConflictResolver(),
  });

  final FirebaseFirestore firestore;
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
      case 'update':
        await _handleUpdate(collection, operation);
      case 'delete':
        await _handleDelete(collection, operation);
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
    final data = operation.payloadMap ?? {};
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['localId'] = operation.documentId;

    final docRef = await collection.add(data);
    developer.log(
      'Created document ${docRef.id} for ${operation.documentId}',
      name: 'offline.firebase',
    );
  }

  Future<void> _handleUpdate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final docRef = collection.doc(operation.documentId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw SyncException(
        'Document ${operation.documentId} not found for update',
      );
    }

    final localData = operation.payloadMap ?? {};
    final serverData = docSnapshot.data() as Map<String, dynamic>?;

    Map<String, dynamic> finalData;
    if (serverData != null) {
      finalData = conflictResolver.resolve(
        localData: localData,
        serverData: serverData,
      );
    } else {
      finalData = localData;
    }

    finalData['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.update(finalData);

    developer.log(
      'Updated document ${operation.documentId}',
      name: 'offline.firebase',
    );
  }

  Future<void> _handleDelete(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final docRef = collection.doc(operation.documentId);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      developer.log(
        'Document ${operation.documentId} already deleted',
        name: 'offline.firebase',
      );
      return;
    }

    await docRef.delete();
    developer.log(
      'Deleted document ${operation.documentId}',
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

  final bool shouldFail;
  final double failureRate;
  final int delayMs;
  final List<SyncOperation> processedOperations = [];

  @override
  Future<void> processOperation(SyncOperation operation) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));

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
      '${operation.collectionName}/${operation.documentId}',
      name: 'offline.mock',
    );
  }

  void reset() {
    processedOperations.clear();
  }
}
