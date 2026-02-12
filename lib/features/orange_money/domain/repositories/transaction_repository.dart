import '../entities/transaction.dart';

/// Repository for managing Mobile Money transactions.
abstract class TransactionRepository {
  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  });

  Future<Transaction?> getTransaction(String transactionId);

  Future<String> createTransaction(Transaction transaction);

  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  );

  Future<void> deleteTransaction(String transactionId, String userId);

  Future<void> restoreTransaction(String transactionId);

  Stream<List<Transaction>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  });

  Stream<List<Transaction>> watchTransactionsByAgent(String agentId);

  Stream<List<Transaction>> watchTransactionsByPeriod(
    DateTime start,
    DateTime end,
  );
  Stream<List<Transaction>> watchDeletedTransactions();

  /// Fetch transactions for multiple enterprises (Hierarchy support)
  Future<List<Transaction>> fetchTransactionsByEnterprises(
    List<String> enterpriseIds, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  });

  /// Watch transactions for multiple enterprises (Hierarchy support)
  Stream<List<Transaction>> watchTransactionsByEnterprises(
    List<String> enterpriseIds, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  });

  /// Get statistics for a period (Single enterprise)
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}
