import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/report_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense.dart';

void main() {
  group('ReportCalculationService', () {
    late ReportCalculationService service;

    setUp(() {
      service = ReportCalculationService();
    });

    group('filterSalesByDateRange', () {
      test('should return empty list for empty sales', () {
        final result = service.filterSalesByDateRange(
          sales: [],
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('should filter sales within date range', () {
        final sales = [
          Sale(
            id: '1',
            enterpriseId: 'test-enterprise',
            date: DateTime(2024, 1, 15),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
            customerPhone: '123456789',
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
          ),
          Sale(
            id: '2',
            enterpriseId: 'test-enterprise',
            date: DateTime(2024, 2, 15),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1500,
            customerId: 'c2',
            customerName: 'Customer 2',
            customerPhone: '987654321',
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
          ),
        ];

        final result = service.filterSalesByDateRange(
          sales: sales,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(result.length, equals(1));
        expect(result.first.id, equals('1'));
      });
    });

    group('filterExpensesByDateRange', () {
      test('should return empty list for empty expenses', () {
        final result = service.filterExpensesByDateRange(
          expenses: [],
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('should filter expenses within date range', () {
        final expenses = [
          Expense(
            id: 'e1',
            type: 'other',
            amount: 5000,
            description: 'Expense 1',
            date: DateTime(2024, 1, 15),
          ),
          Expense(
            id: 'e2',
            type: 'other',
            amount: 3000,
            description: 'Expense 2',
            date: DateTime(2024, 2, 15),
          ),
        ];

        final result = service.filterExpensesByDateRange(
          expenses: expenses,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(result.length, equals(1));
        expect(result.first.id, equals('e1'));
      });
    });

    group('calculateTotalRevenue', () {
      test('should return 0 for empty sales', () {
        final result = service.calculateTotalRevenue([]);
        expect(result, equals(0));
      });

      test('should calculate total revenue correctly', () {
        final sales = [
          Sale(
            id: '1',
            enterpriseId: 'test-enterprise',
            date: DateTime.now(),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
            customerPhone: '123456789',
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
          ),
          Sale(
            id: '2',
            enterpriseId: 'test-enterprise',
            date: DateTime.now(),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1500,
            customerId: 'c2',
            customerName: 'Customer 2',
            customerPhone: '987654321',
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
          ),
        ];

        final result = service.calculateTotalRevenue(sales);
        expect(result, equals(3500));
      });
    });

    group('calculateTotalCollections', () {
      test('should return 0 for empty sales', () {
        final result = service.calculateTotalCollections([]);
        expect(result, equals(0));
      });

      test('should calculate total collections correctly', () {
        final sales = [
          Sale(
            id: '1',
            enterpriseId: 'test-enterprise',
            date: DateTime.now(),
            productId: 'p1',
            productName: 'Product 1',
            quantity: 2,
            unitPrice: 1000,
            totalPrice: 2000,
            amountPaid: 2000,
            customerId: 'c1',
            customerName: 'Customer 1',
            customerPhone: '123456789',
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
          ),
          Sale(
            id: '2',
            enterpriseId: 'test-enterprise',
            date: DateTime.now(),
            productId: 'p2',
            productName: 'Product 2',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
            amountPaid: 1000,
            customerId: 'c2',
            customerName: 'Customer 2',
            customerPhone: '987654321',
            status: SaleStatus.validated,
            createdBy: 'user1',
          ),
        ];

        final result = service.calculateTotalCollections(sales);
        expect(result, equals(3000));
      });
    });

    group('calculateTotalExpenses', () {
      test('should return 0 for empty expenses', () {
        final result = service.calculateTotalExpenses([]);
        expect(result, equals(0));
      });

      test('should calculate total expenses correctly', () {
        final expenses = [
          Expense(
            id: 'e1',
            type: 'other',
            amount: 5000,
            description: 'Expense 1',
            date: DateTime.now(),
          ),
          Expense(
            id: 'e2',
            type: 'other',
            amount: 3000,
            description: 'Expense 2',
            date: DateTime.now(),
          ),
        ];

        final result = service.calculateTotalExpenses(expenses);
        expect(result, equals(8000));
      });
    });

    group('calculateProfit', () {
      test('should calculate profit correctly', () {
        final result = service.calculateProfit(10000, 5000);
        expect(result, equals(5000));
      });

      test('should handle negative profit', () {
        final result = service.calculateProfit(5000, 10000);
        expect(result, equals(-5000));
      });

      test('should handle zero profit', () {
        final result = service.calculateProfit(10000, 10000);
        expect(result, equals(0));
      });
    });
  });
}
