import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../shared/domain/entities/payment_method.dart';
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
  String get collectionName => CollectionNames.payments;

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
  Future<void> saveToLocal(Payment entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity);
    map['localId'] = localId;

    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
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
  Future<void> deleteFromLocal(Payment entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedPayment = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedPayment, userId: userId);
  }

  @override
  Future<Payment?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final payment = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return payment.isDeleted ? null : payment;
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
  Future<List<Payment>> getAllPayments({bool? isDeleted = false}) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((p) {
      if (isDeleted == null) return true;
      return p.isDeleted == isDeleted;
    }).toList();
  }

  @override
  Future<List<Payment>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // PaymentRepository interface implementation

  @override
  Stream<List<Payment>> watchPayments({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((p) {
        if (isDeleted == null) return true;
        return p.isDeleted == isDeleted;
      }).toList();
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
    return watchPayments(isDeleted: true);
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
        await delete(payment);
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
