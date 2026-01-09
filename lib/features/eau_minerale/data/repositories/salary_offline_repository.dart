import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_payment_person.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/repositories/salary_repository.dart';

/// Offline-first repository for Salary entities (eau_minerale module).
///
/// Gère les employés fixes, les paiements de production et les paiements mensuels.
class SalaryOfflineRepository implements SalaryRepository {
  SalaryOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  // Collections séparées pour chaque type d'entité
  static const String _employeesCollection = 'employees';
  static const String _productionPaymentsCollection = 'production_payments';
  static const String _salaryPaymentsCollection = 'salary_payments';

  // Helpers pour Employee

  Map<String, dynamic> _employeeToMap(Employee entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'phone': entity.phone,
      'type': entity.type.name,
      'monthlySalary': entity.monthlySalary,
      'position': entity.position,
      'hireDate': entity.hireDate?.toIso8601String(),
    };
  }

  Employee _employeeFromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      type: _parseEmployeeType(map['type'] as String? ?? 'fixed'),
      monthlySalary: (map['monthlySalary'] as num?)?.toInt() ?? 0,
      position: map['position'] as String?,
      hireDate: map['hireDate'] != null
          ? DateTime.parse(map['hireDate'] as String)
          : null,
      paiementsMensuels: [], // Chargé séparément si nécessaire
    );
  }

  // Helpers pour ProductionPayment

  Map<String, dynamic> _productionPaymentToMap(ProductionPayment entity) {
    return {
      'id': entity.id,
      'period': entity.period,
      'paymentDate': entity.paymentDate.toIso8601String(),
      'persons': entity.persons.map((p) => {
            'name': p.name,
            'pricePerDay': p.pricePerDay,
            'daysWorked': p.daysWorked,
            'bonus': p.bonus,
            'deduction': p.deduction,
          }).toList(),
      'notes': entity.notes,
    };
  }

  ProductionPayment _productionPaymentFromMap(Map<String, dynamic> map) {
    return ProductionPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      persons: (map['persons'] as List<dynamic>?)
              ?.map((p) {
                final pricePerDay = (p['pricePerDay'] as num?)?.toInt() ?? 0;
                final daysWorked = (p['daysWorked'] as num?)?.toInt() ?? 0;
                final bonus = (p['bonus'] as num?)?.toInt() ?? 0;
                final deduction = (p['deduction'] as num?)?.toInt() ?? 0;
                final totalAmount = pricePerDay * daysWorked + bonus - deduction;
                return ProductionPaymentPerson(
                  name: p['name'] as String,
                  pricePerDay: pricePerDay,
                  daysWorked: daysWorked,
                  totalAmount: totalAmount,
                );
              })
              .toList() ??
          [],
      notes: map['notes'] as String?,
    );
  }

  // Helpers pour SalaryPayment

  Map<String, dynamic> _salaryPaymentToMap(SalaryPayment entity) {
    return {
      'id': entity.id,
      'employeeId': entity.employeeId,
      'employeeName': entity.employeeName,
      'amount': entity.amount,
      'date': entity.date.toIso8601String(),
      'period': entity.period,
      'notes': entity.notes,
      // Signature stockée en base64 si présente
      if (entity.signature != null)
        'signature': base64Encode(entity.signature!),
    };
  }

  SalaryPayment _salaryPaymentFromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] as String),
      period: map['period'] as String,
      notes: map['notes'] as String?,
      signature: map['signature'] != null
          ? base64Decode(map['signature'] as String)
          : null,
    );
  }

  // Implémentation de SalaryRepository

  @override
  Future<List<Employee>> fetchFixedEmployees() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _employeesCollection,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      return rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              final employee = _employeeFromMap(map);
              // Filtrer uniquement les employés fixes
              if (employee.type == EmployeeType.fixed) {
                return employee;
              }
              return null;
            } catch (e) {
              developer.log(
                'Error parsing employee: $e',
                name: 'SalaryOfflineRepository',
              );
              return null;
            }
          })
          .whereType<Employee>()
          .toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching fixed employees',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<String> createFixedEmployee(Employee employee) async {
    try {
      final localId = employee.id.startsWith('local_')
          ? employee.id
          : LocalIdGenerator.generate();
      final remoteId = employee.id.startsWith('local_') ? null : employee.id;

      final map = _employeeToMap(employee)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _employeesCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _employeesCollection,
        documentId: localId,
        operationType: 'create',
        payload: map,
        enterpriseId: enterpriseId,
      );

      return localId;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating fixed employee',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    try {
      final localId = employee.id.startsWith('local_')
          ? employee.id
          : LocalIdGenerator.generate();
      final remoteId = employee.id.startsWith('local_') ? null : employee.id;

      final map = _employeeToMap(employee)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _employeesCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _employeesCollection,
        documentId: remoteId ?? localId,
        operationType: 'update',
        payload: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating employee',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    try {
      // Trouver l'employé
      final employees = await fetchFixedEmployees();
      final employee = employees.firstWhere((e) => e.id == employeeId);

      final localId = employee.id.startsWith('local_')
          ? employee.id
          : LocalIdGenerator.generate();
      final remoteId = employee.id.startsWith('local_') ? null : employee.id;

      if (remoteId != null) {
        await driftService.records.deleteByRemoteId(
          collectionName: _employeesCollection,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'eau_minerale',
        );
      } else {
        await driftService.records.deleteByLocalId(
          collectionName: _employeesCollection,
          localId: localId,
          enterpriseId: enterpriseId,
          moduleType: 'eau_minerale',
        );
      }

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _employeesCollection,
        documentId: remoteId ?? localId,
        operationType: 'delete',
        payload: {},
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting employee',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<List<ProductionPayment>> fetchProductionPayments() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _productionPaymentsCollection,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      return rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _productionPaymentFromMap(map);
            } catch (e) {
              developer.log(
                'Error parsing production payment: $e',
                name: 'SalaryOfflineRepository',
              );
              return null;
            }
          })
          .whereType<ProductionPayment>()
          .toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching production payments',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<String> createProductionPayment(ProductionPayment payment) async {
    try {
      final localId = payment.id.startsWith('local_')
          ? payment.id
          : LocalIdGenerator.generate();
      final remoteId = payment.id.startsWith('local_') ? null : payment.id;

      final map = _productionPaymentToMap(payment)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _productionPaymentsCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _productionPaymentsCollection,
        documentId: localId,
        operationType: 'create',
        payload: map,
        enterpriseId: enterpriseId,
      );

      return localId;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating production payment',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<List<SalaryPayment>> fetchMonthlySalaryPayments() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _salaryPaymentsCollection,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      return rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _salaryPaymentFromMap(map);
            } catch (e) {
              developer.log(
                'Error parsing salary payment: $e',
                name: 'SalaryOfflineRepository',
              );
              return null;
            }
          })
          .whereType<SalaryPayment>()
          .toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching monthly salary payments',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    try {
      final localId = payment.id.startsWith('local_')
          ? payment.id
          : LocalIdGenerator.generate();
      final remoteId = payment.id.startsWith('local_') ? null : payment.id;

      final map = _salaryPaymentToMap(payment)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _salaryPaymentsCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _salaryPaymentsCollection,
        documentId: localId,
        operationType: 'create',
        payload: map,
        enterpriseId: enterpriseId,
      );

      return localId;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating monthly salary payment',
        name: 'SalaryOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  EmployeeType _parseEmployeeType(String type) {
    switch (type.toLowerCase()) {
      case 'fixed':
      case 'permanent':
        return EmployeeType.fixed;
      case 'production':
        return EmployeeType.production;
      default:
        return EmployeeType.fixed;
    }
  }
}

