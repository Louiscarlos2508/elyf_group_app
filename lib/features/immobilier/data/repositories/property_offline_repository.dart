import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';

/// Offline-first repository for Property entities (immobilier module).
class PropertyOfflineRepository extends OfflineRepository<Property>
    implements PropertyRepository {
  PropertyOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'properties';

  String get moduleType => 'immobilier';

  @override
  Property fromMap(Map<String, dynamic> map) => Property.fromMap(map);

  @override
  Map<String, dynamic> toMap(Property entity) => entity.toMap();

  @override
  String getLocalId(Property entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Property entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Property entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Property entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Property entity) async {
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
  Future<Property?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ) ?? await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
  }

  @override
  Future<List<Property>> getAllProperties() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Property>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final properties = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(properties);
  }

  // PropertyRepository interface implementation

  @override
  Stream<List<Property>> watchProperties() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => !e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Stream<List<Property>> watchDeletedProperties() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Future<Property?> getPropertyById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<Property>> getPropertiesByStatus(PropertyStatus status) async {
    final all = await getAllProperties();
    return all.where((p) => p.status == status).toList();
  }

  @override
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    final all = await getAllProperties();
    return all.where((p) => p.propertyType == type).toList();
  }

  @override
  Future<Property> createProperty(Property property) async {
    try {
      final localId = property.id.isEmpty ? LocalIdGenerator.generate() : property.id;
      final newProperty = property.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: property.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newProperty);
      return newProperty;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Property> updateProperty(Property property) async {
    try {
      final updatedProperty = property.copyWith(updatedAt: DateTime.now());
      await save(updatedProperty);
      return updatedProperty;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deleteProperty(String id) async {
    try {
      final property = await getPropertyById(id);
      if (property != null) {
        await save(property.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> restoreProperty(String id) async {
    try {
      final property = await getPropertyById(id);
      if (property != null) {
        await save(property.copyWith(
          deletedAt: null,
          deletedBy: null,
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
