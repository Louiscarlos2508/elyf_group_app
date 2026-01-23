import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/finance_repository.dart';

/// Offline-first repository for ExpenseRecord entities.
class FinanceOfflineRepository extends OfflineRepository<ExpenseRecord>
    implements FinanceRepository {
  FinanceOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'expense_records';

  @override
  ExpenseRecord fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String? ?? map['localId'] as String,
      label: map['label'] as String,
      amountCfa: (map['amountCfa'] as num).toInt(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.autres,
      ),
      date: DateTime.parse(map['date'] as String),
      productionId: map['productionId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
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
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(ExpenseRecord entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
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
      moduleType: moduleType,
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
  Future<ExpenseRecord?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final map = safeDecodeJson(byRemote.dataJson, localId);
      if (map == null) return null;
      try {
        return fromMap(map);
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error parsing ExpenseRecord from map: ${appException.message}',
          name: 'FinanceOfflineRepository',
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final map = safeDecodeJson(byLocal.dataJson, localId);
    if (map == null) return null;
    try {
      return fromMap(map);
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing ExpenseRecord from map: $e',
        name: 'FinanceOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<List<ExpenseRecord>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    // Décoder et parser de manière sécurisée, en ignorant les données corrompues
    final expenses = <ExpenseRecord>[];
    for (final row in rows) {
      final map = safeDecodeJson(row.dataJson, row.localId);
      if (map == null) continue; // Ignorer les données corrompues
      
      try {
        expenses.add(fromMap(map));
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error parsing ExpenseRecord from map (skipping): ${appException.message}',
          name: 'FinanceOfflineRepository',
          error: e,
          stackTrace: stackTrace,
        );
        // Continuer avec les autres enregistrements
      }
    }
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedExpenses = deduplicateByRemoteId(expenses);
    
    // Trier par date décroissante
    deduplicatedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return deduplicatedExpenses;
  }

  // FinanceRepository implementation

  @override
  Future<List<ExpenseRecord>> fetchRecentExpenses({int limit = 10}) async {
    try {
      final expenses = await getAllForEnterprise(enterpriseId);
      return expenses.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching recent expenses: ${appException.message}',
        name: 'FinanceOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createExpense(ExpenseRecord expense) async {
    try {
      final localId = getLocalId(expense);
      final expenseWithLocalId = expense.copyWith(
        id: localId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(expenseWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating expense',
        name: 'FinanceOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateExpense(ExpenseRecord expense) async {
    try {
      final updated = expense.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating expense: ${expense.id} - ${appException.message}',
        name: 'FinanceOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
