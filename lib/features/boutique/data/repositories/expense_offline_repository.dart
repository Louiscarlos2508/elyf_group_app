import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/expense_collection.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for Expense entities.
class ExpenseOfflineRepository extends OfflineRepository<Expense>
    implements ExpenseRepository {
  ExpenseOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'expenses';

  @override
  Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String? ?? map['localId'] as String,
      label: map['label'] as String? ?? map['description'] as String? ?? '',
      amountCfa: (map['amountCfa'] as num?)?.toInt() ??
          (map['amount'] as num?)?.toInt() ??
          0,
      category: _parseCategory(map['category'] as String?),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['expenseDate'] != null
              ? DateTime.parse(map['expenseDate'] as String)
              : DateTime.now()),
    );
  }

  @override
  Map<String, dynamic> toMap(Expense entity) {
    return {
      'id': entity.id,
      'label': entity.label,
      'description': entity.label,
      'amountCfa': entity.amountCfa.toDouble(),
      'amount': entity.amountCfa.toDouble(),
      'category': entity.category.name,
      'date': entity.date.toIso8601String(),
      'expenseDate': entity.date.toIso8601String(),
    };
  }

  ExpenseCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return ExpenseCategory.other;
    switch (categoryStr.toLowerCase()) {
      case 'stock':
      case 'achats':
        return ExpenseCategory.stock;
      case 'rent':
      case 'loyer':
        return ExpenseCategory.rent;
      case 'utilities':
      case 'services publics':
        return ExpenseCategory.utilities;
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'marketing':
        return ExpenseCategory.marketing;
      default:
        return ExpenseCategory.other;
    }
  }

  @override
  String getLocalId(Expense entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Expense entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Expense entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Expense entity) async {
    final collection = ExpenseCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.expenseCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Expense entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.expenseCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        await isarService.isar.expenseCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Expense?> getByLocalId(String localId) async {
    var collection = await isarService.isar.expenseCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection == null) {
      collection = await isarService.isar.expenseCollections
          .filter()
          .remoteIdEqualTo(localId)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();
    }

    if (collection == null) return null;
    return fromMap(collection.toMap());
  }

  @override
  Future<List<Expense>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.expenseCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo(moduleType)
        .sortByExpenseDateDesc()
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // ExpenseRepository interface implementation

  @override
  Future<List<Expense>> fetchExpenses({int limit = 50}) async {
    developer.log(
      'Fetching expenses for enterprise: $enterpriseId',
      name: 'ExpenseOfflineRepository',
    );
    final allExpenses = await getAllForEnterprise(enterpriseId);
    return allExpenses.take(limit).toList();
  }

  @override
  Future<Expense?> getExpense(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<String> createExpense(Expense expense) async {
    final localId = getLocalId(expense);
    // Create new expense with local ID
    final expenseWithLocalId = Expense(
      id: localId,
      label: expense.label,
      amountCfa: expense.amountCfa,
      category: expense.category,
      date: expense.date,
    );
    await save(expenseWithLocalId);
    return localId;
  }

  @override
  Future<void> deleteExpense(String id) async {
    final expense = await getExpense(id);
    if (expense != null) {
      await delete(expense);
    }
  }
}

