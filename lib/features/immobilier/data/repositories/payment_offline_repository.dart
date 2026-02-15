import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
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
    final companion = ImmobilierPaymentsTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      contractId: Value(entity.contractId),
      amount: Value(entity.amount),
      paidAmount: Value(entity.paidAmount),
      paymentDate: Value(entity.paymentDate),
      paymentMethod: Value(entity.paymentMethod.name),
      status: Value(entity.status.name),
      month: Value(entity.month),
      year: Value(entity.year),
      receiptNumber: Value(entity.receiptNumber),
      notes: Value(entity.notes),
      paymentType: Value(entity.paymentType?.name),
      cashAmount: Value(entity.cashAmount),
      mobileMoneyAmount: Value(entity.mobileMoneyAmount),
      penaltyAmount: Value(entity.penaltyAmount),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.immobilierPaymentsTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(Payment entity) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.immobilierPaymentsTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<Payment?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.immobilierPaymentsTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  Payment _fromEntity(ImmobilierPaymentEntity entity) {
    return Payment(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      contractId: entity.contractId,
      amount: entity.amount,
      paidAmount: entity.paidAmount,
      paymentDate: entity.paymentDate,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == entity.paymentMethod,
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == entity.status,
        orElse: () => PaymentStatus.paid,
      ),
      month: entity.month,
      year: entity.year,
      receiptNumber: entity.receiptNumber,
      notes: entity.notes,
      paymentType: entity.paymentType != null
          ? PaymentType.values.firstWhere(
              (e) => e.name == entity.paymentType,
              orElse: () => PaymentType.rent,
            )
          : null,
      cashAmount: entity.cashAmount,
      mobileMoneyAmount: entity.mobileMoneyAmount,
      penaltyAmount: entity.penaltyAmount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<Payment>> getAllPayments({bool? isDeleted = false}) async {
    final query = driftService.db.select(driftService.db.immobilierPaymentsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }

    final rows = await query.get();
    return rows.map<Payment>(_fromEntity).toList();
  }

  @override
  Future<List<Payment>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.immobilierPaymentsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map<Payment>(_fromEntity).toList();
  }

  // PaymentRepository interface implementation

  @override
  Stream<List<Payment>> watchPayments({bool? isDeleted = false}) {
    final query = driftService.db.select(driftService.db.immobilierPaymentsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }

    return query.watch().map((rows) => rows.map<Payment>(_fromEntity).toList());
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
    final query = driftService.db.select(driftService.db.immobilierPaymentsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.deletedAt.isNotNull());
    return query.watch().map((rows) => rows.map<Payment>(_fromEntity).toList());
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
