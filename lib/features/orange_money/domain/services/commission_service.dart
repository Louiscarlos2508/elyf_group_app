import '../entities/commission.dart';
import '../entities/orange_money_settings.dart';
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

    // 4. Calculer par tranche
    final details = _calculateCommissionDetails(
      transactions: completedTransactions,
      cashInTiers: settings.cashInTiers,
      cashOutTiers: settings.cashOutTiers,
    );

    // 5. Total estimé
    final estimatedAmount = details.cashInCommission + details.cashOutCommission;

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

    // Calculer l'écart
    final discrepancy = declaredAmount - commission.estimatedAmount;
    final discrepancyPercentage =
        (discrepancy.abs() / commission.estimatedAmount * 100);

    // Déterminer le statut de l'écart
    final settings = await _settingsRepo.getSettings(commission.enterpriseId);
    if (settings == null) {
      throw Exception('Settings not found for enterprise ${commission.enterpriseId}');
    }

    DiscrepancyStatus discrepancyStatus;

    if (discrepancyPercentage < 1) {
      discrepancyStatus = DiscrepancyStatus.conforme;
    } else if (discrepancyPercentage <= settings.commissionDiscrepancyMinor) {
      discrepancyStatus = DiscrepancyStatus.ecartMineur;
    } else {
      discrepancyStatus = DiscrepancyStatus.ecartSignificatif;
    }

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

    // Si conforme et auto-validation activée, valider automatiquement
    if (discrepancyStatus == DiscrepancyStatus.conforme &&
        settings.autoValidateConformeCommissions) {
      return await validateCommission(
        commissionId: commissionId,
        validatedBy: 'system_auto',
        notes: 'Auto-validée (écart < 1%)',
      );
    }

    // Si écart significatif, marquer comme disputée
    if (discrepancyStatus == DiscrepancyStatus.ecartSignificatif) {
      // TODO: Envoyer notification au superviseur
      return await markAsDisputed(
        commissionId: commissionId,
        reason:
            'Écart significatif de ${discrepancyPercentage.toStringAsFixed(1)}%',
      );
    }

    return updated;
  }

  /// Valider une commission (Superviseur/Entreprise)
  Future<Commission> validateCommission({
    required String commissionId,
    required String validatedBy,
    String? notes,
  }) async {
    final commission = await _commissionRepo.getCommission(commissionId);

    if (commission == null) {
      throw Exception('Commission not found: $commissionId');
    }

    if (commission.status != CommissionStatus.declared &&
        commission.status != CommissionStatus.disputed) {
      throw Exception(
        'Commission must be declared or disputed to validate. Current: ${commission.status}',
      );
    }

    final updated = commission.copyWith(
      status: CommissionStatus.validated,
      validatedAt: DateTime.now(),
      validatedBy: validatedBy,
      notes: notes ?? commission.notes,
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

    if (commission.status != CommissionStatus.validated) {
      throw Exception(
        'Commission must be validated to mark as paid. Current: ${commission.status}',
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

  /// Marquer une commission comme disputée
  Future<Commission> markAsDisputed({
    required String commissionId,
    required String reason,
  }) async {
    return await _commissionRepo.markAsDisputed(
      commissionId: commissionId,
      reason: reason,
    );
  }

  /// Calculer les détails de commission par tranche
  CommissionCalculationDetails _calculateCommissionDetails({
    required List<Transaction> transactions,
    required List<CommissionTier> cashInTiers,
    required List<CommissionTier> cashOutTiers,
  }) {
    final transactionsByTranche = <String, int>{};
    final commissionsByTranche = <String, int>{};

    int totalCashIn = 0;
    int totalCashOut = 0;
    int cashInCommission = 0;
    int cashOutCommission = 0;

    for (final tx in transactions) {
      final tiers = tx.type == TransactionType.cashIn ? cashInTiers : cashOutTiers;

      // Trouver la tranche correspondante
      CommissionTier? matchingTier;
      for (final tier in tiers) {
        if (tier.contains(tx.amount)) {
          matchingTier = tier;
          break;
        }
      }

      if (matchingTier != null) {
        final trancheKey = matchingTier.label;

        // Compter les transactions par tranche
        transactionsByTranche[trancheKey] =
            (transactionsByTranche[trancheKey] ?? 0) + 1;

        // Calculer la commission
        final commission = matchingTier.calculateCommission(tx.amount);

        // Ajouter aux commissions par tranche
        commissionsByTranche[trancheKey] =
            (commissionsByTranche[trancheKey] ?? 0) + commission;

        // Totaux
        if (tx.type == TransactionType.cashIn) {
          totalCashIn += tx.amount;
          cashInCommission += commission;
        } else {
          totalCashOut += tx.amount;
          cashOutCommission += commission;
        }
      }
    }

    return CommissionCalculationDetails(
      transactionsByTranche: transactionsByTranche,
      commissionsByTranche: commissionsByTranche,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      cashInCommission: cashInCommission,
      cashOutCommission: cashOutCommission,
    );
  }

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
