import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/point_of_sale.dart';
import '../../domain/repositories/point_of_sale_repository.dart';

/// Offline-first repository for PointOfSale entities (gaz module).
class PointOfSaleOfflineRepository extends OfflineRepository<PointOfSale>
    implements PointOfSaleRepository {
  PointOfSaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'points_of_sale';

  @override
  PointOfSale fromMap(Map<String, dynamic> map) {
    return PointOfSale(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      contact: map['contact'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      moduleId: map['moduleId'] as String? ?? 'gaz',
      isActive: map['isActive'] as bool? ?? true,
      cylinderIds: (map['cylinderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(PointOfSale entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'address': entity.address,
      'contact': entity.contact,
      'enterpriseId': entity.enterpriseId,
      'moduleId': entity.moduleId,
      'isActive': entity.isActive,
      'cylinderIds': entity.cylinderIds,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(PointOfSale entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PointOfSale entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(PointOfSale entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(PointOfSale entity) async {
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
  Future<void> deleteFromLocal(PointOfSale entity) async {
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
  Future<PointOfSale?> getByLocalId(String localId) async {
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
  Future<List<PointOfSale>> getAllForEnterprise(String enterpriseId) async {
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
              'Error parsing point of sale: $e',
              name: 'PointOfSaleOfflineRepository',
            );
            return null;
          }
        })
        .whereType<PointOfSale>()
        .toList();
  }

  // Implémentation de PointOfSaleRepository

  @override
  Future<List<PointOfSale>> getPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      var points = await getAllForEnterprise(enterpriseId);
      points = points.where((p) => p.moduleId == moduleId).toList();
      points.sort((a, b) => a.name.compareTo(b.name));
      return points;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching points of sale',
        name: 'PointOfSaleOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<PointOfSale?> getPointOfSaleById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting point of sale',
        name: 'PointOfSaleOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> addPointOfSale(PointOfSale pointOfSale) async {
    try {
      final posWithId = pointOfSale.id.isEmpty
          ? pointOfSale.copyWith(
              id: LocalIdGenerator.generate(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : pointOfSale;
      await save(posWithId);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding point of sale',
        name: 'PointOfSaleOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePointOfSale(PointOfSale pointOfSale) async {
    try {
      final updated = pointOfSale.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating point of sale',
        name: 'PointOfSaleOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deletePointOfSale(String id) async {
    try {
      final pos = await getPointOfSaleById(id);
      if (pos != null) {
        await delete(pos);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting point of sale',
        name: 'PointOfSaleOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }
}

