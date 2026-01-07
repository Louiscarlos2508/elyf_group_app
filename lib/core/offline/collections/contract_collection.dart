/// Stub ContractCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class ContractCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String propertyId;
  late String tenantId;
  late DateTime startDate;
  DateTime? endDate;
  double monthlyRent = 0;
  double deposit = 0;
  String status = 'active';
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  ContractCollection();

  /// Creates a ContractCollection from a map.
  factory ContractCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = ContractCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..propertyId = map['propertyId'] as String? ?? ''
      ..tenantId = map['tenantId'] as String? ?? ''
      ..startDate = map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now()
      ..endDate = map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null
      ..monthlyRent = (map['monthlyRent'] as num?)?.toDouble() ?? 0
      ..deposit = (map['deposit'] as num?)?.toDouble() ?? 0
      ..status = map['status'] as String? ?? 'active'
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'monthlyRent': monthlyRent,
        'deposit': deposit,
        'status': status,
      };
}
