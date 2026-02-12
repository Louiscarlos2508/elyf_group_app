import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/liquidity_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/transaction_service.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';

import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/adapters/orange_money_permission_adapter.dart';

class OrangeMoneyController {
  OrangeMoneyController(
    this._repository,
    this._liquidityRepository,
    this._settingsRepository,
    this._auditTrailService,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final TransactionRepository _repository;
  final LiquidityRepository _liquidityRepository;
  final SettingsRepository _settingsRepository;
  final AuditTrailService _auditTrailService;
  final String userId;
  final OrangeMoneyPermissionAdapter _permissionAdapter;
  final String _activeEnterpriseId;

  Future<OrangeMoneyState> fetchState() async {
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    
    List<Transaction> transactions;
    Map<String, dynamic> statistics;

    if (accessibleIds.length > 1) {
      // Network View
      final idsList = accessibleIds.toList();
      transactions = await _repository.fetchTransactionsByEnterprises(idsList);
      
      // Calculate statistics manually for network view
      final cashInTransactions = transactions.where((t) => t.isCashIn && t.isCompleted).toList();
      final cashOutTransactions = transactions.where((t) => t.isCashOut && t.isCompleted).toList();
      
      final totalCashIn = cashInTransactions.fold<int>(0, (sum, t) => sum + t.amount);
      final totalCashOut = cashOutTransactions.fold<int>(0, (sum, t) => sum + t.amount);
      final totalCommission = transactions
          .where((t) => t.commission != null)
          .fold<int>(0, (sum, t) => sum + (t.commission ?? 0));
      
      statistics = {
        'totalTransactions': transactions.length,
        'completedTransactions': transactions.where((t) => t.isCompleted).length,
        'pendingTransactions': transactions.where((t) => t.isPending).length,
        'failedTransactions': transactions.where((t) => t.isFailed).length,
        'totalCashIn': totalCashIn,
        'totalCashOut': totalCashOut,
        'netAmount': totalCashIn - totalCashOut,
        'totalCommission': totalCommission,
        'isNetworkView': true, // Flag for UI
      };
    } else {
      // Single Enterprise View
      transactions = await _repository.fetchTransactions();
      statistics = await _repository.getStatistics();
    }
    
    final todayCheckpoint = await _liquidityRepository.getTodayCheckpoint(_activeEnterpriseId);

    return OrangeMoneyState(
      transactions: transactions, 
      statistics: statistics,
      todayCheckpoint: todayCheckpoint,
    );
  }

  /// Crée une transaction avec validation.
  ///
  /// Lance une [ArgumentError] si les données sont invalides ou si la liquidité est insuffisante.
  Future<String> createTransactionFromInput({
    required String enterpriseId,
    required TransactionType type,
    required String phoneNumber,
    required String amountStr,
    String? customerName,
    String? createdBy,
  }) async {
    // 1. Validation de base via le service
    final phoneError = TransactionService.validatePhoneNumber(phoneNumber);
    if (phoneError != null) {
      throw BusinessException(phoneError);
    }

    final amountError = TransactionService.validateAmount(amountStr);
    if (amountError != null) {
      throw BusinessException(amountError);
    }

    final amount = int.parse(amountStr.trim());

    // 2. Validation de la liquidité et seuils (PRD Compliance)
    final settings = await _settingsRepository.getSettings(enterpriseId);
    
    // PRD: Montant minimum 100 FCFA
    if (amount < 100) {
      throw BusinessException('Le montant minimum est de 100 FCFA.');
    }

    // PRD: Montant maximum selon type
    // Cash-In: 1 000 000 FCFA
    // Cash-Out: 500 000 FCFA
    // TODO: Ces limites pourraient être configurables dans settings à l'avenir
    int maxAmount = type == TransactionType.cashIn ? 1000000 : 500000;
    if (amount > maxAmount) {
       // Format amount for display
      throw BusinessException('Le montant maximum pour ${type == TransactionType.cashIn ? 'Cash-In' : 'Cash-Out'} est de $maxAmount FCFA.');
    }

    // PRD: Morning Checkpoint Rule
    final todayCheckpoint = await _liquidityRepository.getTodayCheckpoint(enterpriseId);
    if (todayCheckpoint == null) {
      throw BusinessException(
          'Veuillez effectuer le pointage du matin avant de commencer les transactions.');
    }

    if (type == TransactionType.cashIn) {
      // Cash-In: L'agent reçoit du CASH et envoie de l'argent SIM.
      // On vérifie donc le solde SIM.
      final currentSim = todayCheckpoint.simAmount ?? todayCheckpoint.morningSimAmount ?? 0;
      if (amount > currentSim) {
        throw BusinessException('Solde SIM insuffisant pour ce Cash-In. Disponible: $currentSim FCFA');
      }
    } else if (type == TransactionType.cashOut) {
      // Cash-Out: L'agent donne du CASH et reçoit de l'argent SIM.
      // On vérifie donc le solde CASH.
      final currentCash = todayCheckpoint.cashAmount ?? todayCheckpoint.morningCashAmount ?? 0;
      if (amount > currentCash) {
        throw BusinessException('Encaisse insuffisante pour ce Cash-Out. Disponible: $currentCash FCFA');
      }
    }

    // 3. Calcul de la commission (PRD Compliance)
    int? calculatedCommission;
    if (settings != null) {
      final tiers = type == TransactionType.cashIn ? settings.cashInTiers : settings.cashOutTiers;
      
      // Trouver la tranche correspondante
      for (final tier in tiers) {
        if (tier.contains(amount)) {
          calculatedCommission = tier.calculateCommission(amount);
          break;
        }
      }
    }

    final transaction = TransactionService.createTransaction(
      enterpriseId: enterpriseId,
      type: type,
      amount: amount,
      phoneNumber: phoneNumber,
      customerName: customerName,
      commission: calculatedCommission,
      createdBy: createdBy ?? userId,
    );

    final transactionId = await _repository.createTransaction(transaction);

    // 4. Log to Audit Trail
    try {
      if (createdBy != null) {
        await _auditTrailService.logTransaction(
          enterpriseId: enterpriseId,
          userId: createdBy,
          transactionId: transactionId,
          type: type.name,
          amount: amount,
        );
      }
    } catch (e) {
      // Don't fail the operation if audit logging fails
      AppLogger.error('Failed to log transaction audit', error: e);
    }

    return transactionId;
  }

  /// Crée une transaction (méthode directe pour les cas avancés).
  Future<String> createTransaction(Transaction transaction) async {
    return await _repository.createTransaction(transaction);
  }

  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    return await _repository.updateTransactionStatus(transactionId, status);
  }

