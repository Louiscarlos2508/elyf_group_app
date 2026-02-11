import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/dashboard_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_account.dart';

void main() {
  group('DashboardCalculationService', () {
    late DashboardCalculationService service;

    setUp(() {
      service = DashboardCalculationService();
    });

    group('calculateTodayCollections', () {
      test('should calculate today collections correctly', () {
        final today = DateTime.now();
        final sales = [
          Sale(
            id: '1',
            enterpriseId: 'test-enterprise',
            productId: 'p1',
            productName: 'Product 1',
            customerId: 'c1',
            customerName: 'Customer 1',
            customerPhone: '123456789',
            quantity: 10,
            unitPrice: 500,
            totalPrice: 5000,
            amountPaid: 5000,
            date: today,
            status: SaleStatus.fullyPaid,
            createdBy: 'user1',
            cashAmount: 5000,
          ),
          Sale(
            id: '2',
            enterpriseId: 'test-enterprise',
            productId: 'p2',
            productName: 'Product 2',
            customerId: 'c2',
            customerName: 'Customer 2',
            customerPhone: '987654321',
            quantity: 5,
            unitPrice: 600,
            totalPrice: 3000,
            amountPaid: 1500,
            date: today,
            status: SaleStatus.validated,
            createdBy: 'user1',
            cashAmount: 1500,
          ),
        ];

        final collections = service.calculateTodayCollections(sales);
        expect(collections, 5000);
      });

      test('should return 0 when no fully paid sales today', () {
        final today = DateTime.now();
        final sales = [
          Sale(
            id: '1',
            enterpriseId: 'test-enterprise',
            productId: 'p1',
            productName: 'Product 1',
            customerId: 'c1',
            customerName: 'Customer 1',
            customerPhone: '123456789',
            quantity: 10,
            unitPrice: 500,
            totalPrice: 5000,
            amountPaid: 2000,
            date: today,
            status: SaleStatus.validated,
            createdBy: 'user1',
            cashAmount: 2000,
          ),
        ];

        final collections = service.calculateTodayCollections(sales);
        expect(collections, 0);
      });
    });

    group('calculateCollectionRate', () {
      test('should calculate collection rate correctly', () {
        final rate = service.calculateCollectionRate(10000, 7500);
        expect(rate, 75.0);
      });

      test('should return 0 when revenue is 0', () {
        final rate = service.calculateCollectionRate(0, 0);
        expect(rate, 0.0);
      });
    });

    group('calculateTotalCredits', () {
      test('should calculate total credits correctly', () {
        final customers = [
          CustomerAccount(
            id: '1',
            name: 'Customer 1',
            outstandingCredit: 5000,
            lastOrderDate: DateTime.now(),
            phone: '123456789',
          ),
          CustomerAccount(
            id: '2',
            name: 'Customer 2',
            outstandingCredit: 3000,
            lastOrderDate: DateTime.now(),
            phone: '987654321',
          ),
        ];

        final totalCredits = service.calculateTotalCredits(customers);
        expect(totalCredits, 8000);
      });
    });
  });
}
