/// Stub AgentCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class AgentCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String name;
  String? phone;
  double balance = 0;
  double commission = 0;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  AgentCollection();

  /// Creates an AgentCollection from a map.
  factory AgentCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = AgentCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..name = map['name'] as String? ?? ''
      ..phone = map['phone'] as String?
      ..balance = (map['balance'] as num?)?.toDouble() ?? 0
      ..commission = (map['commission'] as num?)?.toDouble() ?? 0
      ..isActive = map['isActive'] as bool? ?? true
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'name': name,
        'phone': phone,
        'balance': balance,
        'commission': commission,
        'isActive': isActive,
      };
}
