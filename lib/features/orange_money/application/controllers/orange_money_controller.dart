import '../../domain/entities/customer.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/liquidity_repository.dart';

import '../../domain/repositories/commission_repository.dart';
import '../../domain/services/transaction_service.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';

import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/adapters/orange_money_permission_adapter.dart';
import '../../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/utils/id_generator.dart';

class OrangeMoneyController {
  OrangeMoneyController(
    this._repository,
    this._liquidityRepository,
    this._commissionRepository,
    this._treasuryRepository,
    this._auditTrailService,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final TransactionRepository _repository;
  final LiquidityRepository _liquidityRepository;

  final CommissionRepository _commissionRepository;
  final OrangeMoneyTreasuryRepository _treasuryRepository;
  final AuditTrailService _auditTrailService;
  final String userId;
  final OrangeMoneyPermissionAdapter _permissionAdapter;
  final String _activeEnterpriseId;

  Future<OrangeMoneyState> fetchState() async {
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    final idsList = accessibleIds.toList();
    
    final transactions = await _repository.fetchTransactionsByEnterprises(idsList);
    final treasuryOps = await _treasuryRepository.getOperations(
      _activeEnterpriseId,
      enterpriseIds: idsList,
    );

    final statistics = _aggregateStatistics(
      transactions: transactions,
      treasuryOps: treasuryOps,
      isNetworkView: idsList.length > 1,
    );
    
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
    String? town,
    String? idType,
    String? idNumber,
    DateTime? idIssueDate,
    String? reference,
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
    
    // PRD: Montant minimum 100 FCFA
    if (amount < 100) {
      throw const BusinessException('Le montant minimum est de 100 FCFA.');
    }

    // PRD: Montant maximum selon type
    // Cash-In: 1 000 000 FCFA
    // Cash-Out: 500 000 FCFA
    // TODO: Ces limites pourraient être configurables dans settings à l'avenir
    final int maxAmount = type == TransactionType.cashIn ? 1000000 : 500000;
    if (amount > maxAmount) {
       // Format amount for display
      throw BusinessException('Le montant maximum pour ${type == TransactionType.cashIn ? 'Cash-In' : 'Cash-Out'} est de $maxAmount FCFA.');
    }

    // PRD: Morning Checkpoint Rule
    final todayCheckpoint = await _liquidityRepository.getTodayCheckpoint(enterpriseId);
    
    if (todayCheckpoint != null) {
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
    }

    // 3. Automated Treasury Integration (PRD: Transactions must impact balance immediately)
    final transaction = TransactionService.createTransaction(
      enterpriseId: enterpriseId,
      type: type,
      amount: amount,
      phoneNumber: phoneNumber,
      customerName: customerName,
      idType: idType,
      idNumber: idNumber,
      idIssueDate: idIssueDate,
      town: town,
      createdBy: createdBy ?? userId,
    ).copyWith(reference: reference);


    final transactionId = await _repository.createTransaction(transaction);

    // 4. Automated Treasury Integration (PRD: Transactions must impact balance immediately)
    try {
      if (type == TransactionType.cashIn) {
        // Dépôt: SIM -> Cash
        await _treasuryRepository.saveOperation(TreasuryOperation(
          id: IdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: createdBy ?? userId,
          amount: amount,
          type: TreasuryOperationType.transfer,
          fromAccount: PaymentMethod.mobileMoney,
          toAccount: PaymentMethod.cash,
          date: DateTime.now(),
          reason: 'Dépôt Orange Money - $phoneNumber',
          referenceEntityId: transactionId,
          referenceEntityType: 'transaction',
        ));
      } else if (type == TransactionType.cashOut) {
        // Retrait: Cash -> SIM
        await _treasuryRepository.saveOperation(TreasuryOperation(
          id: IdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: createdBy ?? userId,
          amount: amount,
          type: TreasuryOperationType.transfer,
          fromAccount: PaymentMethod.cash,
          toAccount: PaymentMethod.mobileMoney,
          date: DateTime.now(),
          reason: 'Retrait Orange Money - $phoneNumber',
          referenceEntityId: transactionId,
          referenceEntityType: 'transaction',
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to create automated treasury operation', error: e);
    }

    // 5. Log to Audit Trail
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
    return _repository.createTransaction(transaction);
  }

  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    return _repository.updateTransactionStatus(transactionId, status);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _repository.deleteTransaction(transactionId, userId);
    // Also delete linked treasury operations
    await _treasuryRepository.deleteOperationsByReference(transactionId, 'transaction');
  }

  Future<void> restoreTransaction(String transactionId) async {
    return _repository.restoreTransaction(transactionId);
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
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    final idsList = accessibleIds.toList();

    final transactions = await _repository.fetchTransactionsByEnterprises(
      idsList,
      startDate: startDate,
      endDate: endDate,
    );

    final treasuryOps = await _treasuryRepository.getOperations(
      _activeEnterpriseId,
      enterpriseIds: idsList,
      from: startDate,
      to: endDate,
    );

    final stats = _aggregateStatistics(
      transactions: transactions,
      treasuryOps: treasuryOps,
      isNetworkView: idsList.length > 1,
      startDate: startDate,
      endDate: endDate,
    );

    if (startDate == null || endDate == null) return stats;

    try {
      int totalDeclaredCommission = 0;
      bool anyMonthDeclared = false;

      // Check each month completely covered by the range
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      while (currentMonth.isBefore(endDate)) {
        final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
        
        // If this month is fully covered by the selection
        if (!currentMonth.isBefore(startDate) && !endOfMonth.isAfter(endDate)) {
          final period = "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}";
          
          final commissions = await _commissionRepository.fetchCommissions(
            enterpriseId: _activeEnterpriseId,
            period: period,
          );

          if (commissions.isNotEmpty && commissions.first.declaredAmount != null) {
            totalDeclaredCommission += commissions.first.declaredAmount!;
            anyMonthDeclared = true;
          }
        }
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }

      stats['totalDeclaredCommission'] = totalDeclaredCommission;
      stats['isCommissionDeclared'] = anyMonthDeclared;
      if (anyMonthDeclared) {
        stats['totalCommission'] = totalDeclaredCommission;
      }
    } catch (e) {
      AppLogger.error('Failed to aggregate declared commissions for statistics', error: e);
    }

    return stats;
  }

  Map<String, dynamic> _aggregateStatistics({
    required List<Transaction> transactions,
    required List<TreasuryOperation> treasuryOps,
    bool isNetworkView = false,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final cashInTransactions = transactions.where((t) => t.isCashIn && t.isCompleted).toList();
    final cashOutTransactions = transactions.where((t) => t.isCashOut && t.isCompleted).toList();

    final int totalCashIn = cashInTransactions.fold<int>(0, (sum, t) => sum + t.amount);
    final int totalCashOut = cashOutTransactions.fold<int>(0, (sum, t) => sum + t.amount);
    
    int internalIn = 0;
    int internalOut = 0;
    int internalInCount = 0;
    int internalOutCount = 0;

    // Process Treasury Operations (Internal movements, agent recharges, etc.)
    for (final op in treasuryOps) {
      if (op.type == TreasuryOperationType.supply) {
        internalIn += op.amount;
        internalInCount++;
      } else if (op.type == TreasuryOperationType.removal) {
        internalOut += op.amount;
        internalOutCount++;
      } else if (op.type == TreasuryOperationType.transfer && op.referenceEntityType == 'agent_account') {
        // Only count agent transfers that impact cash flow in/out
        if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
          internalIn += op.amount;
          internalInCount++;
        } else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
          internalOut += op.amount;
          internalOutCount++;
        }
      }
    }

    final Map<String, Map<String, dynamic>> dailyMap = {};
    
    // Add transactions to daily history
    for (final t in transactions) {
      if (!t.isCompleted) continue;
      final dateKey = "${t.date.year}-${t.date.month}-${t.date.day}";
      final entry = dailyMap.putIfAbsent(dateKey, () => {
        'date': DateTime(t.date.year, t.date.month, t.date.day),
        'cashIn': 0,
        'cashOut': 0,
        'count': 0,
      });
      entry['count'] = (entry['count'] as int) + 1;
      if (t.isCashIn) entry['cashIn'] = (entry['cashIn'] as int) + t.amount;
      if (t.isCashOut) entry['cashOut'] = (entry['cashOut'] as int) + t.amount;
    }

    // Add treasury operations to daily history
    for (final op in treasuryOps) {
      final dateKey = "${op.date.year}-${op.date.month}-${op.date.day}";
      final entry = dailyMap.putIfAbsent(dateKey, () => {
        'date': DateTime(op.date.year, op.date.month, op.date.day),
        'cashIn': 0,
        'cashOut': 0,
        'count': 0,
      });
      
      if (op.type == TreasuryOperationType.supply) {
        entry['cashIn'] = (entry['cashIn'] as int) + op.amount;
        entry['count'] = (entry['count'] as int) + 1;
      } else if (op.type == TreasuryOperationType.removal) {
        entry['cashOut'] = (entry['cashOut'] as int) + op.amount;
        entry['count'] = (entry['count'] as int) + 1;
      } else if (op.type == TreasuryOperationType.transfer && op.referenceEntityType == 'agent_account') {
         if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
          entry['cashIn'] = (entry['cashIn'] as int) + op.amount;
          entry['count'] = (entry['count'] as int) + 1;
        } else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
          entry['cashOut'] = (entry['cashOut'] as int) + op.amount;
          entry['count'] = (entry['count'] as int) + 1;
        }
      }
    }

    final dailyHistory = dailyMap.values.toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return {
      'totalTransactions': transactions.length + treasuryOps.length,
      'completedTransactions': transactions.where((t) => t.isCompleted).length + treasuryOps.length,
      'totalCashIn': totalCashIn + internalIn,
      'totalCashOut': totalCashOut + internalOut,
      // Keys expected by DashboardScreen
      'cashInTotal': totalCashIn + internalIn,
      'cashOutTotal': totalCashOut + internalOut,
      'deposits': totalCashIn + internalIn,
      'withdrawals': totalCashOut + internalOut,
      'netAmount': (totalCashIn + internalIn) - (totalCashOut + internalOut),
      'totalCommission': 0, // Will be updated by getStatistics from declared commissions
      'totalFees': transactions
          .where((t) => t.isCompleted && t.fees != null)
          .fold<int>(0, (sum, t) => sum + (t.fees ?? 0)),
      'depositsCount': cashInTransactions.length + internalInCount,
      'withdrawalsCount': cashOutTransactions.length + internalOutCount,
      'dailyHistory': dailyHistory,
      'isNetworkView': isNetworkView,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  /// Recherche un client existant par numéro de téléphone.
  /// Retourne le client si une transaction avec ce numéro existe, null sinon.
  Future<Customer?> findCustomerByPhoneNumber(String phoneNumber) async {
    final transactions = await _repository.fetchTransactions();

    try {
      final existingTransaction = transactions.firstWhere(
        (t) =>
            TransactionService.comparePhoneNumbers(t.phoneNumber, phoneNumber),
      );
      
      // On retourne un objet Customer minimal basé sur la transaction
      // ou on pourrait chercher dans un repository de clients s'il existait.
      // Pour l'instant, on reconstruit à partir de la transaction.
      if (existingTransaction.customerName == null) return null;
      
      return Customer(
        id: '', // Non utilisé pour l'affichage
        enterpriseId: existingTransaction.enterpriseId,
        phoneNumber: existingTransaction.phoneNumber,
        name: existingTransaction.customerName!,
        idType: existingTransaction.idType,
        idNumber: existingTransaction.idNumber,
        idIssueDate: existingTransaction.idIssueDate,
        town: existingTransaction.town,
      );
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
