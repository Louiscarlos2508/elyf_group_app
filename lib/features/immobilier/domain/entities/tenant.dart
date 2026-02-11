/// Entité représentant un locataire.
class Tenant {
  Tenant({
    required this.id,
    required this.enterpriseId,
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
  final String enterpriseId;
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
    String? enterpriseId,
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
      enterpriseId: enterpriseId ?? this.enterpriseId,
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

  /// Représentation sérialisable pour logs / audit trail / persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'idNumber': idNumber,
      'emergencyContact': emergencyContact,
      'idCardPath': idCardPath,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      idNumber: map['idNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      idCardPath: map['idCardPath'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
