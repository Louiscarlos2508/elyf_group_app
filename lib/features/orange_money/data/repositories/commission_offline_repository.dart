import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Offline-first repository for Commission entities.
class CommissionOfflineRepository extends OfflineRepository<Commission>
    implements CommissionRepository {
  CommissionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'commissions';

  @override
  Commission fromMap(Map<String, dynamic> map) {
    return Commission(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String,
      amount: (map['amount'] as num).toInt(),
      status: CommissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CommissionStatus.estimated,
      ),
      transactionsCount: (map['transactionsCount'] as num).toInt(),
      estimatedAmount: (map['estimatedAmount'] as num).toInt(),
      enterpriseId: map['enterpriseId'] as String,
      paidAt:
          map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      paymentDueDate: map['paymentDueDate'] != null
          ? DateTime.parse(map['paymentDueDate'] as String)
          : null,
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
  Map<String, dynamic> toMap(Commission entity) {
    return {
      'id': entity.id,
      'period': entity.period,
      'amount': entity.amount,
      'status': entity.status.name,
      'transactionsCount': entity.transactionsCount,
      'estimatedAmount': entity.estimatedAmount,
      'enterpriseId': entity.enterpriseId,
      'paidAt': entity.paidAt?.toIso8601String(),
      'paymentDueDate': entity.paymentDueDate?.toIso8601String(),
      'notes': entity.notes,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Commission entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Commission entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Commission entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(Commission entity) async {
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
  Future<void> deleteFromLocal(Commission entity) async {
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
  Future<Commission?> getByLocalId(String localId) async {
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
  Future<List<Commission>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // CommissionRepository implementation

  @override
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    try {
      final commissions =
          await getAllForEnterprise(enterpriseId ?? this.enterpriseId);
      return commissions.where((c) {
        if (status != null && c.status != status) return false;
        if (period != null && c.period != period) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching commissions',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Commission?> getCommission(String commissionId) async {
    try {
      return await getByLocalId(commissionId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting commission: $commissionId',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Commission?> getCurrentMonthCommission(String enterpriseId) async {
    try {
      final now = DateTime.now();
      final currentPeriod =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final commissions = await fetchCommissions(
        enterpriseId: enterpriseId,
        period: currentPeriod,
      );
      return commissions.isNotEmpty ? commissions.first : null;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting current month commission',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createCommission(Commission commission) async {
    try {
      final localId = getLocalId(commission);
      final commissionWithLocalId = Commission(
        id: localId,
        period: commission.period,
        amount: commission.amount,
        status: commission.status,
        transactionsCount: commission.transactionsCount,
        estimatedAmount: commission.estimatedAmount,
        enterpriseId: commission.enterpriseId,
        paidAt: commission.paidAt,
        paymentDueDate: commission.paymentDueDate,
        notes: commission.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(commissionWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating commission',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateCommission(Commission commission) async {
    try {
      final updated = Commission(
        id: commission.id,
        period: commission.period,
        amount: commission.amount,
        status: commission.status,
        transactionsCount: commission.transactionsCount,
        estimatedAmount: commission.estimatedAmount,
        enterpriseId: commission.enterpriseId,
        paidAt: commission.paidAt,
        paymentDueDate: commission.paymentDueDate,
        notes: commission.notes,
        createdAt: commission.createdAt,
        updatedAt: DateTime.now(),
      );
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating commission: ${commission.id}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    try {
      final commissions =
          await getAllForEnterprise(enterpriseId ?? this.enterpriseId);
      final paidCommissions =
          commissions.where((c) => c.status == CommissionStatus.paid).toList();
      final pendingCommissions = commissions
          .where((c) => c.status == CommissionStatus.pending)
          .toList();

      return {
        'totalCommissions': commissions.length,
        'totalPaid': paidCommissions.fold<int>(0, (sum, c) => sum + c.amount),
        'totalPending':
            pendingCommissions.fold<int>(0, (sum, c) => sum + c.amount),
        'paidCount': paidCommissions.length,
        'pendingCount': pendingCommissions.length,
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting commission statistics',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
