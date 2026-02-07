/// Représente le stock d'emballages (packs, sachets, etc.).
class PackagingStock {
  const PackagingStock({
    required this.id,
    required this.type,
    required this.quantity,
    required this.unit,
    this.unitsPerLot = 1, // Par défaut, 1 unité par lot (si non défini)
    this.seuilAlerte,
    this.fournisseur,
    this.prixUnitaire,
    this.createdAt,
    this.updatedAt,
  }) : assert(quantity >= 0, 'La quantité ne peut pas être négative'),
       assert(unitsPerLot > 0, 'Le nombre d\'unités par lot doit être positif'),
       assert(
         seuilAlerte == null || seuilAlerte >= 0,
         'Le seuil d\'alerte ne peut pas être négatif',
       );

  final String id;
  final String type; // Type d'emballage (par défaut: "Emballage")
  final int quantity; // Quantité disponible (toujours en UNITÉS dans la base)
  final String unit; // Unité d'affichage (ex: "films", "sachets")
  final int unitsPerLot; // Nombre d'unités contenues dans un lot d'achat
  final int? seuilAlerte; // Seuil d'alerte pour stock faible (en UNITÉS)
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (CFA)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Retourne la quantité exprimée en lots
  double get quantityInLots => quantity / unitsPerLot;

  /// Retourne le nombre de lots complets
  int get fullLots => quantity ~/ unitsPerLot;

  /// Retourne le surplus d'unités (après lots complets)
  int get remainingUnits => quantity % unitsPerLot;

  /// Libellé lisible de la quantité (ex: "2 lots et 50 unités")
  String get quantityLabel {
    if (unitsPerLot <= 1) return '$quantity $unit';
    final lots = fullLots;
    final units = remainingUnits;
    if (lots == 0) return '$units $unit';
    if (units == 0) return '$lots lot(s)';
    return '$lots lot(s) + $units $unit';
  }

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
    int? unitsPerLot,
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
      unitsPerLot: unitsPerLot ?? this.unitsPerLot,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      fournisseur: fournisseur ?? this.fournisseur,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
