import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';

/// Offline-first repository for Property entities.
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

  @override
  Property fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String? ?? map['localId'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      propertyType: _parsePropertyType(map['propertyType'] as String),
      rooms: map['rooms'] as int? ?? 0,
      area: (map['area'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toInt() ?? 0,
      status: _parsePropertyStatus(map['status'] as String),
      description: map['description'] as String?,
      images: map['images'] != null
          ? (map['images'] as List).cast<String>()
          : null,
      amenities: map['amenities'] != null
          ? (map['amenities'] as List).cast<String>()
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Property entity) {
    return {
      'id': entity.id,
      'address': entity.address,
      'city': entity.city,
      'propertyType': entity.propertyType.name,
      'rooms': entity.rooms,
      'area': entity.area.toDouble(),
      'price': entity.price.toDouble(),
      'status': entity.status.name,
      'description': entity.description,
      'images': entity.images,
      'amenities': entity.amenities,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Property entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Property entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'immobilier',
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
        moduleType: 'immobilier',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
  }

  @override
  Future<Property?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Property>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    final properties = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    return deduplicateByRemoteId(properties);
  }

  // PropertyRepository interface implementation

  @override
  Stream<List<Property>> watchProperties() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'immobilier',
        )
        .map((rows) {
          final entities = rows
              .map(
                (r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>),
              )
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Future<Property?> getPropertyById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting property: $id - ${appException.message}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Property>> getPropertiesByStatus(PropertyStatus status) async {
    try {
      final allProperties = await getAllForEnterprise(enterpriseId);
      return allProperties.where((p) => p.status == status).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting properties by status: ${appException.message}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    try {
      final allProperties = await getAllForEnterprise(enterpriseId);
      return allProperties.where((p) => p.propertyType == type).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting properties by type: ${appException.message}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Property> createProperty(Property property) async {
    try {
      final localId = getLocalId(property);
      final propertyWithLocalId = Property(
        id: localId,
        address: property.address,
        city: property.city,
        propertyType: property.propertyType,
        rooms: property.rooms,
        area: property.area,
        price: property.price,
        status: property.status,
        description: property.description,
        images: property.images,
        amenities: property.amenities,
        createdAt: property.createdAt,
        updatedAt: DateTime.now(),
      );
      await save(propertyWithLocalId);
      return propertyWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating property: ${appException.message}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Property> updateProperty(Property property) async {
    try {
      final updatedProperty = property.copyWith(updatedAt: DateTime.now());
      await save(updatedProperty);
      return updatedProperty;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating property: ${property.id}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting property: $id - ${appException.message}',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  PropertyType _parsePropertyType(String type) {
    switch (type) {
      case 'house':
        return PropertyType.house;
      case 'apartment':
        return PropertyType.apartment;
      case 'studio':
        return PropertyType.studio;
      case 'villa':
        return PropertyType.villa;
      case 'commercial':
        return PropertyType.commercial;
      default:
        return PropertyType.house;
    }
  }

  PropertyStatus _parsePropertyStatus(String status) {
    switch (status) {
      case 'available':
        return PropertyStatus.available;
      case 'rented':
        return PropertyStatus.rented;
      case 'maintenance':
        return PropertyStatus.maintenance;
      case 'sold':
        return PropertyStatus.sold;
      default:
        return PropertyStatus.available;
    }
  }
}
