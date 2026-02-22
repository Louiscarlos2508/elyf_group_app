import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
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
    final companion = PropertiesTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      address: Value(entity.address),
      city: Value(entity.city),
      propertyType: Value(entity.propertyType.name),
      rooms: Value(entity.rooms),
      area: Value(entity.area),
      price: Value(entity.price),
      status: Value(entity.status.name),
      description: Value(entity.description),
      images: Value(entity.images != null ? jsonEncode(entity.images) : null),
      amenities: Value(entity.amenities != null ? jsonEncode(entity.amenities) : null),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.propertiesTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(Property entity) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.propertiesTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<Property?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.propertiesTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  Property _fromEntity(PropertyEntity entity) {
    return Property(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      address: entity.address,
      city: entity.city,
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == entity.propertyType,
        orElse: () => PropertyType.house,
      ),
      rooms: entity.rooms,
      area: entity.area,
      price: entity.price,
      status: PropertyStatus.values.firstWhere(
        (e) => e.name == entity.status,
        orElse: () => PropertyStatus.available,
      ),
      description: entity.description,
      images: entity.images != null
          ? (jsonDecode(entity.images!) as List).cast<String>()
          : null,
      amenities: entity.amenities != null
          ? (jsonDecode(entity.amenities!) as List).cast<String>()
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<Property>> getAllProperties() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Property>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.propertiesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map(_fromEntity).toList();
  }

  // PropertyRepository interface implementation

  @override
  Stream<List<Property>> watchProperties({bool? isDeleted = false}) {
    var query = driftService.db.select(driftService.db.propertiesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }

    return query.watch().map((rows) => rows.map(_fromEntity).toList());
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
          updatedAt: DateTime.now(),
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
