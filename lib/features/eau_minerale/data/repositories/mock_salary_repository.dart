import 'dart:async';

import '../../domain/entities/employee.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_payment_person.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/repositories/salary_repository.dart';

class MockSalaryRepository implements SalaryRepository {
  final List<Employee> _fixedEmployees = [];
  final List<ProductionPayment> _productionPayments = [];
  final List<SalaryPayment> _monthlySalaryPayments = [];

  MockSalaryRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock fixed employees
    _fixedEmployees.addAll([
      Employee(
        id: 'emp-1',
        name: 'Jean Dupont',
        phone: '+221770001234',
        type: EmployeeType.fixed,
        monthlySalary: 150000,
        position: 'Gérant',
        hireDate: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Employee(
        id: 'emp-2',
        name: 'Marie Traoré',
        phone: '+221770001235',
        type: EmployeeType.fixed,
        monthlySalary: 120000,
        position: 'Vendeuse',
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ]);

    // Mock monthly salary payments
    final now = DateTime.now();
    _monthlySalaryPayments.addAll([
      SalaryPayment(
        id: 'salary-1',
        employeeId: 'emp-1',
        employeeName: 'Jean Dupont',
        amount: 150000,
        date: DateTime(now.year, now.month, 5),
        period: _getMonthName(now.month) + ' ${now.year}',
        notes: 'Paiement complet',
      ),
      SalaryPayment(
        id: 'salary-2',
        employeeId: 'emp-2',
        employeeName: 'Marie Traoré',
        amount: 120000,
        date: DateTime(now.year, now.month, 5),
        period: _getMonthName(now.month) + ' ${now.year}',
      ),
      SalaryPayment(
        id: 'salary-3',
        employeeId: 'emp-1',
        employeeName: 'Jean Dupont',
        amount: 150000,
        date: DateTime(now.year, now.month - 1, 5),
        period: _getMonthName(now.month - 1) + ' ${now.year}',
      ),
    ]);

    // Mock production payments
    _productionPayments.addAll([
      ProductionPayment(
        id: 'prod-pay-1',
        period: '11-20 ${_getMonthName(now.month)} ${now.year}',
        paymentDate: DateTime(now.year, now.month, 15),
        persons: [
          ProductionPaymentPerson(
            name: 'Mamadou Traoré',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
          ProductionPaymentPerson(
            name: 'Amadou Diallo',
            pricePerDay: 6000,
            daysWorked: 4,
          ),
        ],
        notes: 'Production de 500 packs',
      ),
      ProductionPayment(
        id: 'prod-pay-2',
        period: '1-10 ${_getMonthName(now.month)} ${now.year}',
        paymentDate: DateTime(now.year, now.month, 10),
        persons: [
          ProductionPaymentPerson(
            name: 'Mamadou Traoré',
            pricePerDay: 5000,
            daysWorked: 3,
          ),
        ],
      ),
      ProductionPayment(
        id: 'prod-pay-3',
        period: '21-30 ${_getMonthName(now.month - 1)} ${now.year}',
        paymentDate: DateTime(now.year, now.month - 1, 25),
        persons: [
          ProductionPaymentPerson(
            name: 'Ibrahima Sall',
            pricePerDay: 5500,
            daysWorked: 6,
          ),
          ProductionPaymentPerson(
            name: 'Ousmane Ba',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
        ],
      ),
    ]);
  }

  String _getMonthName(int month) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    if (month < 1) month = 12 + month;
    if (month > 12) month = month - 12;
    return months[month - 1];
  }

  @override
  Future<List<Employee>> fetchFixedEmployees() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _fixedEmployees.toList();
  }

  @override
  Future<String> createFixedEmployee(Employee employee) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _fixedEmployees.add(employee);
    return employee.id;
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _fixedEmployees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _fixedEmployees[index] = employee;
    }
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _fixedEmployees.removeWhere((e) => e.id == employeeId);
  }

  @override
  Future<List<ProductionPayment>> fetchProductionPayments() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _productionPayments.toList();
  }

  @override
  Future<String> createProductionPayment(ProductionPayment payment) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _productionPayments.add(payment);
    return payment.id;
  }

  @override
  Future<List<SalaryPayment>> fetchMonthlySalaryPayments() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _monthlySalaryPayments.toList();
  }

  @override
  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _monthlySalaryPayments.add(payment);
    return payment.id;
  }
}

