import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for Expense entities.
class ExpenseOfflineRepository extends OfflineRepository<Expense>
    implements ExpenseRepository {
  ExpenseOfflineRepository({
    required super.driftService,
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
      amountCfa:
          (map['amountCfa'] as num?)?.toInt() ??
          (map['amount'] as num?)?.toInt() ??
          0,
      category: _parseCategory(map['category'] as String?),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['expenseDate'] != null
                ? DateTime.parse(map['expenseDate'] as String)
                : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      receiptPath: map['receiptPath'] as String? ?? map['receipt'] as String?,
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
      'deletedAt': entity.deletedAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
      'receiptPath': entity.receiptPath,
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
  Future<void> deleteFromLocal(Expense entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Expense?> getByLocalId(String localId) async {
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal != null) {
      return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    }

    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote == null) return null;
    return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Expense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final expenses = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedExpenses = deduplicateByRemoteId(expenses);
    
    // Filtrer les dépenses supprimées (soft delete)
    final filteredExpenses = deduplicatedExpenses
        .where((expense) => !expense.isDeleted)
        .toList();
    
    // Trier par date décroissante
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
    return filteredExpenses;
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
    final newExpense = Expense(
      id: localId,
      label: expense.label,
      amountCfa: expense.amountCfa,
      category: expense.category,
      date: expense.date,
      notes: expense.notes,
      receiptPath: expense.receiptPath,
      deletedAt: expense.deletedAt,
      deletedBy: expense.deletedBy,
      updatedAt: DateTime.now(),
    );
    await save(newExpense);
    return localId;
  }

  @override
  Future<void> deleteExpense(String id, {String? deletedBy}) async {
    final expense = await getExpense(id);
    if (expense != null && !expense.isDeleted) {
      // Soft delete: marquer comme supprimé au lieu de supprimer physiquement
      final deletedExpense = Expense(
        id: expense.id,
        label: expense.label,
        amountCfa: expense.amountCfa,
        category: expense.category,
        date: expense.date,
        notes: expense.notes,
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
        updatedAt: DateTime.now(),
      );
      await save(deletedExpense);
    }
  }

  @override
  Future<void> restoreExpense(String id) async {
    final expense = await getExpense(id);
    if (expense != null && expense.isDeleted) {
      // Restaurer: enlever deletedAt et deletedBy
      final restoredExpense = Expense(
        id: expense.id,
        label: expense.label,
        amountCfa: expense.amountCfa,
        category: expense.category,
        date: expense.date,
        notes: expense.notes,
        deletedAt: null,
        deletedBy: null,
        updatedAt: DateTime.now(),
      );
      await save(restoredExpense);
    }
  }

  @override
  Future<List<Expense>> getDeletedExpenses() async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    // Récupérer uniquement les dépenses supprimées
    final expenses = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((expense) => expense.isDeleted)
        .toList();
    expenses.sort(
      (a, b) => (b.deletedAt ?? DateTime(1970)).compareTo(
        a.deletedAt ?? DateTime(1970),
      ),
    );
    return expenses;
  }

  @override
  Future<List<Expense>> getExpensesInPeriod(DateTime start, DateTime end) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      final expenses = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();

      final deduplicatedExpenses = deduplicateByRemoteId(expenses);

      // Filtrer par date et statut (non supprimé)
      return deduplicatedExpenses.where((expense) {
        if (expense.isDeleted) return false;
        return expense.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            expense.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching expenses in period: ${appException.message}',
        name: 'ExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Expense>> watchExpenses({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final expenses = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();
      final deduplicatedExpenses = deduplicateByRemoteId(expenses);
      final filteredExpenses = deduplicatedExpenses
          .where((expense) => !expense.isDeleted)
          .toList();
      filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
      // On ne prend plus le limit ici pour s'assurer que les calculs de totaux quotidiens soient corrects
      // même si on a plus de 50 dépenses.
      return filteredExpenses;
    });
  }

  @override
  Stream<List<Expense>> watchDeletedExpenses() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final expenses = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((expense) => expense.isDeleted)
          .toList();
      expenses.sort(
        (a, b) => (b.deletedAt ?? DateTime(1970)).compareTo(
          a.deletedAt ?? DateTime(1970),
        ),
      );
      return expenses;
    });
  }
}
