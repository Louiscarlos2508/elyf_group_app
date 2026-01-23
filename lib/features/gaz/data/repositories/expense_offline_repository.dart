import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

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
  GazExpense fromMap(Map<String, dynamic> map) {
    return GazExpense(
      id: map['id'] as String? ?? map['localId'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      enterpriseId: map['enterpriseId'] as String,
      isFixed: map['isFixed'] as bool? ?? false,
      notes: map['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(GazExpense entity) {
    return {
      'id': entity.id,
      'category': entity.category.name,
      'amount': entity.amount,
      'description': entity.description,
      'date': entity.date.toIso8601String(),
      'enterpriseId': entity.enterpriseId,
      'isFixed': entity.isFixed,
      'notes': entity.notes,
    };
  }

  @override
  String getLocalId(GazExpense entity) {
    if (entity.id.startsWith('local_')) return entity.id;
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
  Future<void> saveToLocal(GazExpense entity) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
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
  Future<void> deleteFromLocal(GazExpense entity) async {
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
  Future<GazExpense?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
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

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // GazExpenseRepository implementation

  @override
  Future<List<GazExpense>> getExpenses({DateTime? from, DateTime? to}) async {
    try {
      final expenses = await getAllForEnterprise(enterpriseId);
      return expenses.where((expense) {
        if (from != null && expense.date.isBefore(from)) return false;
        if (to != null && expense.date.isAfter(to)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting expenses: ${appException.message}',
        name: 'GazExpenseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
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
      final expenseWithLocalId = expense.copyWith(id: localId);
      await save(expenseWithLocalId);
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
      await save(expense);
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
