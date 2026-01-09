import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/sale_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';

void main() {
  group('SaleCalculationService', () {
    late SaleCalculationService service;

    setUp(() {
      service = SaleCalculationService();
    });

    group('calculateTotalPrice', () {
      test('should calculate total price correctly', () {
        const product = Product(
          id: '1',
          name: 'Eau 500ml',
          price: 500,
          unit: 'bouteille',
          type: ProductType.finished,
        );

        final total = service.calculateTotalPrice(product: product, quantity: 10);
        expect(total, 5000);
      });

      test('should return 0 for zero quantity', () {
        const product = Product(
          id: '1',
          name: 'Eau 500ml',
          price: 500,
          unit: 'bouteille',
          type: ProductType.finished,
        );

        final total = service.calculateTotalPrice(product: product, quantity: 0);
        expect(total, 0);
      });
    });

    group('calculateRemainingCredit', () {
      test('should calculate remaining credit correctly', () {
        final remaining = service.calculateRemainingCredit(
          totalPrice: 10000,
          amountPaid: 6000,
        );
        expect(remaining, 4000);
      });

      test('should return 0 when fully paid', () {
        final remaining = service.calculateRemainingCredit(
          totalPrice: 10000,
          amountPaid: 10000,
        );
        expect(remaining, 0);
      });
    });

    group('validateAmountPaid', () {
      test('should return true for valid amount', () {
        final isValid = service.validateAmountPaid(
          amountPaid: 5000,
          totalPrice: 10000,
        );
        expect(isValid, true);
      });

      test('should return false for negative amount', () {
        final isValid = service.validateAmountPaid(
          amountPaid: -1000,
          totalPrice: 10000,
        );
        expect(isValid, false);
      });

      test('should return false for amount exceeding total', () {
        final isValid = service.validateAmountPaid(
          amountPaid: 15000,
          totalPrice: 10000,
        );
        expect(isValid, false);
      });
    });
  });
}

