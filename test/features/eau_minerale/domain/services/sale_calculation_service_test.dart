import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/sale_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';

void main() {
  group('SaleCalculationService', () {
    group('calculateTotalPrice', () {
      test('should calculate total price correctly', () {
        final total = SaleCalculationService.calculateTotalPrice(
          unitPrice: 500,
          quantity: 10,
        );
        expect(total, 5000);
      });

      test('should return null for null unitPrice', () {
        final total = SaleCalculationService.calculateTotalPrice(
          unitPrice: null,
          quantity: 10,
        );
        expect(total, isNull);
      });

      test('should return null for null quantity', () {
        final total = SaleCalculationService.calculateTotalPrice(
          unitPrice: 500,
          quantity: null,
        );
        expect(total, isNull);
      });

      test('should return 0 for zero quantity', () {
        final total = SaleCalculationService.calculateTotalPrice(
          unitPrice: 500,
          quantity: 0,
        );
        expect(total, 0);
      });
    });

    group('calculateTotalPriceFromProduct', () {
      test('should calculate total price from product correctly', () {
        const product = Product(
          id: '1',
          name: 'Eau 500ml',
          unitPrice: 500,
          unit: 'bouteille',
          type: ProductType.finishedGood,
        );

        final total = SaleCalculationService.calculateTotalPriceFromProduct(
          product: product,
          quantity: 10,
        );
        expect(total, 5000);
      });

      test('should return null for null product', () {
        final total = SaleCalculationService.calculateTotalPriceFromProduct(
          product: null,
          quantity: 10,
        );
        expect(total, isNull);
      });
    });

    group('calculateRemainingCredit', () {
      test('should calculate remaining credit correctly', () {
        final remaining = SaleCalculationService.calculateRemainingCredit(
          totalPrice: 10000,
          amountPaid: 6000,
        );
        expect(remaining, 4000);
      });

      test('should return 0 when fully paid', () {
        final remaining = SaleCalculationService.calculateRemainingCredit(
          totalPrice: 10000,
          amountPaid: 10000,
        );
        expect(remaining, 0);
      });

      test('should return 0 when overpaid', () {
        final remaining = SaleCalculationService.calculateRemainingCredit(
          totalPrice: 10000,
          amountPaid: 15000,
        );
        expect(remaining, 0);
      });
    });

    group('isFullyPaid', () {
      test('should return true when fully paid', () {
        final result = SaleCalculationService.isFullyPaid(
          totalPrice: 10000,
          amountPaid: 10000,
        );
        expect(result, true);
      });

      test('should return true when overpaid', () {
        final result = SaleCalculationService.isFullyPaid(
          totalPrice: 10000,
          amountPaid: 15000,
        );
        expect(result, true);
      });

      test('should return false when partially paid', () {
        final result = SaleCalculationService.isFullyPaid(
          totalPrice: 10000,
          amountPaid: 5000,
        );
        expect(result, false);
      });
    });

    group('hasCredit', () {
      test('should return true when partially paid', () {
        final result = SaleCalculationService.hasCredit(
          totalPrice: 10000,
          amountPaid: 5000,
        );
        expect(result, true);
      });

      test('should return false when fully paid', () {
        final result = SaleCalculationService.hasCredit(
          totalPrice: 10000,
          amountPaid: 10000,
        );
        expect(result, false);
      });
    });

    group('validateAmountPaid', () {
      test('should return null for valid amount', () {
        final result = SaleCalculationService.validateAmountPaid(
          amountPaid: 5000,
          totalPrice: 10000,
        );
        expect(result, isNull);
      });

      test('should return error for null amount', () {
        final result = SaleCalculationService.validateAmountPaid(
          amountPaid: null,
          totalPrice: 10000,
        );
        expect(result, isNotNull);
      });

      test('should return error for negative amount', () {
        final result = SaleCalculationService.validateAmountPaid(
          amountPaid: -1000,
          totalPrice: 10000,
        );
        expect(result, isNotNull);
        expect(result, contains('négatif'));
      });

      test('should return error for amount exceeding total', () {
        final result = SaleCalculationService.validateAmountPaid(
          amountPaid: 15000,
          totalPrice: 10000,
        );
        expect(result, isNotNull);
        expect(result, contains('dépasser'));
      });
    });

    group('getUnitPrice', () {
      test('should return unit price from product', () {
        const product = Product(
          id: '1',
          name: 'Eau 500ml',
          unitPrice: 500,
          unit: 'bouteille',
          type: ProductType.finishedGood,
        );

        final unitPrice = SaleCalculationService.getUnitPrice(product);
        expect(unitPrice, 500);
      });

      test('should return null for null product', () {
        final unitPrice = SaleCalculationService.getUnitPrice(null);
        expect(unitPrice, isNull);
      });
    });
  });
}
