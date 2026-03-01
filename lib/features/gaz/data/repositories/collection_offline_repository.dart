import 'dart:convert';
import 'package:elyf_groupe_app/core/errors/error_handler.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/drift/app_database.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/collection.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/collection_repository.dart';

/// Implémentation offline du repository des collectes.
class CollectionOfflineRepository implements CollectionRepository {
  CollectionOfflineRepository({
    required this.driftService,
    required this.syncManager,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  static const String _collectionName = 'gas_collections';

  @override
  Future<void> saveCollection(Collection collection, String enterpriseId) async {
    try {
      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
        collectionName: _collectionName,
        localId: collection.id,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(collection.toMap()),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving collection: ${appException.message}',
        name: 'CollectionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Collection>> getCollections(
    String enterpriseId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? enterpriseIds,
  }) async {
    try {
      final List<OfflineRecord> rows;
      if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
        rows = await driftService.records.listForEnterprises(
          collectionName: _collectionName,
          enterpriseIds: enterpriseIds,
          moduleType: 'gaz',
        );
      } else {
        rows = await driftService.records.listForEnterprise(
          collectionName: _collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      }

      final collections = rows.map((OfflineRecord row) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          return Collection.fromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<Collection>().toList();

      // Filtrage par date
      var filtered = collections;
      if (startDate != null) {
        filtered = filtered.where((c) => c.paymentDate != null && c.paymentDate!.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((c) => c.paymentDate != null && c.paymentDate!.isBefore(endDate)).toList();
      }

      return filtered..sort((a, b) => (b.paymentDate ?? DateTime(0)).compareTo(a.paymentDate ?? DateTime(0)));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting collections: ${appException.message}',
        name: 'CollectionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<Collection>> watchCollections(
    String enterpriseId, {
    List<String>? enterpriseIds,
  }) {
    final Stream<List<OfflineRecord>> stream;
    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      stream = driftService.records.watchForEnterprises(
        collectionName: _collectionName,
        enterpriseIds: enterpriseIds,
        moduleType: 'gaz',
      );
    } else {
      stream = driftService.records.watchForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );
    }

    return stream.map((rows) {
      return rows.map((OfflineRecord row) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          return Collection.fromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<Collection>().toList()
        ..sort((a, b) => (b.paymentDate ?? DateTime(0)).compareTo(a.paymentDate ?? DateTime(0)));
    });
  }

  @override
  Future<Collection?> getCollectionById(String id) async {
    try {
      // Find the enterpriseId for this collection - offline records need all filters
      final enterpriseId = id.split('_').first; // Assuming ID pattern or we need to find it differently
      
      final row = await driftService.records.findByLocalId(
        collectionName: _collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );
      if (row == null) return null;
      final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
      return Collection.fromMap(map);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting collection by id: ${appException.message}',
        name: 'CollectionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
