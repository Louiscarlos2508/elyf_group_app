import '../entities/liquidity_checkpoint.dart';
import '../entities/transaction.dart';
import '../repositories/liquidity_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transaction_repository.dart';

/// Service for managing liquidity checkpoints with theoretical calculations.
class LiquidityService {
  LiquidityService({
    required LiquidityRepository liquidityRepository,
    required SettingsRepository settingsRepository,
    required TransactionRepository transactionRepository,
  })  : _liquidityRepo = liquidityRepository,
        _settingsRepo = settingsRepository,
        _transactionRepo = transactionRepository;

  final LiquidityRepository _liquidityRepo;
  final SettingsRepository _settingsRepo;
  final TransactionRepository _transactionRepo;

  /// Créer un pointage avec calcul théorique automatique
  Future<LiquidityCheckpoint> createCheckpoint({
    required String enterpriseId,
    required LiquidityCheckpointType type,
    required int cashAmount,
    required int simAmount,
    String? notes,
  }) async {
    // 1. Vérifier horaires
    final now = DateTime.now();
    _validateCheckpointTime(type, now);

    // 2. Si pointage du soir, calculer théorique
    int? theoreticalCash;
    int? theoreticalSim;
    int? cashDiscrepancy;
    int? simDiscrepancy;
    double? discrepancyPercentage;
    bool requiresJustification = false;

    if (type == LiquidityCheckpointType.evening) {
      // Récupérer pointage du matin
      final morningCheckpoint = await _liquidityRepo.getMorningCheckpoint(
        enterpriseId: enterpriseId,
        date: now,
      );

      if (morningCheckpoint != null &&
          morningCheckpoint.cashAmount != null &&
          morningCheckpoint.simAmount != null) {
        // Calculer théorique
        final theoretical = await calculateTheoreticalLiquidity(
          enterpriseId: enterpriseId,
          date: now,
          morningCash: morningCheckpoint.cashAmount!,
          morningSim: morningCheckpoint.simAmount!,
        );

        theoreticalCash = theoretical.cash;
        theoreticalSim = theoretical.sim;

        // Calculer écarts
        cashDiscrepancy = cashAmount - theoreticalCash;
        simDiscrepancy = simAmount - theoreticalSim;

        final totalDiscrepancy = cashDiscrepancy.abs() + simDiscrepancy.abs();
        final totalTheoretical = theoreticalCash + theoreticalSim;

        if (totalTheoretical > 0) {
          discrepancyPercentage = (totalDiscrepancy / totalTheoretical * 100);

          // Vérifier seuil
          final settings = await _settingsRepo.getSettings(enterpriseId);
          if (settings != null &&
              discrepancyPercentage > settings.checkpointDiscrepancyThreshold) {
            requiresJustification = true;

            // TODO: Envoyer alerte superviseur
          }
        }
      }
    }

    // 3. Créer checkpoint
    final checkpoint = LiquidityCheckpoint(
      id: _generateId(),
      enterpriseId: enterpriseId,
      date: now,
      type: type,
      amount: cashAmount + simAmount,
      cashAmount: cashAmount,
      simAmount: simAmount,
      morningCashAmount: type == LiquidityCheckpointType.morning ? cashAmount : null,
      morningSimAmount: type == LiquidityCheckpointType.morning ? simAmount : null,
      eveningCashAmount: type == LiquidityCheckpointType.evening ? cashAmount : null,
      eveningSimAmount: type == LiquidityCheckpointType.evening ? simAmount : null,
      theoreticalCash: theoreticalCash,
      theoreticalSim: theoreticalSim,
      cashDiscrepancy: cashDiscrepancy,
      simDiscrepancy: simDiscrepancy,
      discrepancyPercentage: discrepancyPercentage,
      requiresJustification: requiresJustification,
      notes: notes,
      createdAt: now,
    );

    await _liquidityRepo.createCheckpoint(checkpoint);

    return checkpoint;
  }

  /// Calculer liquidité théorique
  Future<TheoreticalLiquidity> calculateTheoreticalLiquidity({
    required String enterpriseId,
    required DateTime date,
    required int morningCash,
    required int morningSim,
  }) async {
    // Récupérer transactions du jour
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final transactions = await _transactionRepo.fetchTransactions(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    // Filtrer les transactions complétées
    final List<Transaction> completedTransactions = transactions
        .where((tx) => tx.status == TransactionStatus.completed)
        .toList();

    int cashMovement = 0;
    int simMovement = 0;

    for (final Transaction tx in completedTransactions) {
      if (tx.type == TransactionType.cashIn) {
        // Cash-In : Cash entre, SIM sort
        cashMovement += tx.amount.toInt();
        simMovement -= tx.amount.toInt();
        // Commission va dans cash
        if (tx.commission != null) {
          cashMovement += tx.commission!.toInt();
        }
      } else {
        // Cash-Out : Cash sort, SIM entre
        cashMovement -= tx.amount.toInt();
        simMovement += tx.amount.toInt();
        // Commission sort du cash
        if (tx.commission != null) {
          cashMovement -= tx.commission!.toInt();
        }
      }
    }

    return TheoreticalLiquidity(
      cash: morningCash + cashMovement,
      sim: morningSim + simMovement,
      cashMovement: cashMovement,
      simMovement: simMovement,
      transactionsProcessed: completedTransactions.length,
    );
  }

  /// Valider un écart avec justification
  Future<LiquidityCheckpoint> validateDiscrepancy({
    required String checkpointId,
    required String validatedBy,
    required String justification,
  }) async {
    final checkpoint = await _liquidityRepo.getCheckpoint(checkpointId);

    if (checkpoint == null) {
      throw Exception('Checkpoint not found: $checkpointId');
    }

    if (!checkpoint.requiresJustification) {
      throw Exception('Checkpoint does not require justification');
    }

    final updated = checkpoint.copyWith(
      justification: justification,
      validatedBy: validatedBy,
      validatedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _liquidityRepo.updateCheckpoint(updated);

    return updated;
  }

  /// Valider les horaires de pointage
  void _validateCheckpointTime(LiquidityCheckpointType type, DateTime now) {
    if (type == LiquidityCheckpointType.morning) {
      if (now.hour < 6 || now.hour > 12) {
        throw Exception('Pointage du matin entre 6h et 12h');
      }
    } else if (type == LiquidityCheckpointType.evening) {
      if (now.hour < 17 || now.hour > 23) {
        throw Exception('Pointage du soir entre 17h et 23h');
      }
    }
  }

  /// Générer un ID unique
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
