import 'dart:convert';
import 'dart:developer' as developer;
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
  Employee fromMap(Map<String, dynamic> map) {
    final paymentsRaw = map['paiementsMensuels'] as List<dynamic>? ?? [];
    final payments = paymentsRaw
        .map((p) => _salaryPaymentFromMap(p as Map<String, dynamic>))
        .toList();

    return Employee(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      type: EmployeeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EmployeeType.fixed,
      ),
      monthlySalary: (map['monthlySalary'] as num).toInt(),
      position: map['position'] as String?,
      hireDate: map['hireDate'] != null
          ? DateTime.parse(map['hireDate'] as String)
          : null,
      paiementsMensuels: payments,
    );
  }

  SalaryPayment _salaryPaymentFromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      amount: (map['amount'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      period: map['period'] as String,
      notes: map['notes'] as String?,
      signature: map['signature'] != null
          ? Uint8List.fromList((map['signature'] as List<dynamic>).cast<int>())
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Employee entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'phone': entity.phone,
      'type': entity.type.name,
      'monthlySalary': entity.monthlySalary,
      'position': entity.position,
      'hireDate': entity.hireDate?.toIso8601String(),
      'paiementsMensuels': entity.paiementsMensuels
          .map((p) => _salaryPaymentToMap(p))
          .toList(),
    };
  }

  Map<String, dynamic> _salaryPaymentToMap(SalaryPayment payment) {
    return {
      'id': payment.id,
      'employeeId': payment.employeeId,
      'employeeName': payment.employeeName,
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'period': payment.period,
      'notes': payment.notes,
      'signature': payment.signature?.toList(),
    };
  }

  @override
  String getLocalId(Employee entity) {
    if (entity.id.startsWith('local_')) return entity.id;
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
  Future<Employee?> getByLocalId(String localId) async {
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
  Future<List<Employee>> getAllForEnterprise(String enterpriseId) async {
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
      developer.log(
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
      return rows.map((r) {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        return _productionPaymentFromMap(map);
      }).toList();
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

  ProductionPayment _productionPaymentFromMap(Map<String, dynamic> map) {
    final personsRaw = map['persons'] as List<dynamic>? ?? [];
    final persons = personsRaw.map((p) {
      final pm = p as Map<String, dynamic>;
      return ProductionPaymentPerson(
        name: pm['name'] as String,
        pricePerDay:
            (pm['pricePerDay'] as num?)?.toInt() ??
            (pm['dailyRate'] as num?)?.toInt() ??
            0,
        daysWorked: (pm['daysWorked'] as num).toInt(),
        totalAmount: (pm['totalAmount'] as num?)?.toInt(),
      );
    }).toList();

    final sourceIds = map['sourceProductionDayIds'] as List<dynamic>?;

    return ProductionPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      persons: persons,
      notes: map['notes'] as String?,
      sourceProductionDayIds: sourceIds?.cast<String>() ?? [],
      isVerified: map['isVerified'] as bool? ?? false,
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
      signature: map['signature'] != null
          ? Uint8List.fromList((map['signature'] as List<dynamic>).cast<int>())
          : null,
    );
  }

  @override
  Future<String> createProductionPayment(ProductionPayment payment) async {
    try {
      final localId = payment.id.startsWith('local_')
          ? payment.id
          : LocalIdGenerator.generate();
      final map = {
        'id': localId,
        'localId': localId,
        'period': payment.period,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'persons': payment.persons
            .map(
              (p) => {
                'name': p.name,
                'pricePerDay': p.pricePerDay,
                'daysWorked': p.daysWorked,
                'totalAmount': p.totalAmount,
              },
            )
            .toList(),
        'notes': payment.notes,
        'sourceProductionDayIds': payment.sourceProductionDayIds,
        'isVerified': payment.isVerified,
        'verifiedBy': payment.verifiedBy,
        'verifiedAt': payment.verifiedAt?.toIso8601String(),
        'signature': payment.signature?.toList(),
      };

      await driftService.records.upsert(
        collectionName: productionPaymentsCollection,
        localId: localId,
        remoteId: null,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
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
      return rows.map((r) {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        return _salaryPaymentFromMap(map);
      }).toList();
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
      final localId = payment.id.startsWith('local_')
          ? payment.id
          : LocalIdGenerator.generate();
      final map = _salaryPaymentToMap(payment)..['localId'] = localId;
      map['id'] = localId;

      await driftService.records.upsert(
        collectionName: salaryPaymentsCollection,
        localId: localId,
        remoteId: null,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
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
