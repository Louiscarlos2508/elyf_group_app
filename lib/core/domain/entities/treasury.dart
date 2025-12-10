import 'treasury_movement.dart';

/// Représente la trésorerie d'un module.
class Treasury {
  const Treasury({
    required this.id,
    required this.moduleId,
    required this.soldeCash,
    required this.soldeOrangeMoney,
    required this.mouvements,
    this.updatedAt,
  });

  final String id;
  final String moduleId; // ID du module (eau_minerale, boutique, immobilier)
  final int soldeCash; // Solde en espèces (CFA)
  final int soldeOrangeMoney; // Solde Orange Money (CFA)
  final List<TreasuryMovement> mouvements; // Historique des mouvements
  final DateTime? updatedAt;

  /// Calcule le solde total (Cash + Orange Money)
  int get soldeTotal => soldeCash + soldeOrangeMoney;

  /// Récupère les mouvements récents (derniers N)
  List<TreasuryMovement> getRecentMovements([int limit = 10]) {
    final sorted = List<TreasuryMovement>.from(mouvements)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Récupère les mouvements par type
  List<TreasuryMovement> getMovementsByType(TreasuryMovementType type) {
    return mouvements.where((m) => m.type == type).toList();
  }

  /// Récupère les mouvements par méthode de paiement
  List<TreasuryMovement> getMovementsByMethod(PaymentMethod method) {
    return mouvements.where((m) => m.method == method).toList();
  }

  /// Calcule le total des entrées
  int get totalEntrees {
    return mouvements
        .where((m) => m.type == TreasuryMovementType.entree)
        .fold<int>(0, (sum, m) => sum + m.amount);
  }

  /// Calcule le total des sorties
  int get totalSorties {
    return mouvements
        .where((m) => m.type == TreasuryMovementType.sortie)
        .fold<int>(0, (sum, m) => sum + m.amount);
  }

  Treasury copyWith({
    String? id,
    String? moduleId,
    int? soldeCash,
    int? soldeOrangeMoney,
    List<TreasuryMovement>? mouvements,
    DateTime? updatedAt,
  }) {
    return Treasury(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      soldeCash: soldeCash ?? this.soldeCash,
      soldeOrangeMoney: soldeOrangeMoney ?? this.soldeOrangeMoney,
      mouvements: mouvements ?? this.mouvements,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

