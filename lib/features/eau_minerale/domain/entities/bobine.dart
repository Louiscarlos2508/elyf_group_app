/// Représente une bobine de matière première (sachet) en stock.
class Bobine {
  const Bobine({
    required this.id,
    required this.reference,
    required this.poidsActuel,
    required this.poidsInitial,
    required this.dateReception,
    this.fournisseur,
    this.prixUnitaire,
    this.dateUtilisation,
    this.estUtilisee = false,
    this.createdAt,
    this.updatedAt,
  }) : assert(
          poidsActuel <= poidsInitial,
          'Le poids actuel ne peut pas être supérieur au poids initial',
        );

  final String id;
  final String reference; // Référence unique de la bobine
  final double poidsActuel; // kg - poids actuel disponible
  final double poidsInitial; // kg - poids initial à la réception
  final DateTime dateReception;
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (CFA/kg)
  final DateTime? dateUtilisation; // Date de première utilisation
  final bool estUtilisee; // Indique si la bobine a été utilisée
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Calcule le poids utilisé (kg)
  double get poidsUtilise => poidsInitial - poidsActuel;

  /// Calcule le pourcentage de poids restant
  double get pourcentageRestant {
    if (poidsInitial == 0) return 0;
    return (poidsActuel / poidsInitial) * 100;
  }

  /// Vérifie si la bobine est complètement utilisée
  bool get estCompletementUtilisee => poidsActuel <= 0;

  /// Vérifie si la bobine est disponible pour utilisation
  bool get estDisponible => !estCompletementUtilisee;

  /// Calcule le coût total de la bobine (si prixUnitaire est défini)
  int? get coutTotal {
    if (prixUnitaire == null) return null;
    return (poidsInitial * prixUnitaire!).round();
  }

  Bobine copyWith({
    String? id,
    String? reference,
    double? poidsActuel,
    double? poidsInitial,
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
      poidsActuel: poidsActuel ?? this.poidsActuel,
      poidsInitial: poidsInitial ?? this.poidsInitial,
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

