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

  Tenant copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? idNumber,
    String? emergencyContact,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
