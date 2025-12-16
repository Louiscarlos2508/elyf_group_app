/// Représente une bobine (sachet en rouleau) comme matière première en stock.
/// Les bobines sont comptées par unité, sans poids.
class Bobine {
  const Bobine({
    required this.id,
    required this.reference,
    required this.dateReception,
    this.fournisseur,
    this.prixUnitaire,
    this.dateUtilisation,
    this.estUtilisee = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reference; // Référence unique de la bobine
  final DateTime dateReception;
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (FCFA/unité)
  final DateTime? dateUtilisation; // Date de première utilisation
  final bool estUtilisee; // Indique si la bobine a été utilisée
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si la bobine est disponible pour utilisation
  bool get estDisponible => !estUtilisee;

  /// Calcule le coût total de la bobine (si prixUnitaire est défini)
  int? get coutTotal {
    if (prixUnitaire == null) return null;
    return prixUnitaire;
  }

  Bobine copyWith({
    String? id,
    String? reference,
    DateTime? dateReception,
    String? fournisseur,
    int? prixUnitaire,
    DateTime? dateUtilisation,
    bool? estUtilisee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bobine(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      dateReception: dateReception ?? this.dateReception,
      fournisseur: fournisseur ?? this.fournisseur,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
      estUtilisee: estUtilisee ?? this.estUtilisee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

