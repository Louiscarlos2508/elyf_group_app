import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class OrangeMoneyController {
  OrangeMoneyController(this._repository);

  final TransactionRepository _repository;

  Future<OrangeMoneyState> fetchState() async {
    final transactions = await _repository.fetchTransactions();
    final statistics = await _repository.getStatistics();
    return OrangeMoneyState(
      transactions: transactions,
      statistics: statistics,
    );
  }

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
}

class OrangeMoneyState {
  const OrangeMoneyState({
    required this.transactions,
    required this.statistics,
  });

  final List<Transaction> transactions;
  final Map<String, dynamic> statistics;
}

