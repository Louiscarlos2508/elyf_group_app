/// Stub EnterpriseCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class EnterpriseCollection {
  int id = 0;
  late String remoteId;
  late String name;
  String? description;
  late String type;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  EnterpriseCollection();

  Map<String, dynamic> toMap() => {
        'id': remoteId,
        'name': name,
        'description': description,
        'type': type,
        'isActive': isActive,
      };
}
