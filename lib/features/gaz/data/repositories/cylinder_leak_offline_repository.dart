import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/repositories/cylinder_leak_repository.dart';

/// Offline-first repository for CylinderLeak entities (gaz module).
class CylinderLeakOfflineRepository extends OfflineRepository<CylinderLeak>
    implements CylinderLeakRepository {
  CylinderLeakOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'cylinder_leaks';

  @override
  CylinderLeak fromMap(Map<String, dynamic> map) {
    return CylinderLeak(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      reportedDate: DateTime.parse(map['reportedDate'] as String),
      status: _parseStatus(map['status'] as String? ?? 'reported'),
      tourId: map['tourId'] as String?,
      exchangeDate: map['exchangeDate'] != null
          ? DateTime.parse(map['exchangeDate'] as String)
          : null,
      notes: map['notes'] as String?,
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
    };
  }

  @override
  String getLocalId(CylinderLeak entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(CylinderLeak entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(CylinderLeak entity) => enterpriseId;

  @override
  Future<void> saveToLocal(CylinderLeak entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
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
        moduleType: 'gaz',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
  }

  @override
  Future<CylinderLeak?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<CylinderLeak>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing cylinder leak: $e',
              name: 'CylinderLeakOfflineRepository',
            );
            return null;
          }
        })
        .whereType<CylinderLeak>()
        .toList();
  }

  // Implémentation de CylinderLeakRepository

  @override
  Future<List<CylinderLeak>> getLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) async {
    try {
      var leaks = await getAllForEnterprise(enterpriseId);
      if (status != null) {
        leaks = leaks.where((l) => l.status == status).toList();
      }
      leaks.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
      return leaks;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching leaks',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<CylinderLeak?> getLeakById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting leak',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<String> reportLeak(CylinderLeak leak) async {
    try {
      final leakWithId = leak.id.isEmpty
          ? leak.copyWith(id: LocalIdGenerator.generate())
          : leak;
      await save(leakWithId);
      return leakWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error reporting leak',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateLeak(CylinderLeak leak) async {
    try {
      await save(leak);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating leak',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> markAsSentForExchange(String leakId) async {
    try {
      final leak = await getLeakById(leakId);
      if (leak != null) {
        final updated = leak.copyWith(status: LeakStatus.sentForExchange);
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error marking leak as sent for exchange',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      rethrow;
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
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error marking leak as exchanged',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      rethrow;
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting leak',
        name: 'CylinderLeakOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  LeakStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
      case 'signalée':
        return LeakStatus.reported;
      case 'sentforexchange':
      case 'sent_for_exchange':
      case 'envoyée pour échange':
        return LeakStatus.sentForExchange;
      case 'exchanged':
      case 'échangée':
        return LeakStatus.exchanged;
      default:
        return LeakStatus.reported;
    }
  }
}

