/// Entité représentant une propriété immobilière.
class Property {
  Property({
    required this.id,
    required this.address,
    required this.city,
    required this.propertyType,
    required this.rooms,
    required this.area,
    required this.price,
    required this.status,
    this.description,
    this.images,
    this.amenities,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String address;
  final String city;
  final PropertyType propertyType;
  final int rooms;
  final int area; // en m²
  final int price; // prix de location mensuel en FCFA
  final PropertyStatus status;
  final String? description;
  final List<String>? images;
  final List<String>? amenities;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum PropertyType {
  house,
  apartment,
  studio,
  villa,
  commercial,
}

enum PropertyStatus {
  available,
  rented,
  maintenance,
  sold,
}

