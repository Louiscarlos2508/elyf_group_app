/// Entité représentant un locataire.
class Tenant {
  Tenant({
    required this.id,
    required this.fullName,
    required this.phone,
    this.address,
    this.idNumber,
    this.emergencyContact,
    this.idCardPath,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? address;
  final String? idNumber;
  final String? emergencyContact;
  final String? idCardPath; // Chemin vers la photo de la pièce d'identité
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  Tenant copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? idNumber,
    String? emergencyContact,
    String? idCardPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Tenant(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      idCardPath: idCardPath ?? this.idCardPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
