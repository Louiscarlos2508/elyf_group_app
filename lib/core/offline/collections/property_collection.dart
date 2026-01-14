/// Legacy PropertyCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class PropertyCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String name;
  late String address;
  String propertyType = 'house';
  int bedrooms = 0;
  int bathrooms = 0;
  double area = 0;
  double monthlyRent = 0;
  String status = 'available';
  String? description;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  PropertyCollection();

  /// Creates a PropertyCollection from a map.
  factory PropertyCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = PropertyCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..name = map['name'] as String? ?? ''
      ..address = map['address'] as String? ?? ''
      ..propertyType = map['propertyType'] as String? ?? 'house'
      ..bedrooms = (map['bedrooms'] as num?)?.toInt() ?? 0
      ..bathrooms = (map['bathrooms'] as num?)?.toInt() ?? 0
      ..area = (map['area'] as num?)?.toDouble() ?? 0
      ..monthlyRent = (map['monthlyRent'] as num?)?.toDouble() ?? 0
      ..status = map['status'] as String? ?? 'available'
      ..description = map['description'] as String?
      ..notes = map['notes'] as String?
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
    'id': remoteId ?? localId,
    'localId': localId,
    'enterpriseId': enterpriseId,
    'name': name,
    'address': address,
    'propertyType': propertyType,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'area': area,
    'monthlyRent': monthlyRent,
    'status': status,
    'description': description,
    'notes': notes,
  };
}
