import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';

class MockPropertyRepository implements PropertyRepository {
  final _properties = <String, Property>{};

  MockPropertyRepository() {
    _initMockData();
  }

  void _initMockData() {
    final properties = [
      Property(
        id: 'prop-1',
        address: '123 Rue de la Paix',
        city: 'Ouagadougou',
        propertyType: PropertyType.house,
        rooms: 3,
        area: 120,
        price: 150000,
        status: PropertyStatus.available,
        description: 'Belle maison avec jardin',
        amenities: ['Jardin', 'Garage', 'Climatisation'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Property(
        id: 'prop-2',
        address: '456 Avenue Kwame N\'Krumah',
        city: 'Ouagadougou',
        propertyType: PropertyType.apartment,
        rooms: 2,
        area: 80,
        price: 100000,
        status: PropertyStatus.rented,
        description: 'Appartement moderne',
        amenities: ['Balcon', 'Ascenseur'],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Property(
        id: 'prop-3',
        address: '789 Boulevard Charles de Gaulle',
        city: 'Ouagadougou',
        propertyType: PropertyType.villa,
        rooms: 5,
        area: 250,
        price: 300000,
        status: PropertyStatus.available,
        description: 'Villa de luxe avec piscine',
        amenities: ['Piscine', 'Jardin', 'Garage', 'Sécurité'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    for (final property in properties) {
      _properties[property.id] = property;
    }
  }

  @override
  Future<List<Property>> getAllProperties() async {
    return _properties.values.toList();
  }

  @override
  Future<Property?> getPropertyById(String id) async {
    return _properties[id];
  }

  @override
  Future<List<Property>> getPropertiesByStatus(PropertyStatus status) async {
    return _properties.values.where((p) => p.status == status).toList();
  }

  @override
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    return _properties.values.where((p) => p.propertyType == type).toList();
  }

  @override
  Future<Property> createProperty(Property property) async {
    final now = DateTime.now();
    final newProperty = Property(
      id: property.id,
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
      createdAt: now,
      updatedAt: now,
    );
    _properties[property.id] = newProperty;
    return newProperty;
  }

  @override
  Future<Property> updateProperty(Property property) async {
    final existing = _properties[property.id];
    if (existing == null) {
      throw NotFoundException(
        'Property not found',
        'PROPERTY_NOT_FOUND',
      );
    }
    final updated = Property(
      id: property.id,
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
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _properties[property.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteProperty(String id) async {
    _properties.remove(id);
  }
}
