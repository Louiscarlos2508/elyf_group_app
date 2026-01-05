import '../entities/liquidity_checkpoint.dart';

/// Service de validation et logique métier pour les pointages de liquidité.
class LiquidityCheckpointService {
  LiquidityCheckpointService._();

  /// Valide un montant (cash ou SIM).
  /// Retourne null si valide, sinon un message d'erreur.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un montant';
    }
    final amount = int.tryParse(value.trim());
    if (amount == null || amount < 0) {
      return 'Montant invalide';
    }
    return null;
  }

  /// Valide qu'au moins un montant (cash ou SIM) est fourni.
  /// Retourne null si valide, sinon un message d'erreur.
  static String? validateAtLeastOneAmount(int cashAmount, int simAmount) {
    if (cashAmount <= 0 && simAmount <= 0) {
      return 'Veuillez entrer au moins un montant';
    }
    return null;
  }

  /// Crée un LiquidityCheckpoint à partir des données du formulaire.
  /// Gère la logique de création/update selon le type (matin/soir).
  static LiquidityCheckpoint createCheckpointFromInput({
    required String? existingId,
    required String enterpriseId,
    required DateTime date,
    required LiquidityCheckpointType period,
    required int cashAmount,
    required int simAmount,
    String? notes,
    LiquidityCheckpoint? existingCheckpoint,
  }) {
    final totalAmount = cashAmount + simAmount;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return LiquidityCheckpoint(
      id: existingId ??
          existingCheckpoint?.id ??
          'checkpoint-${DateTime.now().millisecondsSinceEpoch}',
      enterpriseId: enterpriseId,
      date: normalizedDate,
      type: period,
      amount: totalAmount,
      morningCheckpoint: period == LiquidityCheckpointType.morning
          ? totalAmount
          : existingCheckpoint?.morningCheckpoint,
      eveningCheckpoint: period == LiquidityCheckpointType.evening
          ? totalAmount
          : existingCheckpoint?.eveningCheckpoint,
      cashAmount: cashAmount > 0 ? cashAmount : null, // Pour compatibilité
      simAmount: simAmount > 0 ? simAmount : null, // Pour compatibilité
      morningCashAmount: period == LiquidityCheckpointType.morning
          ? (cashAmount > 0 ? cashAmount : null)
          : existingCheckpoint?.morningCashAmount,
      morningSimAmount: period == LiquidityCheckpointType.morning
          ? (simAmount > 0 ? simAmount : null)
          : existingCheckpoint?.morningSimAmount,
      eveningCashAmount: period == LiquidityCheckpointType.evening
          ? (cashAmount > 0 ? cashAmount : null)
          : existingCheckpoint?.eveningCashAmount,
      eveningSimAmount: period == LiquidityCheckpointType.evening
          ? (simAmount > 0 ? simAmount : null)
          : existingCheckpoint?.eveningSimAmount,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: existingCheckpoint?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

