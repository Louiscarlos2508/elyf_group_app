import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for PropertyExpense entities (immobilier module).
class PropertyExpenseOfflineRepository
    extends OfflineRepository<PropertyExpense>
    implements PropertyExpenseRepository {
  PropertyExpenseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'expenses';

  @override
  PropertyExpense fromMap(Map<String, dynamic> map) {
    return PropertyExpense(
      id: map['id'] as String? ?? map['localId'] as String,
      propertyId:
          map['propertyId'] as String? ??
          map['relatedEntityId'] as String? ??
          '',
      amount:
          (map['amount'] as num?)?.toInt() ??
          (map['amountCfa'] as num?)?.toInt() ??
          0,
      expenseDate: map['expenseDate'] != null
          ? DateTime.parse(map['expenseDate'] as String)
          : (map['date'] != null
                ? DateTime.parse(map['date'] as String)
                : DateTime.now()),
      category: _parseCategory(map['category'] as String?),
      description: map['description'] as String? ?? '',
      property: map['property'] as String?,
      receipt: map['receipt'] as String? ?? map['reference'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(PropertyExpense entity) {
    return {
      'id': entity.id,
      'propertyId': entity.propertyId,
      'relatedEntityId': entity.propertyId,
      'relatedEntityType': 'property',
      'amount': entity.amount.toDouble(),
      'amountCfa': entity.amount.toDouble(),
      'expenseDate': entity.expenseDate.toIso8601String(),
      'date': entity.expenseDate.toIso8601String(),
      'category': entity.category.name,
      'description': entity.description,
      'property': entity.property,
      'receipt': entity.receipt,
      'reference': entity.receipt,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(PropertyExpense entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PropertyExpense entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(PropertyExpense entity) => enterpriseId;

  @override
  Future<void> saveToLocal(PropertyExpense entity) async {
    final map = toMap(entity);
    final localId = getLocalId(entity);
    map['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(PropertyExpense entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'immobilier',
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
  }

  @override
  Future<PropertyExpense?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<PropertyExpense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    final expenses =
        rows
            .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  // PropertyExpenseRepository interface implementation

  @override
  Future<List<PropertyExpense>> getAllExpenses() async {
    try {
      developer.log(
        'Fetching all property expenses for enterprise: $enterpriseId',
        name: 'PropertyExpenseOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching all expenses',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PropertyExpense?> getExpenseById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting expense: $id',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      final filtered = all.where((e) => e.propertyId == propertyId).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return filtered;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching expenses by property: $propertyId',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<PropertyExpense>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      final filtered = all.where((e) => e.category == category).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return filtered;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching expenses by category: ${category.name}',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      final filtered = all.where((e) {
        return (e.expenseDate.isAfter(start) ||
                e.expenseDate.isAtSameMomentAs(start)) &&
            (e.expenseDate.isBefore(end) ||
                e.expenseDate.isAtSameMomentAs(end));
      }).toList()..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return filtered;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching expenses by period',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PropertyExpense> createExpense(PropertyExpense expense) async {
    try {
      final localId = getLocalId(expense);
      final expenseWithLocalId = PropertyExpense(
        id: localId,
        propertyId: expense.propertyId,
        amount: expense.amount,
        expenseDate: expense.expenseDate,
        category: expense.category,
        description: expense.description,
        property: expense.property,
        receipt: expense.receipt,
        createdAt: expense.createdAt ?? DateTime.now(),
        updatedAt: expense.updatedAt,
      );
      await save(expenseWithLocalId);
      return expenseWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating expense',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PropertyExpense> updateExpense(PropertyExpense expense) async {
    try {
      await save(expense);
      return expense;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating expense: ${expense.id}',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting expense: $id',
        name: 'PropertyExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  ExpenseCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return ExpenseCategory.other;
    switch (categoryStr.toLowerCase()) {
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'repair':
      case 'réparation':
        return ExpenseCategory.repair;
      case 'utilities':
      case 'services publics':
        return ExpenseCategory.utilities;
      case 'insurance':
      case 'assurance':
        return ExpenseCategory.insurance;
      case 'taxes':
      case 'impôts':
        return ExpenseCategory.taxes;
      case 'cleaning':
      case 'nettoyage':
        return ExpenseCategory.cleaning;
      default:
        return ExpenseCategory.other;
    }
  }
}
