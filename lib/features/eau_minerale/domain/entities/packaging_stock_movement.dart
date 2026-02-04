/// Représente un mouvement de stock pour les emballages (entrée ou sortie).
class PackagingStockMovement {
  const PackagingStockMovement({
    required this.id,
    required this.packagingId,
    required this.packagingType,
    required this.type,
    required this.date,
    required this.quantite,
    required this.raison,
    this.productionId,
    this.fournisseur,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String packagingId;
  final String packagingType;
  final PackagingMovementType type;
  final DateTime date;
  final int quantite; // Quantité en unités
  final String
  raison; // Ex: "Livraison", "Utilisation en production", "Ajustement"
  final String? productionId; // ID de la production si lié à une production
  final String? fournisseur; // Fournisseur si entrée
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PackagingStockMovement copyWith({
    String? id,
    String? packagingId,
    String? packagingType,
    PackagingMovementType? type,
    DateTime? date,
    int? quantite,
    String? raison,
    String? productionId,
    String? fournisseur,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackagingStockMovement(
      id: id ?? this.id,
      packagingId: packagingId ?? this.packagingId,
      packagingType: packagingType ?? this.packagingType,
      type: type ?? this.type,
      date: date ?? this.date,
      quantite: quantite ?? this.quantite,
      raison: raison ?? this.raison,
      productionId: productionId ?? this.productionId,
      fournisseur: fournisseur ?? this.fournisseur,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PackagingMovementType {
  /// Entrée en stock (livraison)
  entree,

  /// Sortie du stock (utilisation en production)
  sortie,

  /// Ajustement manuel
  ajustement,
}

extension PackagingMovementTypeExtension on PackagingMovementType {
  String get label {
    switch (this) {
      case PackagingMovementType.entree:
        return 'Entrée';
      case PackagingMovementType.sortie:
        return 'Sortie';
      case PackagingMovementType.ajustement:
        return 'Ajustement';
    }
  }
}
