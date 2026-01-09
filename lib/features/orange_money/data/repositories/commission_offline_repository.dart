import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Offline-first repository for Commission entities (orange_money module).
class CommissionOfflineRepository extends OfflineRepository<Commission>
    implements CommissionRepository {
  CommissionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'commissions';

  @override
  Commission fromMap(Map<String, dynamic> map) {
    return Commission(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: _parseStatus(map['status'] as String? ?? 'estimated'),
      transactionsCount: (map['transactionsCount'] as num?)?.toInt() ?? 0,
      estimatedAmount: (map['estimatedAmount'] as num?)?.toInt() ?? 0,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      paidAt: map['paidAt'] != null
          ? DateTime.parse(map['paidAt'] as String)
          : null,
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
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Commission entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'orange_money',
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
        moduleType: 'orange_money',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
  }

  @override
  Future<Commission?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<Commission>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing commission: $e',
              name: 'CommissionOfflineRepository',
            );
            return null;
          }
        })
        .whereType<Commission>()
        .toList();
  }

  // Implémentation de CommissionRepository

  @override
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    try {
      final effectiveEnterpriseId = enterpriseId ?? this.enterpriseId;
      var commissions = await getAllForEnterprise(effectiveEnterpriseId);

      if (status != null) {
        commissions = commissions.where((c) => c.status == status).toList();
      }

      if (period != null) {
        commissions = commissions.where((c) => c.period == period).toList();
      }

      commissions.sort((a, b) => b.period.compareTo(a.period));
      return commissions;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching commissions',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<Commission?> getCommission(String commissionId) async {
    try {
      return await getByLocalId(commissionId);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting commission',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<Commission?> getCurrentMonthCommission(String enterpriseId) async {
    try {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final commissions = await fetchCommissions(
        enterpriseId: enterpriseId,
        period: period,
      );
      return commissions.isNotEmpty ? commissions.first : null;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting current month commission',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<String> createCommission(Commission commission) async {
    try {
      final commissionWithId = commission.id.isEmpty
          ? Commission(
              id: LocalIdGenerator.generate(),
              period: commission.period,
              amount: commission.amount,
              status: commission.status,
              transactionsCount: commission.transactionsCount,
              estimatedAmount: commission.estimatedAmount,
              enterpriseId: commission.enterpriseId,
              paidAt: commission.paidAt,
              paymentDueDate: commission.paymentDueDate,
              notes: commission.notes,
              createdAt: commission.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : commission;
      await save(commissionWithId);
      return commissionWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating commission',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCommission(Commission commission) async {
    try {
      final updatedCommission = Commission(
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
      await save(updatedCommission);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating commission',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
  }) async {
    try {
      final effectiveEnterpriseId = enterpriseId ?? this.enterpriseId;
      final commissions = await getAllForEnterprise(effectiveEnterpriseId);

      final totalCommissions = commissions.fold<int>(
        0,
        (sum, c) => sum + c.amount,
      );
      final pendingCommissions = commissions
          .where((c) => c.status == CommissionStatus.pending)
          .fold<int>(0, (sum, c) => sum + c.amount);
      final paidCommissions = commissions
          .where((c) => c.status == CommissionStatus.paid)
          .fold<int>(0, (sum, c) => sum + c.amount);

      return {
        'totalCommissions': totalCommissions,
        'pendingCommissions': pendingCommissions,
        'paidCommissions': paidCommissions,
        'totalCount': commissions.length,
        'pendingCount': commissions
            .where((c) => c.status == CommissionStatus.pending)
            .length,
        'paidCount': commissions
            .where((c) => c.status == CommissionStatus.paid)
            .length,
      };
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting commission statistics',
        name: 'CommissionOfflineRepository',
        error: appException,
      );
      return {};
    }
  }

  CommissionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'estimated':
        return CommissionStatus.estimated;
      case 'pending':
        return CommissionStatus.pending;
      case 'paid':
        return CommissionStatus.paid;
      default:
        return CommissionStatus.estimated;
    }
  }
}

