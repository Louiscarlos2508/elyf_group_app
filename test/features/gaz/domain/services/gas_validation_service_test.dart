import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gas_validation_service.dart';

void main() {
  final testCylinder = Cylinder(
    id: 'cyl-1',
    weight: 6,
    buyPrice: 2500,
    sellPrice: 3000,
    enterpriseId: 'ent-1',
    moduleId: 'gaz',
    stock: 10,
  );

  group('GasValidationService', () {
    group('validateCylinderSelection', () {
      test('returns error when cylinder is null', () {
        final result = GasValidationService.validateCylinderSelection(null);
        expect(result, isNotNull);
        expect(result, contains('cylindre'));
      });

      test('returns null when cylinder is selected', () {
        final result =
            GasValidationService.validateCylinderSelection(testCylinder);
        expect(result, isNull);
      });
    });

    group('validateCustomerName', () {
      test('returns error when name is null', () {
        final result = GasValidationService.validateCustomerName(null);
        expect(result, isNotNull);
        expect(result, contains('nom'));
      });

      test('returns error when name is empty or whitespace', () {
        expect(
          GasValidationService.validateCustomerName(''),
          isNotNull,
        );
        expect(
          GasValidationService.validateCustomerName('   '),
          isNotNull,
        );
      });

      test('returns error when name has less than 2 characters', () {
        final result = GasValidationService.validateCustomerName('A');
        expect(result, isNotNull);
        expect(result, contains('2'));
      });

      test('returns null when name is valid', () {
        final result = GasValidationService.validateCustomerName('Jean Dupont');
        expect(result, isNull);
      });
    });

    group('validateCustomerPhone', () {
      test('returns error when phone is null or empty', () {
        expect(
          GasValidationService.validateCustomerPhone(null),
          isNotNull,
        );
        expect(
          GasValidationService.validateCustomerPhone(''),
          isNotNull,
        );
      });

      test('returns null for valid Burkina phone', () {
        final result =
            GasValidationService.validateCustomerPhone('+226 70 12 34 56');
        expect(result, isNull);
      });
    });

    group('validateStockAvailability', () {
      test('returns error when quantity exceeds available stock', () {
        final result = GasValidationService.validateStockAvailability(
          quantity: 15,
          availableStock: 10,
        );
        expect(result, isNotNull);
        expect(result, contains('10'));
      });

      test('returns null when quantity is within stock', () {
        final result = GasValidationService.validateStockAvailability(
          quantity: 5,
          availableStock: 10,
        );
        expect(result, isNull);
      });

      test('returns null when quantity equals available stock', () {
        final result = GasValidationService.validateStockAvailability(
          quantity: 10,
          availableStock: 10,
        );
        expect(result, isNull);
      });
    });

    group('validateGasSale', () {
      test('returns multiple errors when several fields are invalid', () {
        final errors = GasValidationService.validateGasSale(
          cylinder: null,
          quantity: 20,
          availableStock: 10,
          customerName: '',
          customerPhone: null,
        );
        expect(errors.length, greaterThanOrEqualTo(2));
        expect(
          errors.any((e) => e.toLowerCase().contains('cylindre')),
          isTrue,
        );
      });

      test('returns empty list when all fields are valid', () {
        final errors = GasValidationService.validateGasSale(
          cylinder: testCylinder,
          quantity: 2,
          availableStock: 10,
          customerName: 'Jean Dupont',
          customerPhone: '+22670123456',
        );
        expect(errors, isEmpty);
      });
    });
  });
}
