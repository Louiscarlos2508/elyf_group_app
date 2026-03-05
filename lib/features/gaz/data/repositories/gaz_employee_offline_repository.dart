import 'dart:convert';
import 'package:elyf_groupe_app/core/errors/error_handler.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_employee.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gaz_employee_repository.dart';

class GazEmployeeOfflineRepository implements GazEmployeeRepository {
  GazEmployeeOfflineRepository({
    required this.driftService,
    required this.syncManager,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  static const String _collectionName = 'gas_employees';

  @override
  Future<void> saveEmployee(GazEmployee employee) async {
    try {
      await driftService.records.upsert(
        userId: syncManager.getUserId() ?? '',
        collectionName: _collectionName,
        localId: employee.id,
        enterpriseId: employee.enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(employee.toJson()),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving employee: ${appException.message}',
        name: 'GazEmployeeOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      // Find employee to get enterpriseId
      final employee = await getEmployee(id);
      if (employee == null) return;

      await driftService.records.deleteByLocalId(
        collectionName: _collectionName,
        localId: id,
        enterpriseId: employee.enterpriseId,
        moduleType: 'gaz',
      );
    } catch (error, stackTrace) {
      ErrorHandler.instance.handleError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<GazEmployee?> getEmployee(String id) async {
    try {
      final row = await driftService.records.findInCollectionByLocalId(
        collectionName: _collectionName,
        localId: id,
      );
      if (row == null) return null;
      final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
      return GazEmployee.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<GazEmployee>> watchEmployees(String enterpriseId) {
    return driftService.records.watchForEnterprise(
      collectionName: _collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    ).map((rows) {
      return rows.map((row) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          return GazEmployee.fromJson(map);
        } catch (e) {
          return null;
        }
      }).whereType<GazEmployee>().toList();
    });
  }
}
