import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
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
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'expenses';

  @override
  Expense fromMap(Map<String, dynamic> map) {
    return Expense.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Expense entity) {
    return entity.toMap();
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
    AppLogger.debug(
      'Fetching expenses for enterprise: $enterpriseId',
      name: 'ExpenseOfflineRepository',
    );
    final allExpenses = await getAllForEnterprise(enterpriseId);
    return allExpenses.take(limit).toList();
  }

  @override
  Future<int> getCountForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    final expenses = await getExpensesInPeriod(start, end);
    return expenses.length;
  }

  @override
  Future<Expense?> getExpense(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<String> createExpense(Expense expense) async {
    final localId = getLocalId(expense);
    // Create new expense with local ID
    final newExpense = expense.copyWith(
      id: localId,
      enterpriseId: enterpriseId,
      updatedAt: DateTime.now(),
    );
    await save(newExpense);
      
    // Audit Log
    await _logAudit(
      action: 'create_expense',
      entityId: localId,
      metadata: {'label': expense.label, 'amountCfa': expense.amountCfa},
    );

    return localId;
  }

  @override
  Future<void> deleteExpense(String id, {String? deletedBy}) async {
    final expense = await getExpense(id);
    if (expense != null && !expense.isDeleted) {
      // Soft delete: marquer comme supprimé au lieu de supprimer physiquement
      final deletedExpense = expense.copyWith(
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
        updatedAt: DateTime.now(),
      );
      await save(deletedExpense);

      // Audit Log
      await _logAudit(
        action: 'delete_expense',
        entityId: id,
        metadata: {'deletedBy': deletedBy},
      );
    }
  }

  @override
  Future<void> restoreExpense(String id) async {
    final expense = await getExpense(id);
    if (expense != null && expense.isDeleted) {
      // Restaurer: enlever deletedAt et deletedBy
      final restoredExpense = expense.copyWith(
        deletedAt: null,
        deletedBy: null,
        updatedAt: DateTime.now(),
      );
      await save(restoredExpense);

      // Audit Log
      await _logAudit(
        action: 'restore_expense',
        entityId: id,
      );
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

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await auditTrailRepository.log(
        AuditRecord(
          id: '', // Generated by repository
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'expense',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log expense audit: $action', error: e);
    }
  }
}
