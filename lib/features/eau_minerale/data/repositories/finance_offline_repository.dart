import 'dart:convert';

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
  ExpenseRecord fromMap(Map<String, dynamic> map) =>
      ExpenseRecord.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(ExpenseRecord entity) => entity.toMap();

  @override
  String getLocalId(ExpenseRecord entity) {
    if (entity.id.isNotEmpty) return entity.id;
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
    // Soft-delete
    final deletedExpense = entity.copyWith(
      deletedAt: DateTime.now(),
    );
    await saveToLocal(deletedExpense);
    
    AppLogger.info(
      'Soft-deleted expense record: ${entity.id}',
      name: 'FinanceOfflineRepository',
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
      final expense = fromMap(map);
      return expense.isDeleted ? null : expense;
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
    final expense = fromMap(map);
    return expense.isDeleted ? null : expense;
  }

  @override
  Future<List<ExpenseRecord>> getAllForEnterprise(String enterpriseId) async {
    AppLogger.debug(
      'Fetching all expenses for enterprise: $enterpriseId (module: $moduleType)',
      name: 'FinanceOfflineRepository',
    );

    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    AppLogger.debug(
      'Found ${rows.length} records for $collectionName / $enterpriseId',
      name: 'FinanceOfflineRepository',
    );
    
    // Décoder et parser de manière sécurisée, en ignorant les données corrompues
    final expenses = <ExpenseRecord>[];
    for (final row in rows) {
      final map = safeDecodeJson(row.dataJson, row.localId);
      if (map == null) continue; // Ignorer les données corrompues
      
      try {
        final expense = fromMap(map);
        if (!expense.isDeleted) {
          expenses.add(expense);
        }
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
    
    AppLogger.debug(
      'Successfully decoded ${expenses.length} expenses',
      name: 'FinanceOfflineRepository',
    );

    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedExpenses = deduplicateByRemoteId(expenses);

    AppLogger.debug(
      'Final list has ${deduplicatedExpenses.length} expenses after deduplication',
      name: 'FinanceOfflineRepository',
    );
    
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
  Future<List<ExpenseRecord>> fetchExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var all = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        all = all
            .where(
              (e) =>
                  e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        all = all
            .where(
              (e) => e.date.isBefore(endDate) || e.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      return all;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching expenses for period: ${appException.message}',
        name: 'FinanceOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<ExpenseRecord>> watchExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          var expenses = rows
              .map((row) => safeDecodeJson(row.dataJson, row.localId))
              .where((map) => map != null)
              .map((map) {
                try {
                  return fromMap(map!);
                } catch (e) {
                  return null;
                }
              })
              .whereType<ExpenseRecord>()
              .toList();

          if (startDate != null) {
            expenses = expenses
                .where(
                  (e) =>
                      e.date.isAfter(startDate) ||
                      e.date.isAtSameMomentAs(startDate),
                )
                .toList();
          }

          if (endDate != null) {
            expenses = expenses
                .where(
                  (e) =>
                      e.date.isBefore(endDate) ||
                      e.date.isAtSameMomentAs(endDate),
                )
                .toList();
          }

          return expenses.where((e) => !e.isDeleted).toList();
        });
  }

  @override
  Future<String> createExpense(ExpenseRecord expense) async {
    try {
      final localId = getLocalId(expense);
      final expenseToSave = expense.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(expenseToSave);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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
      final updated = expense.copyWith(
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
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
