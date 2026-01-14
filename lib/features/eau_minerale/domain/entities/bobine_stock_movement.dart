/// Représente un mouvement de stock pour une bobine (entrée ou sortie).
class BobineStockMovement {
  const BobineStockMovement({
    required this.id,
    required this.bobineId,
    required this.bobineReference,
    required this.type,
    required this.date,
    required this.quantite,
    required this.raison,
    this.productionId,
    this.machineId,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String bobineId;
  final String bobineReference;
  final BobineMovementType type;
  final DateTime date;
  final double quantite; // En unités
  final String
  raison; // Ex: "Livraison", "Installation en production", "Retrait après fin"
  final String? productionId; // ID de la production si lié à une production
  final String? machineId; // ID de la machine si lié à une installation
  final String? notes;
  final DateTime? createdAt;

  BobineStockMovement copyWith({
    String? id,
    String? bobineId,
    String? bobineReference,
    BobineMovementType? type,
    DateTime? date,
    double? quantite,
    String? raison,
    String? productionId,
    String? machineId,
    String? notes,
    DateTime? createdAt,
  }) {
    return BobineStockMovement(
      id: id ?? this.id,
      bobineId: bobineId ?? this.bobineId,
      bobineReference: bobineReference ?? this.bobineReference,
      type: type ?? this.type,
      date: date ?? this.date,
      quantite: quantite ?? this.quantite,
      raison: raison ?? this.raison,
      productionId: productionId ?? this.productionId,
      machineId: machineId ?? this.machineId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum BobineMovementType {
  /// Entrée en stock (livraison)
  entree,

  /// Sortie du stock (installation en production)
  sortie,

  /// Retrait après utilisation complète
  retrait,
}

extension BobineMovementTypeExtension on BobineMovementType {
  String get label {
    switch (this) {
      case BobineMovementType.entree:
        return 'Entrée';
      case BobineMovementType.sortie:
        return 'Sortie';
      case BobineMovementType.retrait:
        return 'Retrait';
    }
  }
}
