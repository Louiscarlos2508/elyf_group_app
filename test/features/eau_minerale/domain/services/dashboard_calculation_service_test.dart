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
            productId: 'p1',
            productName: 'Product 1',
            customerId: 'c1',
            customerName: 'Customer 1',
            quantity: 10,
            totalPrice: 5000,
            amountPaid: 5000,
            date: today,
            paymentMethod: 'cash',
            isFullyPaid: true,
          ),
          Sale(
            id: '2',
            productId: 'p2',
            productName: 'Product 2',
            customerId: 'c2',
            customerName: 'Customer 2',
            quantity: 5,
            totalPrice: 3000,
            amountPaid: 1500,
            date: today,
            paymentMethod: 'cash',
            isFullyPaid: false,
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
            productId: 'p1',
            productName: 'Product 1',
            customerId: 'c1',
            customerName: 'Customer 1',
            quantity: 10,
            totalPrice: 5000,
            amountPaid: 2000,
            date: today,
            paymentMethod: 'cash',
            isFullyPaid: false,
          ),
        ];

        final collections = service.calculateTodayCollections(sales);
        expect(collections, 0);
      });
    });

    group('calculateCollectionRate', () {
      test('should calculate collection rate correctly', () {
        final rate = service.calculateCollectionRate(
          revenue: 10000,
          collections: 7500,
        );
        expect(rate, 75.0);
      });

      test('should return 0 when revenue is 0', () {
        final rate = service.calculateCollectionRate(
          revenue: 0,
          collections: 0,
        );
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
