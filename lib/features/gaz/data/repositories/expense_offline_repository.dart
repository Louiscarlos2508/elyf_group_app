import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Offline-first repository for GazExpense entities (gaz module).
class ExpenseOfflineRepository extends OfflineRepository<GazExpense>
    implements GazExpenseRepository {
  ExpenseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'gaz_expenses';

  @override
  GazExpense fromMap(Map<String, dynamic> map) {
    return GazExpense(
      id: map['id'] as String? ?? map['localId'] as String,
      category: _parseCategory(map['category'] as String? ?? ''),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
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
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(GazExpense entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(GazExpense entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(GazExpense entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
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
        moduleType: 'gaz',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
  }

  @override
  Future<GazExpense?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<GazExpense>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing expense: $e',
              name: 'ExpenseOfflineRepository',
            );
            return null;
          }
        })
        .whereType<GazExpense>()
        .toList();
  }

  // Implémentation de GazExpenseRepository

  @override
  Future<List<GazExpense>> getExpenses({DateTime? from, DateTime? to}) async {
    try {
      var expenses = await getAllForEnterprise(enterpriseId);

      if (from != null) {
        expenses = expenses
            .where((e) => e.date.isAfter(from) || e.date.isAtSameMomentAs(from))
            .toList();
      }

      if (to != null) {
        expenses = expenses
            .where((e) => e.date.isBefore(to) || e.date.isAtSameMomentAs(to))
            .toList();
      }

      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching expenses',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<GazExpense?> getExpenseById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting expense',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> addExpense(GazExpense expense) async {
    try {
      final expenseWithId = expense.id.isEmpty
          ? expense.copyWith(id: LocalIdGenerator.generate())
          : expense;
      await save(expenseWithId);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding expense',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(GazExpense expense) async {
    try {
      await save(expense);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating expense',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      rethrow;
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting expense',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    try {
      final expenses = await getExpenses(from: from, to: to);
      return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error calculating total expenses',
        name: 'ExpenseOfflineRepository',
        error: appException,
      );
      return 0.0;
    }
  }

  ExpenseCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'structurecharges':
      case 'structure_charges':
        return ExpenseCategory.structureCharges;
      case 'salaries':
        return ExpenseCategory.salaries;
      case 'loadingevents':
      case 'loading_events':
        return ExpenseCategory.loadingEvents;
      case 'transport':
        return ExpenseCategory.transport;
      case 'rent':
      case 'loyer':
        return ExpenseCategory.rent;
      case 'utilities':
      case 'services_publics':
        return ExpenseCategory.utilities;
      case 'supplies':
      case 'fournitures':
        return ExpenseCategory.supplies;
      case 'other':
      case 'autres':
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.other;
    }
  }
}

