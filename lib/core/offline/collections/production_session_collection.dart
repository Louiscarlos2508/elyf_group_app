/// Stub ProductionSessionCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class ProductionSessionCollection {
  int id = 0;
  late String localId;
  late String remoteId;
  late String enterpriseId;
  late DateTime sessionDate;
  int period = 1;
  DateTime? startTime;
  DateTime? endTime;
  double electricityConsumption = 0;
  double quantityProduced = 0;
  String quantityUnit = 'pack';
  String status = 'draft';
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;
  
  // JSON fields for complex data
  String? bobinesUtiliseesJson;
  String? eventsJson;
  String? productionDaysJson;

  ProductionSessionCollection();

  factory ProductionSessionCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    return ProductionSessionCollection()
      ..localId = localId
      ..remoteId = map['id'] as String? ?? ''
      ..enterpriseId = enterpriseId
      ..sessionDate = map['sessionDate'] != null
          ? DateTime.parse(map['sessionDate'] as String)
          : DateTime.now()
      ..period = map['period'] as int? ?? 1
      ..startTime = map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null
      ..endTime = map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null
      ..electricityConsumption =
          (map['electricityConsumption'] as num?)?.toDouble() ?? 0
      ..quantityProduced = (map['quantityProduced'] as num?)?.toDouble() ?? 0
      ..quantityUnit = map['quantityUnit'] as String? ?? 'pack'
      ..status = map['status'] as String? ?? 'draft'
      ..notes = map['notes'] as String?
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null
      ..localUpdatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId,
        'enterpriseId': enterpriseId,
        'sessionDate': sessionDate.toIso8601String(),
        'period': period,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'electricityConsumption': electricityConsumption,
        'quantityProduced': quantityProduced,
        'quantityUnit': quantityUnit,
        'status': status,
        'notes': notes,
      };
}
