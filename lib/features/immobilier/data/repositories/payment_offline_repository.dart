import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

/// Offline-first repository for Payment entities (immobilier module).
class PaymentOfflineRepository extends OfflineRepository<Payment>
    implements PaymentRepository {
  PaymentOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'payments';

  String get moduleType => 'immobilier';

  @override
  Payment fromMap(Map<String, dynamic> map) => Payment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Payment entity) => entity.toMap();

  @override
  String getLocalId(Payment entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Payment entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Payment entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Payment entity) async {
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
  Future<void> deleteFromLocal(Payment entity) async {
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
  Future<Payment?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ) ?? await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
  }

  @override
  Future<List<Payment>> getAllPayments() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Payment>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(entities);
  }

  // PaymentRepository interface implementation

  @override
  Stream<List<Payment>> watchPayments() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => !e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Future<Payment?> getPaymentById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<Payment>> getPaymentsByContract(String contractId) async {
    final all = await getAllPayments();
    return all.where((p) => p.contractId == contractId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByPeriod(DateTime start, DateTime end) async {
    final all = await getAllPayments();
    return all.where((p) {
      return p.paymentDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
             p.paymentDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Stream<List<Payment>> watchDeletedPayments() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Future<void> restorePayment(String id) async {
    try {
      final payment = await getPaymentById(id);
      if (payment != null) {
        await save(payment.copyWith(
          deletedAt: null,
          deletedBy: null,
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Payment> createPayment(Payment payment) async {
    try {
      final localId = payment.id.isEmpty ? LocalIdGenerator.generate() : payment.id;
      final newPayment = payment.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: payment.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newPayment);
      return newPayment;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Payment> updatePayment(Payment payment) async {
    try {
      final updatedPayment = payment.copyWith(updatedAt: DateTime.now());
      await save(updatedPayment);
      return updatedPayment;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      final payment = await getPaymentById(id);
      if (payment != null) {
        await save(payment.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
