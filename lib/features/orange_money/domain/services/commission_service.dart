import '../entities/commission.dart';
import '../entities/transaction.dart';
import '../repositories/commission_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transaction_repository.dart';

/// Service for managing commissions with hybrid model (estimated + declared).
class CommissionService {
  CommissionService({
    required CommissionRepository commissionRepository,
    required SettingsRepository settingsRepository,
    required TransactionRepository transactionRepository,
  })  : _commissionRepo = commissionRepository,
        _settingsRepo = settingsRepository,
        _transactionRepo = transactionRepository;

  final CommissionRepository _commissionRepo;
  final SettingsRepository _settingsRepo;
  final TransactionRepository _transactionRepo;

  /// Calcule les commissions estimées du mois
  Future<Commission> calculateMonthlyCommission({
    required String enterpriseId,
    required String period, // "YYYY-MM"
  }) async {
    // 1. Récupérer les paramètres
    final settings = await _settingsRepo.getSettings(enterpriseId);
    if (settings == null) {
      throw Exception('Settings not found for enterprise $enterpriseId');
    }

    // 2. Récupérer toutes les transactions du mois
    final transactions = await _transactionRepo.fetchTransactions(
      startDate: _parseMonthStart(period),
      endDate: _parseMonthEnd(period),
    );

    // 3. Filtrer les transactions complétées
    final completedTransactions = transactions
        .where((tx) => tx.status == TransactionStatus.completed)
        .toList();

    // 4. No more system-calculated estimation (User request)
    const details = CommissionCalculationDetails(
      transactionsByTranche: {},
      commissionsByTranche: {},
      totalCashIn: 0,
      totalCashOut: 0,
      cashInCommission: 0,
      cashOutCommission: 0,
    );
    
    // 5. Amount is 0 until declared
    const estimatedAmount = 0;

    // 6. Créer commission
    final commission = Commission(
      id: '${enterpriseId}_$period',
      enterpriseId: enterpriseId,
      period: period,
      estimatedAmount: estimatedAmount,
      transactionsCount: completedTransactions.length,
      calculationDetails: details,
      status: CommissionStatus.estimated,
      createdAt: DateTime.now(),
    );

    await _commissionRepo.createCommission(commission);

    return commission;
  }

  /// Agent déclare le montant du SMS opérateur
  Future<Commission> declareCommission({
    required String commissionId,
    required int declaredAmount,
    required String smsProofUrl,
    required String declaredBy,
  }) async {
    final commission = await _commissionRepo.getCommission(commissionId);

    if (commission == null) {
      throw Exception('Commission not found: $commissionId');
    }

    if (commission.status != CommissionStatus.estimated) {
      throw Exception(
        'Commission must be in estimated status to declare. Current: ${commission.status}',
      );
    }

    // Pas d'écart car pas d'estimation
    const discrepancy = 0;
    const discrepancyPercentage = 0.0;
    const discrepancyStatus = DiscrepancyStatus.conforme;

    // Mettre à jour
    final updated = commission.copyWith(
      declaredAmount: declaredAmount,
      smsProofUrl: smsProofUrl,
      declaredAt: DateTime.now(),
      declaredBy: declaredBy,
      discrepancy: discrepancy,
      discrepancyPercentage: discrepancyPercentage,
      discrepancyStatus: discrepancyStatus,
      status: CommissionStatus.declared,
      updatedAt: DateTime.now(),
    );

    await _commissionRepo.updateCommission(updated);

    return updated;
  }


  /// Marquer comme payée avec preuve
  Future<Commission> markAsPaid({
    required String commissionId,
    required String paymentProofUrl,
    String? notes,
  }) async {
    final commission = await _commissionRepo.getCommission(commissionId);

    if (commission == null) {
      throw Exception('Commission not found: $commissionId');
    }

    if (commission.status != CommissionStatus.declared) {
      throw Exception(
        'Commission must be declared to mark as paid. Current: ${commission.status}',
      );
    }

    final updated = commission.copyWith(
      status: CommissionStatus.paid,
      paidAt: DateTime.now(),
      paymentProofUrl: paymentProofUrl,
      notes: notes ?? commission.notes,
      updatedAt: DateTime.now(),
    );

    await _commissionRepo.updateCommission(updated);

    return updated;
  }


  // Removed _calculateCommissionDetails as per user request to disable system calculations

  /// Parse le début du mois depuis "YYYY-MM"
  DateTime _parseMonthStart(String period) {
    final parts = period.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  /// Parse la fin du mois depuis "YYYY-MM"
  DateTime _parseMonthEnd(String period) {
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}
