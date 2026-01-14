import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/transaction_service.dart';

class OrangeMoneyController {
  OrangeMoneyController(this._repository);

  final TransactionRepository _repository;

  Future<OrangeMoneyState> fetchState() async {
    final transactions = await _repository.fetchTransactions();
    final statistics = await _repository.getStatistics();
    return OrangeMoneyState(transactions: transactions, statistics: statistics);
  }

  /// Crée une transaction avec validation.
  ///
  /// Lance une [ArgumentError] si les données sont invalides.
  Future<String> createTransactionFromInput({
    required TransactionType type,
    required String phoneNumber,
    required String amountStr,
    String? customerName,
    String? createdBy,
  }) async {
    // Validation via le service
    final phoneError = TransactionService.validatePhoneNumber(phoneNumber);
    if (phoneError != null) {
      throw ArgumentError(phoneError);
    }

    final amountError = TransactionService.validateAmount(amountStr);
    if (amountError != null) {
      throw ArgumentError(amountError);
    }

    final amount = int.parse(amountStr.trim());

    // Création de la transaction via le service
    final transaction = TransactionService.createTransaction(
      type: type,
      amount: amount,
      phoneNumber: phoneNumber,
      customerName: customerName,
      createdBy: createdBy,
    );

    return await _repository.createTransaction(transaction);
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
