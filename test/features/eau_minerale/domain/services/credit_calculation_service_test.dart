import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/credit_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_credit.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';

void main() {
  group('CreditCalculationService', () {
    late CreditCalculationService service;

    setUp(() {
      service = CreditCalculationService();
    });

    group('calculateTotalCredit', () {
      test('should calculate total credit correctly', () {
        final credits = [
          CustomerCredit(
            saleId: '1',
            amount: 10000,
            amountPaid: 6000,
            remainingAmount: 4000,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          CustomerCredit(
            saleId: '2',
            amount: 5000,
            amountPaid: 2000,
            remainingAmount: 3000,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ];

        final total = service.calculateTotalCredit(credits);
        expect(total, 7000);
      });

      test('should return 0 when no credits', () {
        expect(service.calculateTotalCredit([]), 0);
      });
    });

    group('calculateTotalRemainingCredit', () {
      test('should calculate total remaining credit correctly', () {
        final credits = [
          CustomerCredit(
            saleId: '1',
            amount: 10000,
            amountPaid: 6000,
            remainingAmount: 4000,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          CustomerCredit(
            saleId: '2',
            amount: 5000,
            amountPaid: 2000,
            remainingAmount: 3000,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ];

        final total = service.calculateTotalRemainingCredit(credits);
        expect(total, 7000);
      });
    });

    group('calculateTotalPaidForSale', () {
      test('should calculate total paid for a sale correctly', () {
        final sale = Sale(
          id: '1',
          productId: 'p1',
          productName: 'Product 1',
          customerId: 'c1',
          customerName: 'Customer 1',
          quantity: 10,
          totalPrice: 10000,
          amountPaid: 6000,
          date: DateTime.now(),
          paymentMethod: 'cash',
          isFullyPaid: false,
        );

        final totalPaid = service.calculateTotalPaidForSale(sale);
        expect(totalPaid, 6000);
      });
    });
  });
}

