import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
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
  String get collectionName => CollectionNames.properties;

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
  Future<void> saveToLocal(Property entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity);
    map['localId'] = localId;

    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
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
  Future<void> deleteFromLocal(Property entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedProperty = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedProperty, userId: userId);
  }

  @override
  Future<Property?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final property = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return property.isDeleted ? null : property;
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
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((p) => !p.isDeleted)
        .toList();
  }

  // PropertyRepository interface implementation

  @override
  Stream<List<Property>> watchProperties({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((p) {
        if (isDeleted == null) return true;
        return p.isDeleted == isDeleted;
      }).toList();
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
        await delete(property);
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
