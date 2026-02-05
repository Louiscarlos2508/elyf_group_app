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
  CylinderLeak fromMap(Map<String, dynamic> map) {
    return CylinderLeak(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      weight: (map['weight'] as num).toInt(),
      reportedDate: DateTime.parse(map['reportedDate'] as String),
      status: LeakStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LeakStatus.reported,
      ),
      tourId: map['tourId'] as String?,
      exchangeDate: map['exchangeDate'] != null
          ? DateTime.parse(map['exchangeDate'] as String)
          : null,
      notes: map['notes'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(CylinderLeak entity) {
    return {
      'id': entity.id,
      'cylinderId': entity.cylinderId,
      'weight': entity.weight,
      'reportedDate': entity.reportedDate.toIso8601String(),
      'status': entity.status.name,
      'tourId': entity.tourId,
      'exchangeDate': entity.exchangeDate?.toIso8601String(),
      'notes': entity.notes,
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

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
  Future<void> saveToLocal(CylinderLeak entity) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(CylinderLeak entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
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
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
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
                  return fromMap(map);
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
