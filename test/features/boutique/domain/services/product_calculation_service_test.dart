import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/product_calculation_service.dart';

void main() {
  group('ProductCalculationService', () {
    late ProductCalculationService service;

    setUp(() {
      service = ProductCalculationService();
    });

    group('calculateUnitPurchasePrice', () {
      test('should return null when stock is 0', () {
        final result = service.calculateUnitPurchasePrice(
          stockInitial: 0,
          totalPurchasePrice: 10000,
        );

        expect(result, isNull);
      });

      test('should return null when totalPurchasePrice is null', () {
        final result = service.calculateUnitPurchasePrice(
          stockInitial: 100,
          totalPurchasePrice: null,
        );

        expect(result, isNull);
      });

      test('should calculate unit price correctly', () {
        final result = service.calculateUnitPurchasePrice(
          stockInitial: 100,
          totalPurchasePrice: 10000,
        );

        expect(result, equals(100));
      });

      test('should round to nearest integer', () {
        final result = service.calculateUnitPurchasePrice(
          stockInitial: 3,
          totalPurchasePrice: 1000,
        );

        expect(result, equals(333));
      });
    });

    group('validateProduct', () {
      test('should return error when name is null', () {
        final result = service.validateProduct(
          name: null,
          price: '1000',
          stock: 10,
        );

        expect(result, equals('Le nom du produit est requis'));
      });

      test('should return error when name is empty', () {
        final result = service.validateProduct(
          name: '',
          price: '1000',
          stock: 10,
        );

        expect(result, equals('Le nom du produit est requis'));
      });

      test('should return error when name is only whitespace', () {
        final result = service.validateProduct(
          name: '   ',
          price: '1000',
          stock: 10,
        );

        expect(result, equals('Le nom du produit est requis'));
      });

      test('should return error when price is null', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: null,
          stock: 10,
        );

        expect(result, equals('Le prix de vente est requis'));
      });

      test('should return error when price is empty', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '',
          stock: 10,
        );

        expect(result, equals('Le prix de vente est requis'));
      });

      test('should return error when price is not a number', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: 'abc',
          stock: 10,
        );

        expect(result, equals('Le prix de vente doit être un nombre positif'));
      });

      test('should return error when price is negative', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '-100',
          stock: 10,
        );

        expect(result, equals('Le prix de vente doit être un nombre positif'));
      });

      test('should return error when price is zero', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '0',
          stock: 10,
        );

        expect(result, equals('Le prix de vente doit être un nombre positif'));
      });

      test('should return error when stock is negative', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '1000',
          stock: -10,
        );

        expect(result, equals('Le stock ne peut pas être négatif'));
      });

      test('should return null when product is valid', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '1000',
          stock: 10,
        );

        expect(result, isNull);
      });

      test('should return null when stock is null (optional)', () {
        final result = service.validateProduct(
          name: 'Product 1',
          price: '1000',
          stock: null,
        );

        expect(result, isNull);
      });
    });
  });
}

