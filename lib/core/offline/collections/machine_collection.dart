/// Stub MachineCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class MachineCollection {
  int id = 0;
  late String localId;
  late String remoteId;
  late String enterpriseId;
  late String name;
  late String reference;
  String? description;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  MachineCollection();

  factory MachineCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    return MachineCollection()
      ..localId = localId
      ..remoteId = map['id'] as String? ?? ''
      ..enterpriseId = enterpriseId
      ..name = map['name'] as String? ?? ''
      ..reference = map['reference'] as String? ?? ''
      ..description = map['description'] as String?
      ..isActive = map['isActive'] as bool? ?? true
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
        'name': name,
        'reference': reference,
        'description': description,
        'isActive': isActive,
      };
}
