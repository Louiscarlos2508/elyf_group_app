/// Représente une bobine (sachet en rouleau) comme matière première en stock.
/// Les bobines sont comptées par unité, sans poids.
class Bobine {
  const Bobine({
    required this.id,
    required this.enterpriseId,
    required this.reference,
    required this.dateReception,
    this.fournisseur,
    this.prixUnitaire,
    this.dateUtilisation,
    this.estUtilisee = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String reference; // Référence unique de la bobine
  final DateTime dateReception;
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (FCFA/unité)
  final DateTime? dateUtilisation; // Date de première utilisation
  final bool estUtilisee; // Indique si la bobine a été utilisée
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Vérifie si la bobine est disponible pour utilisation
  bool get estDisponible => !estUtilisee;
  bool get isDeleted => deletedAt != null;

  /// Calcule le coût total de la bobine (si prixUnitaire est défini)
  int? get coutTotal {
    if (prixUnitaire == null) return null;
    return prixUnitaire;
  }

  Bobine copyWith({
    String? id,
    String? enterpriseId,
    String? reference,
    DateTime? dateReception,
    String? fournisseur,
    int? prixUnitaire,
    DateTime? dateUtilisation,
    bool? estUtilisee,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Bobine(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      reference: reference ?? this.reference,
      dateReception: dateReception ?? this.dateReception,
      fournisseur: fournisseur ?? this.fournisseur,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
      estUtilisee: estUtilisee ?? this.estUtilisee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Bobine.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Bobine(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      reference: map['reference'] as String? ?? '',
      dateReception: DateTime.parse(map['dateReception'] as String),
      fournisseur: map['fournisseur'] as String?,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toInt(),
      dateUtilisation: map['dateUtilisation'] != null
          ? DateTime.parse(map['dateUtilisation'] as String)
          : null,
      estUtilisee: map['estUtilisee'] as bool? ?? false,
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
      'reference': reference,
      'dateReception': dateReception.toIso8601String(),
      'fournisseur': fournisseur,
      'prixUnitaire': prixUnitaire,
      'dateUtilisation': dateUtilisation?.toIso8601String(),
      'estUtilisee': estUtilisee,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}
