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
  DailyWorker fromMap(Map<String, dynamic> map) =>
      DailyWorker.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(DailyWorker entity) => entity.toMap();

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
    // Soft-delete
    final deletedWorker = entity.copyWith(
      deletedAt: DateTime.now(),
    );
    await saveToLocal(deletedWorker);
    
    AppLogger.info(
      'Soft-deleted worker: ${entity.id}',
      name: 'DailyWorkerOfflineRepository',
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
      final worker = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return worker.isDeleted ? null : worker;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final worker = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return worker.isDeleted ? null : worker;
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
        .where((worker) => !worker.isDeleted)
        .toList();

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
