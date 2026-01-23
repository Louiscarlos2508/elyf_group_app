import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/property_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/contract_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/payment_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/contract.dart';
import '../../../../helpers/test_helpers.dart';

import 'immobilier_validation_service_test.mocks.dart';

@GenerateMocks([
  PropertyRepository,
  ContractRepository,
  PaymentRepository,
])
void main() {
  late ImmobilierValidationService service;
  late MockPropertyRepository mockPropertyRepository;
  late MockContractRepository mockContractRepository;
  late MockPaymentRepository mockPaymentRepository;

  setUp(() {
    mockPropertyRepository = MockPropertyRepository();
    mockContractRepository = MockContractRepository();
    mockPaymentRepository = MockPaymentRepository();
    service = ImmobilierValidationService(
      mockPropertyRepository,
      mockContractRepository,
      mockPaymentRepository,
    );
  });

  group('ImmobilierValidationService', () {
    group('validatePropertyDeletion', () {
      test('should return null when no active contracts', () async {
        // Arrange
        when(mockContractRepository.getContractsByProperty('property-1'))
            .thenAnswer((_) async => []);

        // Act
        final result = await service.validatePropertyDeletion('property-1');

        // Assert
        expect(result, isNull);
      });

      test('should return error when active contracts exist', () async {
        // Arrange
        final contracts = [
          createTestContract(id: 'contract-1', status: ContractStatus.active),
        ];
        when(mockContractRepository.getContractsByProperty('property-1'))
            .thenAnswer((_) async => contracts);

        // Act
        final result = await service.validatePropertyDeletion('property-1');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('contrat(s) actif(s)'));
      });
    });

    group('validatePropertyStatusUpdate', () {
      test('should return error when setting to available with active contracts',
          () async {
        // Arrange
        final contracts = [
          createTestContract(id: 'contract-1', status: ContractStatus.active),
        ];
        when(mockContractRepository.getContractsByProperty('property-1'))
            .thenAnswer((_) async => contracts);

        // Act
        final result = await service.validatePropertyStatusUpdate(
          'property-1',
          PropertyStatus.available,
        );

        // Assert
        expect(result, isNotNull);
        expect(result, contains('contrat(s) actif(s)'));
      });

      test('should return null when no active contracts', () async {
        // Arrange
        when(mockContractRepository.getContractsByProperty('property-1'))
            .thenAnswer((_) async => []);

        // Act
        final result = await service.validatePropertyStatusUpdate(
          'property-1',
          PropertyStatus.available,
        );

        // Assert
        expect(result, isNull);
      });
    });
  });
}
