import 'dart:convert';
import 'package:elyf_groupe_app/core/errors/error_handler.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_salary_payment.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gaz_salary_payment_repository.dart';

class GazSalaryPaymentOfflineRepository implements GazSalaryPaymentRepository {
  GazSalaryPaymentOfflineRepository({
    required this.driftService,
    required this.syncManager,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  static const String _collectionName = 'gas_salary_payments';

  @override
  Future<void> savePayment(GazSalaryPayment payment) async {
    try {
      await driftService.records.upsert(
        userId: syncManager.getUserId() ?? '',
        collectionName: _collectionName,
        localId: payment.id,
        enterpriseId: payment.enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(payment.toJson()),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving salary payment: ${appException.message}',
        name: 'GazSalaryPaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<GazSalaryPayment>> watchPayments(String enterpriseId) {
    return driftService.records.watchForEnterprise(
      collectionName: _collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    ).map((rows) {
      return rows.map((row) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          return GazSalaryPayment.fromJson(map);
        } catch (e) {
          return null;
        }
      }).whereType<GazSalaryPayment>().toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    });
  }

  @override
  Future<List<GazSalaryPayment>> getPaymentsByEmployee(String employeeId) async {
    try {
      final rows = await driftService.records.listForCollection(
        collectionName: _collectionName,
        moduleType: 'gaz',
      );
      return rows.map((row) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final payment = GazSalaryPayment.fromJson(map);
          return payment.employeeId == employeeId ? payment : null;
        } catch (e) {
          return null;
        }
      }).whereType<GazSalaryPayment>().toList();
    } catch (e) {
      return [];
    }
  }
}
