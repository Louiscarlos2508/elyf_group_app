
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/wholesaler.dart';
import '../../domain/repositories/wholesaler_repository.dart';

/// Implémentation offline-first de WholesalerRepository.
class WholesalerOfflineRepository implements WholesalerRepository {
  WholesalerOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  static const String _collectionName = 'wholesalers';

  Wholesaler _fromMap(Map<String, dynamic> map) => Wholesaler.fromMap(map);
  Map<String, dynamic> _toMap(Wholesaler entity) => entity.toMap();

  @override
  Future<List<Wholesaler>> getWholesalers(String enterpriseId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      return rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _fromMap(map).copyWith(id: row.localId);
            } catch (e) {
              return null;
            }
          })
          .whereType<Wholesaler>()
          .where((w) => w.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting wholesalers: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<Wholesaler?> getWholesalerById(String id) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      for (final row in rows) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final wholesaler = _fromMap(map);
          if (wholesaler.id == id && wholesaler.isActive) {
            return wholesaler;
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting wholesaler: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> createWholesaler(Wholesaler wholesaler) async {
    try {
      final localId = wholesaler.id.startsWith('local_')
          ? wholesaler.id
          : LocalIdGenerator.generate();
      
      final remoteId = wholesaler.id.startsWith('local_') ? null : wholesaler.id;

      final map = _toMap(wholesaler)..['localId'] = localId..['id'] = localId;

      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueCreate(
        collectionName: _collectionName,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating wholesaler: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateWholesaler(Wholesaler wholesaler) async {
    try {
      final localId = wholesaler.id;
      final remoteId = wholesaler.id.startsWith('local_') ? null : wholesaler.id;

      final map = _toMap(wholesaler);

      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueUpdate(
        collectionName: _collectionName,
        localId: localId,
        remoteId: remoteId ?? localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating wholesaler: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteWholesaler(String id) async {
    try {
      final wholesaler = await getWholesalerById(id);
      if (wholesaler == null) return;

      final deletedWholesaler = wholesaler.copyWith(isActive: false);
      await updateWholesaler(deletedWholesaler);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting wholesaler: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Wholesaler>> searchWholesalers(String enterpriseId, String query) async {
    try {
      final all = await getWholesalers(enterpriseId);
      final normalizedQuery = query.toLowerCase();
      
      return all.where((w) {
        return w.name.toLowerCase().contains(normalizedQuery) ||
               (w.phone != null && w.phone!.contains(normalizedQuery));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error searching wholesalers: ${appException.message}',
        name: 'WholesalerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
