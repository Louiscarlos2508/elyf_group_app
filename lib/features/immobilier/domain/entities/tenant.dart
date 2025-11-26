/// Entité représentant un locataire.
class Tenant {
  Tenant({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.address,
    this.idNumber,
    this.emergencyContact,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? address;
  final String? idNumber;
  final String? emergencyContact;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

