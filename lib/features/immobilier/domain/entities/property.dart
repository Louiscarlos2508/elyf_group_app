/// Entité représentant une propriété immobilière.
class Property {
  Property({
    required this.id,
    required this.enterpriseId,
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
  final String enterpriseId;
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
    String? enterpriseId,
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
      enterpriseId: enterpriseId ?? this.enterpriseId,
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

  /// Représentation sérialisable pour logs / audit trail / persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'address': address,
      'city': city,
      'propertyType': propertyType.name,
      'rooms': rooms,
      'area': area,
      'price': price,
      'status': status.name,
      'description': description,
      'images': images,
      'amenities': amenities,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == map['propertyType'],
        orElse: () => PropertyType.house,
      ),
      rooms: (map['rooms'] as num).toInt(),
      area: (map['area'] as num).toInt(),
      price: (map['price'] as num).toInt(),
      status: PropertyStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PropertyStatus.available,
      ),
      description: map['description'] as String?,
      images: (map['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      amenities: (map['amenities'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
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
