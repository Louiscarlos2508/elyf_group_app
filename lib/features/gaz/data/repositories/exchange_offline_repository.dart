import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart' show LocalIdGenerator;
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/exchange_record.dart';
import '../../domain/repositories/exchange_repository.dart';

/// Implémentation offline-first du dépôt des échanges.
class ExchangeOfflineRepository implements ExchangeRepository {
  ExchangeOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  static const String _collectionName = 'exchange_records';

  ExchangeRecord _fromMap(Map<String, dynamic> map) => ExchangeRecord.fromMap(map);
  Map<String, dynamic> _toMap(ExchangeRecord entity) => entity.toMap();

  @override
  Future<List<ExchangeRecord>> getExchanges(String enterpriseId) async {
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
          .whereType<ExchangeRecord>()
          .toList()
        ..sort((a, b) => b.exchangedAt.compareTo(a.exchangedAt));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting exchanges: ${appException.message}',
        name: 'ExchangeOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<ExchangeRecord>> watchExchanges(String enterpriseId) {
    return driftService.records
        .watchForEnterprise(
          collectionName: _collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        )
        .map((rows) {
          return rows
              .map((row) {
                try {
                  final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
                  return _fromMap(map).copyWith(id: row.localId);
                } catch (e) {
                  return null;
                }
              })
              .whereType<ExchangeRecord>()
              .toList()
            ..sort((a, b) => b.exchangedAt.compareTo(a.exchangedAt));
        });
  }

  @override
  Future<ExchangeRecord?> getExchangeById(String id) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      for (final row in rows) {
        if (row.localId == id || row.remoteId == id) {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          return _fromMap(map).copyWith(id: row.localId);
        }
      }
      return null;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting exchange by id: ${appException.message}',
        name: 'ExchangeOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> addExchange(ExchangeRecord exchange) async {
    try {
      final localId = exchange.id.startsWith('local_') ? exchange.id : LocalIdGenerator.generate();
      final remoteId = exchange.id.startsWith('local_') ? null : exchange.id;

      final map = _toMap(exchange)..['localId'] = localId;

      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
        collectionName: _collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueCreate(
        collectionName: _collectionName,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding exchange: ${appException.message}',
        name: 'ExchangeOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteExchange(String id) async {
    try {
      await driftService.records.deleteByLocalId(
        collectionName: _collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      await syncManager.queueDelete(
        collectionName: _collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        remoteId: '', // Should ideally fetch remoteId if exists
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting exchange: ${appException.message}',
        name: 'ExchangeOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
