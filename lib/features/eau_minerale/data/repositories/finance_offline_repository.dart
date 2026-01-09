import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/finance_repository.dart';

/// Offline-first repository for Finance entities (eau_minerale module).
class FinanceOfflineRepository extends OfflineRepository<ExpenseRecord>
    implements FinanceRepository {
  FinanceOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'expenses';

  @override
  ExpenseRecord fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String? ?? map['localId'] as String,
      label: map['label'] as String,
      amountCfa: (map['amountCfa'] as num?)?.toInt() ?? 0,
      category: _parseExpenseCategory(map['category'] as String? ?? ''),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      productionId: map['productionId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap(ExpenseRecord entity) {
    return {
      'id': entity.id,
      'label': entity.label,
      'amountCfa': entity.amountCfa,
      'category': entity.category.name,
      'date': entity.date.toIso8601String(),
      'productionId': entity.productionId,
      'notes': entity.notes,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(ExpenseRecord entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(ExpenseRecord entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(ExpenseRecord entity) => enterpriseId;

  @override
  Future<void> saveToLocal(ExpenseRecord entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(ExpenseRecord entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<ExpenseRecord?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<ExpenseRecord>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing expense record: $e',
              name: 'FinanceOfflineRepository',
            );
            return null;
          }
        })
        .whereType<ExpenseRecord>()
        .toList();
  }

  // Implémentation de FinanceRepository

  @override
  Future<List<ExpenseRecord>> fetchRecentExpenses({int limit = 10}) async {
    try {
      final expenses = await getAllForEnterprise(enterpriseId);
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses.take(limit).toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching recent expenses',
        name: 'FinanceOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<String> createExpense(ExpenseRecord expense) async {
    try {
      final expenseWithId = expense.id.isEmpty
          ? expense.copyWith(id: LocalIdGenerator.generate())
          : expense;
      await save(expenseWithId);
      return expenseWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating expense',
        name: 'FinanceOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(ExpenseRecord expense) async {
    try {
      await save(expense.copyWith(updatedAt: DateTime.now()));
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating expense',
        name: 'FinanceOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  ExpenseCategory _parseExpenseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'carburant':
        return ExpenseCategory.carburant;
      case 'reparations':
        return ExpenseCategory.reparations;
      case 'achatsdivers':
      case 'achats_divers':
        return ExpenseCategory.achatsDivers;
      case 'autres':
        return ExpenseCategory.autres;
      default:
        return ExpenseCategory.autres;
    }
  }
}