  Future<void> deleteTransaction(String transactionId) async {
    return await _repository.deleteTransaction(transactionId, userId);
  }

  Future<void> restoreTransaction(String transactionId) async {
    return await _repository.restoreTransaction(transactionId);
  }

  Stream<List<Transaction>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) {
    return _repository.watchTransactions(
      startDate: startDate,
      endDate: endDate,
      type: type,
      status: status,
    );
  }

  Stream<List<Transaction>> watchTransactionsByAgent(String agentId) {
    return _repository.watchTransactionsByAgent(agentId);
  }

  Stream<List<Transaction>> watchTransactionsByPeriod(DateTime start, DateTime end) {
    return _repository.watchTransactionsByPeriod(start, end);
  }

  Stream<List<Transaction>> watchDeletedTransactions() {
    return _repository.watchDeletedTransactions();
  }

  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Recherche un client existant par numéro de téléphone.
  /// Retourne le nom du client si une transaction avec ce numéro existe, null sinon.
  Future<String?> findCustomerByPhoneNumber(String phoneNumber) async {
    final transactions = await _repository.fetchTransactions();

    try {
      final existingTransaction = transactions.firstWhere(
        (t) =>
            TransactionService.comparePhoneNumbers(t.phoneNumber, phoneNumber),
      );
      return existingTransaction.customerName;
    } catch (e) {
      return null;
    }
  }
}

class OrangeMoneyState {
  const OrangeMoneyState({
    required this.transactions,
    required this.statistics,
    this.todayCheckpoint,
  });

  final List<Transaction> transactions;
  final Map<String, dynamic> statistics;
  final LiquidityCheckpoint? todayCheckpoint;
}
