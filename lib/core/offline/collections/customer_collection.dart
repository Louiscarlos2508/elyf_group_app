/// Legacy CustomerCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class CustomerCollection {
  int id = 0;
  late String localId;
  late String remoteId;
  late String enterpriseId;
  late String moduleType;
  late String name;
  String? phone;
  String? phoneNumber;
  String? email;
  String? address;
  double balance = 0;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  CustomerCollection();

  factory CustomerCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    return CustomerCollection()
      ..localId = localId
      ..remoteId = map['id'] as String? ?? ''
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..name = map['name'] as String? ?? ''
      ..phone = map['phone'] as String?
      ..phoneNumber = map['phoneNumber'] as String? ?? map['phone'] as String?
      ..email = map['email'] as String?
      ..address = map['address'] as String?
      ..balance = (map['balance'] as num?)?.toDouble() ?? 0
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
    'phone': phone,
    'phoneNumber': phoneNumber,
    'email': email,
    'address': address,
    'balance': balance,
    'isActive': isActive,
  };
}
