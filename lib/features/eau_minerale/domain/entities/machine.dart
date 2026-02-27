/// Représente une machine de production.
class Machine {
  const Machine({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.reference,
    this.description,
    this.isActive = true,
    this.puissanceKw,
    this.dateInstallation,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String name; // Nom de la machine
  final String reference; // Référence unique
  final String? description;
  final bool isActive; // Indique si la machine est active
  final double? puissanceKw; // Puissance en kW
  final DateTime? dateInstallation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  Machine copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    String? reference,
    String? description,
    bool? isActive,
    double? puissanceKw,
    DateTime? dateInstallation,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Machine(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      puissanceKw: puissanceKw ?? this.puissanceKw,
      dateInstallation: dateInstallation ?? this.dateInstallation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Machine.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Machine(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String? ?? map['nom'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      description: map['description'] as String?,
      isActive: map['isActive'] as bool? ?? map['estActive'] as bool? ?? true,
      puissanceKw: (map['puissanceKw'] as num?)?.toDouble(),
      dateInstallation: map['dateInstallation'] != null
          ? DateTime.parse(map['dateInstallation'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'reference': reference,
      'description': description,
      'isActive': isActive,
      'puissanceKw': puissanceKw,
      'dateInstallation': dateInstallation?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}
