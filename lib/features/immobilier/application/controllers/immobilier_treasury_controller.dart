import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/treasury_operation.dart';
import '../../domain/repositories/treasury_repository.dart';

class ImmobilierTreasuryController {
  ImmobilierTreasuryController(
    this._repository,
    this._enterpriseId,
    this._userId,
  );

  final TreasuryRepository _repository;
  final String _enterpriseId;
  final String _userId;

  /// Fetch operations history.
  Future<List<TreasuryOperation>> fetchOperations({int limit = 50}) async {
    return _repository.fetchOperations(limit: limit);
  }

  /// Watch operations for reactive updates.
  Stream<List<TreasuryOperation>> watchOperations({int limit = 50}) {
    return _repository.watchOperations(limit: limit);
  }

  /// Get current balances.
  Future<Map<String, int>> getBalances() async {
    return _repository.getBalances();
  }

  /// Record a new operation (generic).
  Future<String> recordOperation(TreasuryOperation operation) async {
    // Basic validation could go here
    if (operation.amount <= 0) {
      throw Exception('Amount must be positive');
    }

    final id = await _repository.createOperation(operation);
    return id;
  }

  /// Helper: Record income (e.g., Rent Payment).
  Future<String> recordIncome({
    required int amount,
    required PaymentMethod method,
    required String reason,
    String? referenceEntityId,
    String? notes,
  }) async {
    return recordOperation(TreasuryOperation(
      id: '',
      enterpriseId: _enterpriseId,
      userId: _userId,
      amount: amount,
      type: TreasuryOperationType.supply,
      toAccount: method,
      date: DateTime.now(),
      reason: reason,
      notes: notes,
      referenceEntityId: referenceEntityId,
      referenceEntityType: 'payment',
    ));
  }

  /// Helper: Record expense (e.g., Property Expense).
  Future<String> recordExpense({
    required int amount,
    required PaymentMethod method, // Source account
    required String reason,
    String? referenceEntityId,
    String? notes,
  }) async {
    return recordOperation(TreasuryOperation(
      id: '',
      enterpriseId: _enterpriseId,
      userId: _userId,
      amount: amount,
      type: TreasuryOperationType.removal,
      fromAccount: method,
      date: DateTime.now(),
      reason: reason,
      notes: notes,
      referenceEntityId: referenceEntityId,
      referenceEntityType: 'expense',
    ));
  }
}
