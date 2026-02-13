import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for PropertyExpense entities (immobilier module).
class PropertyExpenseOfflineRepository extends OfflineRepository<PropertyExpense>
    implements PropertyExpenseRepository {
  PropertyExpenseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'property_expenses';

  String get moduleType => 'immobilier';

  @override
  PropertyExpense fromMap(Map<String, dynamic> map) => PropertyExpense.fromMap(map);

  @override
  Map<String, dynamic> toMap(PropertyExpense entity) => entity.toMap();

  @override
  String getLocalId(PropertyExpense entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PropertyExpense entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(PropertyExpense entity) => enterpriseId;

  @override
  Future<void> saveToLocal(PropertyExpense entity) async {
    final localId = getLocalId(entity);
    final companion = PropertyExpensesTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      propertyId: Value(entity.propertyId),
      amount: Value(entity.amount),
      expenseDate: Value(entity.expenseDate),
      category: Value(entity.category.name),
      description: Value(entity.description),
      receipt: Value(entity.receipt),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.propertyExpensesTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(PropertyExpense entity) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.propertyExpensesTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<PropertyExpense?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.propertyExpensesTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  PropertyExpense _fromEntity(PropertyExpenseEntity entity) {
    return PropertyExpense(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      propertyId: entity.propertyId,
      amount: entity.amount,
      expenseDate: entity.expenseDate,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == entity.category,
        orElse: () => ExpenseCategory.other,
      ),
      description: entity.description,
      receipt: entity.receipt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<PropertyExpense>> getAllExpenses() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<PropertyExpense>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.propertyExpensesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map(_fromEntity).toList();
  }

  // PropertyExpenseRepository interface implementation

  @override
  Stream<List<PropertyExpense>> watchExpenses() {
    final query = driftService.db.select(driftService.db.propertyExpensesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId).and(t.deletedAt.isNull()));
    return query.watch().map((rows) => rows.map(_fromEntity).toList());
  }

  @override
  Future<PropertyExpense?> getExpenseById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId) async {
    final all = await getAllExpenses();
    return all.where((e) => e.propertyId == propertyId).toList();
  }

  @override
  Future<List<PropertyExpense>> getExpensesByCategory(ExpenseCategory category) async {
    final all = await getAllExpenses();
    return all.where((e) => e.category == category).toList();
  }

  @override
  Future<PropertyExpense> createExpense(PropertyExpense expense) async {
    try {
      final localId = expense.id.isEmpty ? LocalIdGenerator.generate() : expense.id;
      final newExpense = expense.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: expense.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newExpense);
      return newExpense;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<PropertyExpense> updateExpense(PropertyExpense expense) async {
    try {
      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
      await save(updatedExpense);
      return updatedExpense;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final expense = await getExpenseById(id);
      if (expense != null) {
        await save(expense.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
  @override
  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllExpenses();
    return all.where((e) {
      return e.expenseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Stream<List<PropertyExpense>> watchDeletedExpenses() {
    final query = driftService.db.select(driftService.db.propertyExpensesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId).and(t.deletedAt.isNotNull()));
    return query.watch().map((rows) => rows.map(_fromEntity).toList());
  }

  @override
  Future<void> restoreExpense(String id) async {
    try {
      final expense = await getExpenseById(id);
      if (expense != null) {
        await save(expense.copyWith(
          deletedAt: null,
          deletedBy: null,
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
