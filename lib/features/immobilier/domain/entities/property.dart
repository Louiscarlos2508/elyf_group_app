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
    this.deletedAt,
    this.deletedBy,
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
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;
  Property copyWith({
    String? id,
    String? address,
    String? city,
    PropertyType? propertyType,
    int? rooms,
    int? area,
    int? price,
    PropertyStatus? status,
    String? description,
    List<String>? images,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Property(
      id: id ?? this.id,
      address: address ?? this.address,
      city: city ?? this.city,
      propertyType: propertyType ?? this.propertyType,
      rooms: rooms ?? this.rooms,
      area: area ?? this.area,
      price: price ?? this.price,
      status: status ?? this.status,
      description: description ?? this.description,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum PropertyType { house, apartment, studio, villa, commercial }

enum PropertyStatus { available, rented, maintenance, sold }
