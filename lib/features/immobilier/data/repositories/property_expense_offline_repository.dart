import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/collections/expense_collection.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for PropertyExpense entities (immobilier module).
class PropertyExpenseOfflineRepository extends OfflineRepository<PropertyExpense>
    implements PropertyExpenseRepository {
  PropertyExpenseOfflineRepository({
    required super.isarService,
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
      propertyId: map['propertyId'] as String? ?? 
                  map['relatedEntityId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 
              (map['amountCfa'] as num?)?.toInt() ?? 0,
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
    final collection = ExpenseCollection.fromMap(
      map,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.expenseCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(PropertyExpense entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.expenseCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .and()
            .moduleTypeEqualTo('immobilier')
            .and()
            .relatedEntityTypeEqualTo('property')
            .deleteAll();
      } else {
        await isarService.isar.expenseCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .and()
            .moduleTypeEqualTo('immobilier')
            .and()
            .relatedEntityTypeEqualTo('property')
            .deleteAll();
      }
    });
  }

  @override
  Future<PropertyExpense?> getByLocalId(String localId) async {
    var collection = await isarService.isar.expenseCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('immobilier')
        .and()
        .relatedEntityTypeEqualTo('property')
        .findFirst();

    if (collection == null) {
      collection = await isarService.isar.expenseCollections
          .filter()
          .localIdEqualTo(localId)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('immobilier')
          .and()
          .relatedEntityTypeEqualTo('property')
          .findFirst();
    }

    if (collection == null) return null;
    return fromMap(collection.toMap());
  }

  @override
  Future<List<PropertyExpense>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.expenseCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('immobilier')
        .and()
        .relatedEntityTypeEqualTo('property')
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
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
      final collections = await isarService.isar.expenseCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('immobilier')
          .and()
          .relatedEntityTypeEqualTo('property')
          .and()
          .relatedEntityIdEqualTo(propertyId)
          .findAll();

      return collections.map((c) => fromMap(c.toMap())).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
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
      final collections = await isarService.isar.expenseCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('immobilier')
          .and()
          .relatedEntityTypeEqualTo('property')
          .and()
          .categoryEqualTo(category.name)
          .findAll();

      return collections.map((c) => fromMap(c.toMap())).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
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
      final collections = await isarService.isar.expenseCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('immobilier')
          .and()
          .relatedEntityTypeEqualTo('property')
          .and()
          .expenseDateGreaterThan(start.subtract(const Duration(days: 1)))
          .and()
          .expenseDateLessThan(end.add(const Duration(days: 1)))
          .findAll();

      return collections.map((c) => fromMap(c.toMap())).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
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

