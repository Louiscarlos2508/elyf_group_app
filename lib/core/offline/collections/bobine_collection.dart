/// Legacy BobineCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class BobineCollection {
  int id = 0;
  late String remoteId;
  late String enterpriseId;
  late String type;
  String? machineId;
  int quantity = 0;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  BobineCollection();

  Map<String, dynamic> toMap() => {
        'id': remoteId,
        'enterpriseId': enterpriseId,
        'type': type,
        'machineId': machineId,
        'quantity': quantity,
        'isActive': isActive,
      };
}
