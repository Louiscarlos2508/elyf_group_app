import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/property_collection.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';

/// Offline-first repository for Property entities.
class PropertyOfflineRepository extends OfflineRepository<Property>
    implements PropertyRepository {
  PropertyOfflineRepository({
    required super.isarService,
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
    final collection = PropertyCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.propertyCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Property entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.propertyCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.propertyCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Property?> getByLocalId(String localId) async {
    var collection = await isarService.isar.propertyCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    collection = await isarService.isar.propertyCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    return null;
  }

  @override
  Future<List<Property>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.propertyCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // PropertyRepository interface implementation

  @override
  Future<List<Property>> getAllProperties() async {
    try {
      developer.log(
        'Fetching properties for enterprise: $enterpriseId',
        name: 'PropertyOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching properties',
        name: 'PropertyOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Property?> getPropertyById(String id) async {
    try {
      final collection = await isarService.isar.propertyCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting property: $id',
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
      return allProperties
          .where((p) => p.status == status)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting properties by status',
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
      return allProperties
          .where((p) => p.propertyType == type)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting properties by type',
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
        updatedAt: property.updatedAt,
      );
      await save(propertyWithLocalId);
      return propertyWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating property',
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
      await save(property);
      return property;
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
      developer.log(
        'Error deleting property: $id',
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

