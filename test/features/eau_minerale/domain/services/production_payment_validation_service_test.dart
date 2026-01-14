import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/production_payment_validation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_payment_person.dart';

void main() {
  group('ProductionPaymentValidationService', () {
    late ProductionPaymentValidationService service;

    setUp(() {
      service = ProductionPaymentValidationService();
    });

    group('validateHasPersons', () {
      test('should return true when persons list is not empty', () {
        final persons = [
          const ProductionPaymentPerson(
            name: 'John Doe',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
        ];
        expect(service.validateHasPersons(persons), true);
      });

      test('should return false when persons list is empty', () {
        expect(service.validateHasPersons([]), false);
      });
    });

    group('validateAllPersonNames', () {
      test('should return true when all persons have valid names', () {
        final persons = [
          const ProductionPaymentPerson(
            name: 'John Doe',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
          const ProductionPaymentPerson(
            name: 'Jane Smith',
            pricePerDay: 6000,
            daysWorked: 3,
          ),
        ];
        expect(service.validateAllPersonNames(persons), true);
      });

      test('should return false when any person has empty name', () {
        final persons = [
          const ProductionPaymentPerson(
            name: 'John Doe',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
          const ProductionPaymentPerson(
            name: '',
            pricePerDay: 6000,
            daysWorked: 3,
          ),
        ];
        expect(service.validateAllPersonNames(persons), false);
      });
    });

    group('validateAllPersonAmountsAndDays', () {
      test(
        'should return true when all persons have valid amounts and days',
        () {
          final persons = [
            const ProductionPaymentPerson(
              name: 'John Doe',
              pricePerDay: 5000,
              daysWorked: 5,
            ),
          ];
          expect(service.validateAllPersonAmountsAndDays(persons), true);
        },
      );

      test(
        'should return false when any person has invalid amount or days',
        () {
          final persons = [
            const ProductionPaymentPerson(
              name: 'John Doe',
              pricePerDay: 0,
              daysWorked: 5,
            ),
          ];
          expect(service.validateAllPersonAmountsAndDays(persons), false);
        },
      );
    });

    group('getPersonsValidationError', () {
      test('should return error when no persons', () {
        final error = service.getPersonsValidationError([]);
        expect(error, 'Ajoutez au moins une personne à payer');
      });

      test('should return error when names are empty', () {
        final persons = [
          const ProductionPaymentPerson(
            name: '',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
        ];
        final error = service.getPersonsValidationError(persons);
        expect(error, 'Tous les noms doivent être remplis');
      });

      test('should return error when amounts or days are invalid', () {
        final persons = [
          const ProductionPaymentPerson(
            name: 'John Doe',
            pricePerDay: 0,
            daysWorked: 5,
          ),
        ];
        final error = service.getPersonsValidationError(persons);
        expect(error, 'Vérifiez les montants et jours');
      });

      test('should return null when all validations pass', () {
        final persons = [
          const ProductionPaymentPerson(
            name: 'John Doe',
            pricePerDay: 5000,
            daysWorked: 5,
          ),
        ];
        final error = service.getPersonsValidationError(persons);
        expect(error, null);
      });
    });
  });
}
