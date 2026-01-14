/// Represents a liquidity checkpoint (pointage de liquidité).
class LiquidityCheckpoint {
  const LiquidityCheckpoint({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.type,
    required this.amount,
    this.morningCheckpoint,
    this.eveningCheckpoint,
    this.cashAmount, // Montant en cash (FCFA) - pour compatibilité
    this.simAmount, // Solde sur la SIM (FCFA) - pour compatibilité
    this.morningCashAmount, // Cash du pointage du matin (FCFA)
    this.morningSimAmount, // SIM du pointage du matin (FCFA)
    this.eveningCashAmount, // Cash du pointage du soir (FCFA)
    this.eveningSimAmount, // SIM du pointage du soir (FCFA)
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final LiquidityCheckpointType type;
  final int amount; // Montant total en FCFA (cash + sim)
  final int? morningCheckpoint; // Pointage du matin en FCFA (total)
  final int? eveningCheckpoint; // Pointage du soir en FCFA (total)
  final int? cashAmount; // Montant en cash (FCFA) - pour compatibilité
  final int? simAmount; // Solde sur la SIM (FCFA) - pour compatibilité
  final int? morningCashAmount; // Cash du pointage du matin (FCFA)
  final int? morningSimAmount; // SIM du pointage du matin (FCFA)
  final int? eveningCashAmount; // Cash du pointage du soir (FCFA)
  final int? eveningSimAmount; // SIM du pointage du soir (FCFA)
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si le pointage du matin est effectué.
  bool get hasMorningCheckpoint =>
      (morningCashAmount != null && morningCashAmount! > 0) ||
      (morningSimAmount != null && morningSimAmount! > 0);

  /// Vérifie si le pointage du soir est effectué.
  bool get hasEveningCheckpoint =>
      (eveningCashAmount != null && eveningCashAmount! > 0) ||
      (eveningSimAmount != null && eveningSimAmount! > 0);

  /// Vérifie si les deux pointages sont effectués.
  bool get isComplete => hasMorningCheckpoint && hasEveningCheckpoint;
}

/// Type de pointage de liquidité.
enum LiquidityCheckpointType {
  morning('Matin'),
  evening('Soir'),
  full('Complet');

  const LiquidityCheckpointType(this.label);
  final String label;
}
