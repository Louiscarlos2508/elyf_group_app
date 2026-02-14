import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import 'immobilier_treasury_controller.dart';
import '../../../../shared/domain/entities/payment_method.dart';

class PropertyExpenseController {
  PropertyExpenseController(
    this._expenseRepository,
    this._auditTrailService,
    this._treasuryController,
    this._enterpriseId,
    this._userId,
  );

  final PropertyExpenseRepository _expenseRepository;
  final AuditTrailService _auditTrailService;
  final ImmobilierTreasuryController _treasuryController;
  final String _enterpriseId;
  final String _userId;

  Future<List<PropertyExpense>> fetchExpenses({bool? isDeleted = false}) async {
    return await _expenseRepository.getAllExpenses(isDeleted: isDeleted);
  }

  Stream<List<PropertyExpense>> watchExpenses({bool? isDeleted = false}) {
    return _expenseRepository.watchExpenses(isDeleted: isDeleted);
  }

  Stream<List<PropertyExpense>> watchDeletedExpenses() {
    return _expenseRepository.watchDeletedExpenses();
  }

  Future<PropertyExpense?> getExpense(String id) async {
    return await _expenseRepository.getExpenseById(id);
  }

  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId) async {
    return await _expenseRepository.getExpensesByProperty(propertyId);
  }

  Future<List<PropertyExpense>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    return await _expenseRepository.getExpensesByCategory(category);
  }

  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await _expenseRepository.getExpensesByPeriod(start, end);
  }

  Future<PropertyExpense> createExpense(PropertyExpense expense) async {
    final created = await _expenseRepository.createExpense(expense);
    await _logAction('create', created.id, metadata: created.toMap());
    
    // Record Treasury Expense
    await _treasuryController.recordExpense(
      amount: created.amount,
      method: created.paymentMethod,
      reason: '${created.category.name}: ${created.description}',
      referenceEntityId: created.id,
      notes: created.description,
    );

    return created;
  }

  Future<PropertyExpense> updateExpense(PropertyExpense expense) async {
    final updated = await _expenseRepository.updateExpense(expense);
    await _logAction('update', updated.id, metadata: updated.toMap());
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    await _expenseRepository.deleteExpense(id);
    await _logAction('delete', id);
  }

  Future<void> restoreExpense(String id) async {
    await _expenseRepository.restoreExpense(id);
    await _logAction('restore', id);
  }

  Future<void> _logAction(
    String action,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    await _auditTrailService.logAction(
      enterpriseId: _enterpriseId,
      userId: _userId,
      module: 'immobilier',
      action: action,
      entityId: entityId,
      entityType: 'expense',
      metadata: metadata,
    );
  }
}
