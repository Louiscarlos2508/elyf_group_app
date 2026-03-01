import 'dart:convert';

import 'package:elyf_groupe_app/core/errors/error_handler.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/drift/app_database.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/expense_repository.dart';

/// Offline-first repository for GazExpense entities.
class GazExpenseOfflineRepository extends OfflineRepository<GazExpense>
    implements GazExpenseRepository {
  GazExpenseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'gaz_expenses';

  @override
  GazExpense fromMap(Map<String, dynamic> map) =>
      GazExpense.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(GazExpense entity) => entity.toMap();

  @override
  String getLocalId(GazExpense entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(GazExpense entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(GazExpense entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(GazExpense entity, {String? userId}) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
  Future<void> deleteFromLocal(GazExpense entity, {String? userId}) async {
    // Soft-delete
    final deletedExpense = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedExpense, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted gaz expense: ${entity.id}',
      name: 'GazExpenseOfflineRepository',
    );
  }

  @override
  Future<GazExpense?> getByLocalId(String localId) async {
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
    final expense = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return expense.isDeleted ? null : expense;
  }

  @override
  Future<List<GazExpense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((expense) => !expense.isDeleted)
        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  @override
  Future<List<GazExpense>> getExpenses({DateTime? from, DateTime? to, List<String>? enterpriseIds}) async {
    try {
      final List<GazExpense> all;
      if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
        final rows = await driftService.records.listForEnterprises(
          collectionName: collectionName,
          enterpriseIds: enterpriseIds,
          moduleType: moduleType,
        );
        all = rows
            .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
            .where((expense) => !expense.isDeleted)
            .toList();
      } else {
        all = await getAllForEnterprise(enterpriseId);
      }

      return all.where((expense) {
        if (from != null && expense.date.isBefore(from)) return false;
        if (to != null && expense.date.isAfter(to)) return false;
        return true;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting expenses: ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // GazExpenseRepository implementation

  @override
  Stream<List<GazExpense>> watchExpenses({DateTime? from, DateTime? to, List<String>? enterpriseIds}) {
    final Stream<List<OfflineRecord>> stream;
    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      stream = driftService.records.watchForEnterprises(
        collectionName: collectionName,
        enterpriseIds: enterpriseIds,
        moduleType: moduleType,
      );
    } else {
      stream = driftService.records.watchForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
    }

    return stream.map((rows) {
      final entities = rows
          .map((r) {
            try {
              final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
              return fromMap(map);
            } catch (e) {
              return null;
            }
          })
          .whereType<GazExpense>()
          .where((expense) => !expense.isDeleted)
          .toList();

      final deduplicated = deduplicateByRemoteId(entities);
      return deduplicated.where((expense) {
        if (from != null && expense.date.isBefore(from)) return false;
        if (to != null && expense.date.isAfter(to)) return false;
        return true;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Future<GazExpense?> getExpenseById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting expense: $id - ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> addExpense(GazExpense expense) async {
    try {
      final localId = getLocalId(expense);
      final expenseToSave = expense.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(expenseToSave);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding expense: ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateExpense(GazExpense expense) async {
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
        name: 'GazExpenseOfflineRepository',
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
      AppLogger.error(
        'Error deleting expense: $id - ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    try {
      final expenses = await getExpenses(from: from, to: to);
      return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting total expenses: ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
