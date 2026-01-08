/// Legacy TenantCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class TenantCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String firstName;
  late String lastName;
  String? email;
  String? phone;
  String? idNumber;
  String? address;
  String? occupation;
  String? emergencyContact;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  TenantCollection();

  /// Creates a TenantCollection from a map.
  factory TenantCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = TenantCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..firstName = map['firstName'] as String? ?? ''
      ..lastName = map['lastName'] as String? ?? ''
      ..email = map['email'] as String?
      ..phone = map['phone'] as String?
      ..idNumber = map['idNumber'] as String?
      ..address = map['address'] as String?
      ..occupation = map['occupation'] as String?
      ..emergencyContact = map['emergencyContact'] as String?
      ..notes = map['notes'] as String?
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'idNumber': idNumber,
        'address': address,
        'occupation': occupation,
        'emergencyContact': emergencyContact,
        'notes': notes,
      };
}
