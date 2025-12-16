/// Représente le stock d'emballages (packs, sachets, etc.).
class PackagingStock {
  const PackagingStock({
    required this.id,
    required this.type,
    required this.quantity,
    required this.unit,
    this.seuilAlerte,
    this.fournisseur,
    this.prixUnitaire,
    this.createdAt,
    this.updatedAt,
  }) : assert(
          quantity >= 0,
          'La quantité ne peut pas être négative',
        ),
        assert(
          seuilAlerte == null || seuilAlerte >= 0,
          'Le seuil d\'alerte ne peut pas être négatif',
        );

  final String id;
  final String type; // Type d'emballage (par défaut: "Emballage")
  final int quantity; // Quantité disponible
  final String unit; // Unité (ex: "packs", "sachets", "unités")
  final int? seuilAlerte; // Seuil d'alerte pour stock faible
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (CFA)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si le stock est faible (en dessous du seuil d'alerte)
  bool get estStockFaible {
    if (seuilAlerte == null) return false;
    return quantity <= seuilAlerte!;
  }

  /// Calcule le pourcentage de stock restant par rapport au seuil d'alerte
  double? get pourcentageRestant {
    if (seuilAlerte == null || seuilAlerte == 0) return null;
    return (quantity / seuilAlerte!) * 100;
  }

  /// Vérifie si le stock est suffisant pour une quantité donnée
  bool peutSatisfaire(int quantiteDemandee) {
    return quantity >= quantiteDemandee;
  }

  PackagingStock copyWith({
    String? id,
    String? type,
    int? quantity,
    String? unit,
    int? seuilAlerte,
    String? fournisseur,
    int? prixUnitaire,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackagingStock(
      id: id ?? this.id,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      fournisseur: fournisseur ?? this.fournisseur,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
