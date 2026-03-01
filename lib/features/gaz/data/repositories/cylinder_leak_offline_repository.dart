import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/repositories/cylinder_leak_repository.dart';

/// Offline-first repository for CylinderLeak entities.
class CylinderLeakOfflineRepository extends OfflineRepository<CylinderLeak>
    implements CylinderLeakRepository {
  CylinderLeakOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'cylinder_leaks';

  @override
  CylinderLeak fromMap(Map<String, dynamic> map) =>
      CylinderLeak.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(CylinderLeak entity) => entity.toMap();

  @override
  String getLocalId(CylinderLeak entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(CylinderLeak entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(CylinderLeak entity) => enterpriseId;

  @override
  Future<void> saveToLocal(CylinderLeak entity, {String? userId}) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(CylinderLeak entity, {String? userId}) async {
    // Soft-delete
    final deletedLeak = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedLeak, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted cylinder leak: ${entity.id}',
      name: 'CylinderLeakOfflineRepository',
    );
  }

  @override
  Future<CylinderLeak?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final leak = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return leak.isDeleted ? null : leak;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final leak = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return leak.isDeleted ? null : leak;
  }

  @override
  Future<List<CylinderLeak>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows

      .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
      .where((l) => !l.isDeleted)
      .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  @override
  Future<List<CylinderLeak>> getLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      if (status == null) return all;
      return all.where((leak) => leak.status == status).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting leaks: ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // CylinderLeakRepository implementation

  @override
  Stream<List<CylinderLeak>> watchLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  final leak = fromMap(map);
                  return leak.isDeleted ? null : leak;
                } catch (e) {
                  return null;
                }
              })
              .whereType<CylinderLeak>()
              .toList();

          final deduplicated = deduplicateByRemoteId(entities);
          if (status == null) return deduplicated;
          return deduplicated.where((leak) => leak.status == status).toList();
        });
  }

  @override
  Future<CylinderLeak?> getLeakById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting leak: $id - ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> reportLeak(CylinderLeak leak) async {
    try {
      final localId = getLocalId(leak);
      final leakWithLocalId = leak.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
      );
      await save(leakWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error reporting leak: ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateLeak(CylinderLeak leak) async {
    try {
      final updatedLeak = leak.copyWith(updatedAt: DateTime.now());
      await save(updatedLeak);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating leak: ${leak.id} - ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> markAsSentForExchange(String leakId) async {
    try {
      final leak = await getLeakById(leakId);
      if (leak != null) {
        final updated = leak.copyWith(
          status: LeakStatus.sentForExchange,
          updatedAt: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error marking leak as sent for exchange: $leakId - ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> markAsExchanged(String leakId, DateTime exchangeDate) async {
    try {
      final leak = await getLeakById(leakId);
      if (leak != null) {
        final updated = leak.copyWith(
          status: LeakStatus.exchanged,
          exchangeDate: exchangeDate,
          updatedAt: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error marking leak as exchanged: $leakId - ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteLeak(String id) async {
    try {
      final leak = await getLeakById(id);
      if (leak != null) {
        await delete(leak);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting leak: $id - ${appException.message}',
        name: 'CylinderLeakOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
