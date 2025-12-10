/// Représente un mouvement de trésorerie.
class TreasuryMovement {
  const TreasuryMovement({
    required this.id,
    required this.type,
    required this.amount,
    required this.method,
    required this.date,
    required this.description,
    this.reference,
    this.createdAt,
  });

  final String id;
  final TreasuryMovementType type; // Type de mouvement
  final int amount; // Montant en CFA
  final PaymentMethod method; // Méthode de paiement
  final DateTime date;
  final String description;
  final String? reference; // Référence (ex: ID vente, ID achat)
  final DateTime? createdAt;

  /// Vérifie si c'est une entrée
  bool get isEntree => type == TreasuryMovementType.entree;

  /// Vérifie si c'est une sortie
  bool get isSortie => type == TreasuryMovementType.sortie;

  /// Vérifie si c'est un transfert
  bool get isTransfert => type == TreasuryMovementType.transfert;

  TreasuryMovement copyWith({
    String? id,
    TreasuryMovementType? type,
    int? amount,
    PaymentMethod? method,
    DateTime? date,
    String? description,
    String? reference,
    DateTime? createdAt,
  }) {
    return TreasuryMovement(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      date: date ?? this.date,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Type de mouvement de trésorerie.
enum TreasuryMovementType {
  entree, // Entrée d'argent
  sortie, // Sortie d'argent
  transfert, // Transfert entre Cash et Orange Money
}

/// Méthode de paiement.
enum PaymentMethod {
  cash, // Espèces
  orangeMoney, // Orange Money
}

