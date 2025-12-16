/// Type d'événement pouvant survenir pendant une production.
enum ProductionEventType {
  /// Panne de machine
  panne,

  /// Coupure de courant
  coupure,

  /// Arrêt forcé de la production
  arretForce,
}

extension ProductionEventTypeExtension on ProductionEventType {
  /// Libellé du type d'événement
  String get label {
    switch (this) {
      case ProductionEventType.panne:
        return 'Panne';
      case ProductionEventType.coupure:
        return 'Coupure';
      case ProductionEventType.arretForce:
        return 'Arrêt forcé';
    }
  }

  /// Icône associée au type d'événement
  String get icon {
    switch (this) {
      case ProductionEventType.panne:
        return '🔧';
      case ProductionEventType.coupure:
        return '⚡';
      case ProductionEventType.arretForce:
        return '⛔';
    }
  }
}

/// Représente un événement survenu pendant une production
/// (panne, coupure, arrêt forcé).
class ProductionEvent {
  const ProductionEvent({
    required this.id,
    required this.productionId,
    required this.type,
    required this.date,
    required this.heure,
    required this.motif,
    this.duree,
    this.heureReprise,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String productionId; // ID de la production concernée
  final ProductionEventType type;
  final DateTime date;
  final DateTime heure;
  final String motif; // Description de l'événement
  final Duration? duree; // Durée de l'événement (si terminé)
  final DateTime? heureReprise; // Heure de reprise (si reprise)
  final String? notes; // Notes supplémentaires
  final DateTime? createdAt;

  /// Vérifie si l'événement est terminé (reprise enregistrée)
  bool get estTermine => heureReprise != null;

  /// Calcule la durée totale si l'événement est terminé
  Duration? get dureeTotale {
    if (heureReprise == null) return null;
    return heureReprise!.difference(heure);
  }

  ProductionEvent copyWith({
    String? id,
    String? productionId,
    ProductionEventType? type,
    DateTime? date,
    DateTime? heure,
    String? motif,
    Duration? duree,
    DateTime? heureReprise,
    String? notes,
    DateTime? createdAt,
  }) {
    return ProductionEvent(
      id: id ?? this.id,
      productionId: productionId ?? this.productionId,
      type: type ?? this.type,
      date: date ?? this.date,
      heure: heure ?? this.heure,
      motif: motif ?? this.motif,
      duree: duree ?? this.duree,
      heureReprise: heureReprise ?? this.heureReprise,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
