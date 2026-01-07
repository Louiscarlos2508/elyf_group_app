import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/services/dashboard_calculation_service.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/entities/customer_account.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/entities/expense.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_group_app/features/eau_minerale/domain/entities/salary.dart';

void main() {
  group('DashboardCalculationService', () {
    late DashboardCalculationService service;

    setUp(() {
      service = DashboardCalculationService();
    });

    group('calculateMonthlyRevenue', () {
      test('should return 0 for empty sales list', () {
        final result = service.calculateMonthlyRevenue([], DateTime.now());
        expect(result, equals(0));
      });

      test('should calculate revenue for sales in current month', () {
        final now = DateTime(2024, 1, 15);
        final monthStart = DateTime(2024, 1, 1);
        final sales = [
          Sale(
            id: '1',
            date: DateTime(2024, 1, 10),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
          ),
          Sale(
            id: '2',
            date: DateTime(2024, 1, 20),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1500,
            customerId: 'c2',
            customerName: 'Customer 2',
          ),
        ];

        final result = service.calculateMonthlyRevenue(sales, monthStart);
        expect(result, equals(3500));
      });

      test('should exclude sales from previous months', () {
        final now = DateTime(2024, 1, 15);
        final monthStart = DateTime(2024, 1, 1);
        final sales = [
          Sale(
            id: '1',
            date: DateTime(2023, 12, 31),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
          ),
          Sale(
            id: '2',
            date: DateTime(2024, 1, 10),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1500,
            customerId: 'c2',
            customerName: 'Customer 2',
          ),
        ];

        final result = service.calculateMonthlyRevenue(sales, monthStart);
        expect(result, equals(1500));
      });
    });

    group('calculateMonthlyCollections', () {
      test('should return 0 for empty sales list', () {
        final result = service.calculateMonthlyCollections([], DateTime.now());
        expect(result, equals(0));
      });

      test('should calculate collections only for fully paid sales', () {
        final monthStart = DateTime(2024, 1, 1);
        final sales = [
          Sale(
            id: '1',
            date: DateTime(2024, 1, 10),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
          ),
          Sale(
            id: '2',
            date: DateTime(2024, 1, 20),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1000,
            customerId: 'c2',
            customerName: 'Customer 2',
          ),
        ];

        final result = service.calculateMonthlyCollections(sales, monthStart);
        expect(result, equals(2000));
      });
    });

    group('calculateCollectionRate', () {
      test('should return 0 when revenue is 0', () {
        final result = service.calculateCollectionRate(0, 1000);
        expect(result, equals(0.0));
      });

      test('should calculate collection rate correctly', () {
        final result = service.calculateCollectionRate(2000, 1500);
        expect(result, equals(75.0));
      });
    });

    group('calculateTotalCredits', () {
      test('should return 0 for empty customers list', () {
        final result = service.calculateTotalCredits([]);
        expect(result, equals(0));
      });

      test('should calculate total credits from customers', () {
        final customers = [
          CustomerAccount(
            id: 'c1',
            customerName: 'Customer 1',
            totalCredit: 5000,
            lastSaleDate: DateTime.now(),
          ),
          CustomerAccount(
            id: 'c2',
            customerName: 'Customer 2',
            totalCredit: 3000,
            lastSaleDate: DateTime.now(),
          ),
        ];

        final result = service.calculateTotalCredits(customers);
        expect(result, equals(8000));
      });
    });

    group('countCreditCustomers', () {
      test('should return 0 for empty customers list', () {
        final result = service.countCreditCustomers([]);
        expect(result, equals(0));
      });

      test('should count only customers with active credits', () {
        final customers = [
          CustomerAccount(
            id: 'c1',
            customerName: 'Customer 1',
            totalCredit: 5000,
            lastSaleDate: DateTime.now(),
          ),
          CustomerAccount(
            id: 'c2',
            customerName: 'Customer 2',
            totalCredit: 0,
            lastSaleDate: DateTime.now(),
          ),
          CustomerAccount(
            id: 'c3',
            customerName: 'Customer 3',
            totalCredit: 3000,
            lastSaleDate: DateTime.now(),
          ),
        ];

        final result = service.countCreditCustomers(customers);
        expect(result, equals(2));
      });
    });

    group('calculateMonthlyExpenses', () {
      test('should return 0 for empty expenses list', () {
        final result = service.calculateMonthlyExpenses([], DateTime.now());
        expect(result, equals(0));
      });

      test('should calculate expenses for current month', () {
        final monthStart = DateTime(2024, 1, 1);
        final expenses = [
          Expense(
            id: 'e1',
            label: 'Expense 1',
            amountCfa: 5000,
            category: ExpenseCategory.other,
            date: DateTime(2024, 1, 10),
          ),
          Expense(
            id: 'e2',
            label: 'Expense 2',
            amountCfa: 3000,
            category: ExpenseCategory.other,
            date: DateTime(2024, 1, 20),
          ),
        ];

        final result = service.calculateMonthlyExpenses(expenses, monthStart);
        expect(result, equals(8000));
      });
    });

    group('calculateMonthlyResult', () {
      test('should calculate result correctly', () {
        final result = service.calculateMonthlyResult(10000, 5000);
        expect(result, equals(5000));
      });

      test('should handle negative result', () {
        final result = service.calculateMonthlyResult(5000, 10000);
        expect(result, equals(-5000));
      });
    });

    group('calculateMonthlyMetrics', () {
      test('should calculate all metrics correctly', () {
        final now = DateTime(2024, 1, 15);
        final monthStart = DateTime(2024, 1, 1);
        final sales = [
          Sale(
            id: '1',
            date: DateTime(2024, 1, 10),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
          ),
        ];
        final customers = [
          CustomerAccount(
            id: 'c1',
            customerName: 'Customer 1',
            totalCredit: 1000,
            lastSaleDate: DateTime.now(),
          ),
        ];
        final expenses = [
          Expense(
            id: 'e1',
            label: 'Expense 1',
            amountCfa: 500,
            category: ExpenseCategory.other,
            date: DateTime(2024, 1, 10),
          ),
        ];

        final metrics = service.calculateMonthlyMetrics(
          sales: sales,
          customers: customers,
          expenses: expenses,
          referenceDate: now,
        );

        expect(metrics.revenue, equals(2000));
        expect(metrics.collections, equals(2000));
        expect(metrics.collectionRate, equals(100.0));
        expect(metrics.totalCredits, equals(1000));
        expect(metrics.creditCustomersCount, equals(1));
        expect(metrics.expenses, equals(500));
        expect(metrics.result, equals(1500));
        expect(metrics.salesCount, equals(1));
        expect(metrics.expensesCount, equals(1));
      });
    });

    group('calculateOperationsMetrics', () {
      test('should calculate operations metrics correctly', () {
        final now = DateTime(2024, 1, 15);
        final monthStart = DateTime(2024, 1, 1);
        final expenses = [
          Expense(
            id: 'e1',
            label: 'Expense 1',
            amountCfa: 5000,
            category: ExpenseCategory.other,
            date: DateTime(2024, 1, 10),
          ),
        ];
        final productionSessions = [
          ProductionSession(
            id: 'ps1',
            date: DateTime(2024, 1, 10),
            heureDebut: DateTime(2024, 1, 10, 8),
            heureFin: DateTime(2024, 1, 10, 16),
            machinesUtilisees: ['m1'],
            quantiteProduite: 1000,
            status: ProductionSessionStatus.completed,
            bobinesUtilisees: [],
          ),
        ];
        final salaries = [
          Salary(
            id: 's1',
            employeeName: 'Employee 1',
            amount: 10000,
            paymentDate: DateTime(2024, 1, 5),
          ),
        ];

        final metrics = service.calculateOperationsMetrics(
          expenses: expenses,
          productionSessions: productionSessions,
          salaries: salaries,
          referenceDate: now,
        );

        expect(metrics.production, equals(1000));
        expect(metrics.productionSessionsCount, equals(1));
        expect(metrics.expenses, equals(5000));
        expect(metrics.expensesCount, equals(1));
        expect(metrics.salaries, equals(10000));
        expect(metrics.salariesCount, equals(1));
      });
    });
  });
}
