import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_payment_person.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/repositories/salary_repository.dart';

/// Offline-first repository for Employee and Salary entities.
class SalaryOfflineRepository extends OfflineRepository<Employee>
    implements SalaryRepository {
  SalaryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'employees';

  String get salaryPaymentsCollection => 'salary_payments';
  String get productionPaymentsCollection => 'production_payments';

  @override
  Employee fromMap(Map<String, dynamic> map) => Employee.fromMap(map);

  @override
  Map<String, dynamic> toMap(Employee entity) => entity.toMap();

  @override
  String getLocalId(Employee entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Employee entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Employee entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Employee entity) async {
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
  Future<void> deleteFromLocal(Employee entity) async {
    // Soft-delete
    final deletedEmployee = entity.copyWith(
      deletedAt: DateTime.now(),
    );
    await saveToLocal(deletedEmployee);
    
    AppLogger.info(
      'Soft-deleted employee: ${entity.id}',
      name: 'SalaryOfflineRepository',
    );
  }

  @override
  Future<Employee?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final employee = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return employee.isDeleted ? null : employee;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final employee = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return employee.isDeleted ? null : employee;
  }

  @override
  Future<List<Employee>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((e) => !e.isDeleted)
        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // SalaryRepository implementation

  @override
  Future<List<Employee>> fetchFixedEmployees() async {
    try {
      final employees = await getAllForEnterprise(enterpriseId);
      return employees.where((e) => e.type == EmployeeType.fixed).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching fixed employees: ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createFixedEmployee(Employee employee) async {
    try {
      final localId = getLocalId(employee);
      final employeeWithLocalId = Employee(
        id: localId,
        name: employee.name,
        phone: employee.phone,
        type: employee.type,
        monthlySalary: employee.monthlySalary,
        position: employee.position,
        hireDate: employee.hireDate ?? DateTime.now(),
        paiementsMensuels: employee.paiementsMensuels,
      );
      await save(employeeWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating fixed employee',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    try {
      await save(employee);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating employee: ${employee.id} - ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    try {
      final employee = await getByLocalId(employeeId);
      if (employee != null) {
        await delete(employee);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting employee: $employeeId - ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<ProductionPayment>> fetchProductionPayments() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: productionPaymentsCollection,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return rows
          .map((r) {
            final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
            return ProductionPayment.fromMap(map);
          })
          .where((p) => !p.isDeleted)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching production payments: ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }


  @override
  Future<void> deleteProductionPayment(String paymentId) async {
    try {
      // Pour annuler une transaction locale récente, l'ID est forcément local
      // Soft-delete pour les paiements de production
      final record = await driftService.records.findByLocalId(
        collectionName: productionPaymentsCollection,
        localId: paymentId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      if (record != null) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        final payment = ProductionPayment.fromMap(map);
        final deletedPayment = payment.copyWith(deletedAt: DateTime.now());
        
        await driftService.records.upsert(
          collectionName: productionPaymentsCollection,
          localId: paymentId,
          remoteId: record.remoteId,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
          dataJson: jsonEncode(deletedPayment.toMap()),
          localUpdatedAt: DateTime.now(),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting production payment: $paymentId - ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createProductionPayment(ProductionPayment payment) async {
    try {
      final localId = payment.id.isNotEmpty
          ? payment.id
          : LocalIdGenerator.generate();
      
      final paymentToSave = payment.copyWith(
        id: localId,
        createdAt: payment.createdAt ?? DateTime.now(),
      );
      final map = paymentToSave.toMap();

      await driftService.db.transaction(() async {
        // 1. Sauvegarder localement
        await driftService.records.upsert(
          collectionName: productionPaymentsCollection,
          localId: localId,
          remoteId: null,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
          dataJson: jsonEncode(map),
          localUpdatedAt: DateTime.now(),
        );

        // 2. File d'attente de synchronisation
        if (enableAutoSync) {
          await syncManager.queueCreate(
            collectionName: productionPaymentsCollection,
            localId: localId,
            data: map,
            enterpriseId: enterpriseId,
          );
        }
      });

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating production payment',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<SalaryPayment>> fetchMonthlySalaryPayments() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: salaryPaymentsCollection,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return rows
          .map((r) {
            final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
            return SalaryPayment.fromMap(map);
          })
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching monthly salary payments: ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    try {
      final localId = payment.id.isNotEmpty
          ? payment.id
          : LocalIdGenerator.generate();
      final updatedPayment = payment.copyWith(id: localId);
      final map = updatedPayment.toMap()..['localId'] = localId;

      await driftService.db.transaction(() async {
        // 1. Sauvegarder localement
        await driftService.records.upsert(
          collectionName: salaryPaymentsCollection,
          localId: localId,
          remoteId: null,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
          dataJson: jsonEncode(map),
          localUpdatedAt: DateTime.now(),
        );

        // 2. File d'attente de synchronisation
        if (enableAutoSync) {
          await syncManager.queueCreate(
            collectionName: salaryPaymentsCollection,
            localId: localId,
            data: map,
            enterpriseId: enterpriseId,
          );
        }
      });

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating monthly salary payment: ${appException.message}',
        name: 'SalaryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
