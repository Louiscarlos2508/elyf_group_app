import 'dart:async';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Mock implementation of TransactionRepository for development.
class MockTransactionRepository implements TransactionRepository {
  final _transactions = <String, Transaction>{};

  MockTransactionRepository() {
    // Initialize with sample data
    final now = DateTime.now();
    _transactions['txn-1'] = Transaction(
      id: 'txn-1',
      type: TransactionType.cashIn,
      amount: 50000,
      phoneNumber: '+22670123456',
      date: now.subtract(const Duration(hours: 2)),
      status: TransactionStatus.completed,
      customerName: 'Jean Dupont',
      commission: 500,
      fees: 0,
      reference: 'OM123456789',
    );
    _transactions['txn-2'] = Transaction(
      id: 'txn-2',
      type: TransactionType.cashOut,
      amount: 25000,
      phoneNumber: '+22670234567',
      date: now.subtract(const Duration(hours: 1)),
      status: TransactionStatus.completed,
      customerName: 'Marie Konaté',
      commission: 250,
      fees: 0,
      reference: 'OM987654321',
    );
    _transactions['txn-3'] = Transaction(
      id: 'txn-3',
      type: TransactionType.cashIn,
      amount: 100000,
      phoneNumber: '+22670345678',
      date: now.subtract(const Duration(minutes: 30)),
      status: TransactionStatus.pending,
      customerName: 'Amadou Traoré',
    );
  }

  @override
  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var transactions = _transactions.values.toList();

    if (startDate != null) {
      transactions = transactions
          .where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      transactions = transactions
          .where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate))
          .toList();
    }

    if (type != null) {
      transactions = transactions.where((t) => t.type == type).toList();
    }

    if (status != null) {
      transactions = transactions.where((t) => t.status == status).toList();
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _transactions[transactionId];
  }

  @override
  Future<String> createTransaction(Transaction transaction) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _transactions[transaction.id] = transaction;
    return transaction.id;
  }

  @override
  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final transaction = _transactions[transactionId];
    if (transaction != null) {
      _transactions[transactionId] = Transaction(
        id: transaction.id,
        type: transaction.type,
        amount: transaction.amount,
        phoneNumber: transaction.phoneNumber,
        date: transaction.date,
        status: status,
        customerName: transaction.customerName,
        commission: transaction.commission,
        fees: transaction.fees,
        reference: transaction.reference,
        notes: transaction.notes,
        createdBy: transaction.createdBy,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final transactions = await fetchTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    final cashInTotal = transactions
        .where((t) => t.type == TransactionType.cashIn && t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.amount);

    final cashOutTotal = transactions
        .where((t) => t.type == TransactionType.cashOut && t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.amount);

    final totalCommission = transactions
        .where((t) => t.isCompleted && t.commission != null)
        .fold<int>(0, (sum, t) => sum + (t.commission ?? 0));

    return {
      'totalTransactions': transactions.length,
      'cashInTotal': cashInTotal,
      'cashOutTotal': cashOutTotal,
      'totalCommission': totalCommission,
      'pendingTransactions': transactions.where((t) => t.isPending).length,
    };
  }
}

