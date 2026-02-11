import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/repositories/daily_worker_repository.dart';

/// Offline-first repository for DailyWorker entities.
class DailyWorkerOfflineRepository extends OfflineRepository<DailyWorker>
    implements DailyWorkerRepository {
  DailyWorkerOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'daily_workers';

  @override
  DailyWorker fromMap(Map<String, dynamic> map) {
    final workDaysRaw = map['joursTravailles'] as List<dynamic>? ?? [];
    final workDays = workDaysRaw.map((w) {
      final wm = w as Map<String, dynamic>;
      return WorkDay(
        date: DateTime.parse(wm['date'] as String),
        productionId: wm['productionId'] as String,
        salaireJournalier: (wm['salaireJournalier'] as num).toInt(),
      );
    }).toList();

    return DailyWorker(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      salaireJournalier: (map['salaireJournalier'] as num).toInt(),
      joursTravailles: workDays,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(DailyWorker entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'phone': entity.phone,
      'salaireJournalier': entity.salaireJournalier,
      'joursTravailles': entity.joursTravailles
          .map(
            (w) => {
              'date': w.date.toIso8601String(),
              'productionId': w.productionId,
              'salaireJournalier': w.salaireJournalier,
            },
          )
          .toList(),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(DailyWorker entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(DailyWorker entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(DailyWorker entity) => enterpriseId;

  @override
  Future<void> saveToLocal(DailyWorker entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
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
  Future<void> deleteFromLocal(DailyWorker entity) async {
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
  Future<DailyWorker?> getByLocalId(String localId) async {
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
  Future<List<DailyWorker>> getAllForEnterprise(String enterpriseId) async {
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

  // DailyWorkerRepository implementation

  @override
  Future<List<DailyWorker>> fetchAllWorkers() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching all workers: ${appException.message}',
        name: 'DailyWorkerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<DailyWorker?> fetchWorkerById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching worker: $id',
        name: 'DailyWorkerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<DailyWorker> createWorker(DailyWorker worker) async {
    try {
      final localId = getLocalId(worker);
      final workerWithLocalId = worker.copyWith(
        id: localId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(workerWithLocalId);
      return workerWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating worker: ${appException.message}',
        name: 'DailyWorkerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<DailyWorker> updateWorker(DailyWorker worker) async {
    try {
      final updated = worker.copyWith(updatedAt: DateTime.now());
      await save(updated);
      return updated;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating worker: ${worker.id}',
        name: 'DailyWorkerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteWorker(String id) async {
    try {
      final worker = await fetchWorkerById(id);
      if (worker != null) {
        await delete(worker);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting worker: $id - ${appException.message}',
        name: 'DailyWorkerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
