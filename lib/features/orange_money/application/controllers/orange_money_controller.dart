import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/liquidity_repository.dart';
import '../../domain/services/transaction_service.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';

class OrangeMoneyController {
  OrangeMoneyController(
    this._repository,
    this._liquidityRepository,
    this._auditTrailService,
    this.userId,
  );

  final TransactionRepository _repository;
  final LiquidityRepository _liquidityRepository;
  final AuditTrailService _auditTrailService;
  final String userId;

  Future<OrangeMoneyState> fetchState() async {
    final transactions = await _repository.fetchTransactions();
    final statistics = await _repository.getStatistics();
    return OrangeMoneyState(transactions: transactions, statistics: statistics);
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

    // 2. Validation de la liquidité (Epic 3 improvement)
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

    final transaction = TransactionService.createTransaction(
      enterpriseId: enterpriseId,
      type: type,
      amount: amount,
      phoneNumber: phoneNumber,
      customerName: customerName,
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
  });

  final List<Transaction> transactions;
  final Map<String, dynamic> statistics;
}
