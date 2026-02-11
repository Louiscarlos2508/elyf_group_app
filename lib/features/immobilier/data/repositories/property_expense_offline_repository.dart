import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
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
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(PropertyExpense entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<PropertyExpense?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ) ?? await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
  }

  @override
  Future<List<PropertyExpense>> getAllExpenses() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<PropertyExpense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(entities);
  }

  // PropertyExpenseRepository interface implementation

  @override
  Stream<List<PropertyExpense>> watchExpenses() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => !e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
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
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
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
