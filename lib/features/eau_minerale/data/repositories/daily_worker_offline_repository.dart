import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/repositories/daily_worker_repository.dart';

/// Offline-first repository for DailyWorker entities (eau_minerale module).
///
/// Gère les ouvriers journaliers.
class DailyWorkerOfflineRepository extends OfflineRepository<DailyWorker>
    implements DailyWorkerRepository {
  DailyWorkerOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'daily_workers';

  @override
  DailyWorker fromMap(Map<String, dynamic> map) {
    final workDaysList = map['joursTravailles'] as List<dynamic>?;
    final workDays = workDaysList?.map((day) {
      return WorkDay(
        date: DateTime.parse(day['date'] as String),
        productionId: day['productionId'] as String,
        salaireJournalier: (day['salaireJournalier'] as num).toInt(),
      );
    }).toList() ?? <WorkDay>[];

    return DailyWorker(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
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
      'joursTravailles': entity.joursTravailles.map((day) {
        return {
          'date': day.date.toIso8601String(),
          'productionId': day.productionId,
          'salaireJournalier': day.salaireJournalier,
        };
      }).toList(),
      if (entity.createdAt != null)
        'createdAt': entity.createdAt!.toIso8601String(),
      if (entity.updatedAt != null)
        'updatedAt': entity.updatedAt!.toIso8601String(),
    };
  }

  @override
  String getLocalId(DailyWorker entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(DailyWorker entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(DailyWorker entity) => enterpriseId;

  @override
  Future<void> saveToLocal(DailyWorker entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    final now = DateTime.now();
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      updatedAt: entity.updatedAt ?? now,
    );
  }

  @override
  Future<void> deleteFromLocal(String localId) async {
    await driftService.records.delete(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<List<DailyWorker>> fetchFromLocal() async {
    try {
      final records = await driftService.records.query(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        map['localId'] = record.localId;
        if (record.remoteId != null) {
          map['id'] = record.remoteId;
        }
        return fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching daily workers from local',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<DailyWorker?> getFromLocal(String localId) async {
    try {
      final record = await driftService.records.get(
        collectionName: collectionName,
        localId: localId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      if (record == null) return null;

      final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
      map['localId'] = record.localId;
      if (record.remoteId != null) {
        map['id'] = record.remoteId;
      }
      return fromMap(map);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting daily worker from local',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  // Implementation of DailyWorkerRepository interface

  @override
  Future<List<DailyWorker>> fetchAllWorkers() async {
    try {
      return await fetchFromLocal();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching all daily workers',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<DailyWorker?> fetchWorkerById(String id) async {
    try {
      final allWorkers = await fetchFromLocal();
      try {
        return allWorkers.firstWhere((worker) => worker.id == id);
      } catch (_) {
        return await getFromLocal(id);
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DailyWorker> createWorker(DailyWorker worker) async {
    try {
      final now = DateTime.now();
      final workerId = worker.id.isEmpty
          ? 'worker-${DateTime.now().millisecondsSinceEpoch}'
          : worker.id;
      final newWorker = worker.copyWith(
        id: workerId,
        createdAt: now,
        updatedAt: now,
      );
      await saveToLocal(newWorker);
      
      // Queue sync operation
      final localId = getLocalId(newWorker);
      final remoteId = getRemoteId(newWorker);
      final map = toMap(newWorker);
      if (remoteId == null) {
        await syncManager.queueCreate(
          collectionName: collectionName,
          localId: localId,
          data: map,
          enterpriseId: enterpriseId,
        );
      } else {
        await syncManager.queueUpdate(
          collectionName: collectionName,
          localId: localId,
          remoteId: remoteId,
          data: map,
          enterpriseId: enterpriseId,
        );
      }
      
      return newWorker;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating daily worker',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<DailyWorker> updateWorker(DailyWorker worker) async {
    try {
      final now = DateTime.now();
      final updatedWorker = worker.copyWith(updatedAt: now);
      await saveToLocal(updatedWorker);
      
      // Queue sync operation
      final localId = getLocalId(updatedWorker);
      final remoteId = getRemoteId(updatedWorker);
      final map = toMap(updatedWorker);
      if (remoteId == null) {
        await syncManager.queueCreate(
          collectionName: collectionName,
          localId: localId,
          data: map,
          enterpriseId: enterpriseId,
        );
      } else {
        await syncManager.queueUpdate(
          collectionName: collectionName,
          localId: localId,
          remoteId: remoteId,
          data: map,
          enterpriseId: enterpriseId,
        );
      }
      
      return updatedWorker;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating daily worker',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteWorker(String id) async {
    try {
      final worker = await fetchWorkerById(id);
      if (worker == null) {
        throw Exception('DailyWorker not found: $id');
      }

      final localId = getLocalId(worker);
      final remoteId = getRemoteId(worker);
      
      await deleteFromLocal(localId);
      
      // Queue sync operation
      if (remoteId != null) {
        await syncManager.queueDelete(
          collectionName: collectionName,
          localId: localId,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting daily worker',
        name: 'DailyWorkerOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }
}

