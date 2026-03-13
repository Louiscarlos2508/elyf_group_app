import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
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
  String get collectionName => CollectionNames.propertyExpenses;

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
  Future<void> saveToLocal(PropertyExpense entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity);
    map['localId'] = localId;

    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(PropertyExpense entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedExpense = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedExpense, userId: userId);
  }

  @override
  Future<PropertyExpense?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final expense = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return expense.isDeleted ? null : expense;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<PropertyExpense>> getAllExpenses({bool? isDeleted = false}) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((e) {
      if (isDeleted == null) return true;
      return e.isDeleted == isDeleted;
    }).toList();
  }

  @override
  Future<List<PropertyExpense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // PropertyExpenseRepository interface implementation

  @override
  Stream<List<PropertyExpense>> watchExpenses({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((e) {
        if (isDeleted == null) return true;
        return e.isDeleted == isDeleted;
      }).toList();
    });
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
        await delete(expense);
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
    return watchExpenses(isDeleted: true);
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
