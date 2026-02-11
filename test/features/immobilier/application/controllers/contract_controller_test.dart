import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/contract_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/contract_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/property_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/contract.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import '../../../../helpers/test_helpers.dart';

import 'contract_controller_test.mocks.dart';

import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';

class MockAuditTrailService extends Mock implements AuditTrailService {
  @override
  Future<String> logAction({
    required String? enterpriseId,
    required String? userId,
    required String? module,
    required String? action,
    required String? entityId,
    required String? entityType,
    Map<String, dynamic>? metadata,
  }) =>
      super.noSuchMethod(
        Invocation.method(#logAction, [], {
          #enterpriseId: enterpriseId,
          #userId: userId,
          #module: module,
          #action: action,
          #entityId: entityId,
          #entityType: entityType,
          #metadata: metadata,
        }),
        returnValue: Future.value('test-log-id'),
      );
}

@GenerateMocks([
  ContractRepository,
  PropertyRepository,
  ImmobilierValidationService
])
void main() {
  late ContractController controller;
  late MockContractRepository mockContractRepository;
  late MockPropertyRepository mockPropertyRepository;
  late MockImmobilierValidationService mockValidationService;
  late MockAuditTrailService mockAuditService;

  setUp(() {
    mockContractRepository = MockContractRepository();
    mockPropertyRepository = MockPropertyRepository();
    mockValidationService = MockImmobilierValidationService();
    mockAuditService = MockAuditTrailService();
    controller = ContractController(
      mockContractRepository,
      mockPropertyRepository,
      mockValidationService,
      mockAuditService,
      'test-enterprise',
      'test-user',
    );
  });

  group('ContractController', () {
    group('createContract', () {
      test('should create contract and update property status when active', () async {
        // Arrange
        final property = createTestProperty(
          id: 'property-1',
          status: PropertyStatus.available,
        );
        final contract = createTestContract(
          id: 'contract-1',
          propertyId: 'property-1',
          status: ContractStatus.active,
        );
        when(mockValidationService.validateContractCreation(any))
            .thenAnswer((_) async => null);
        when(mockContractRepository.createContract(any))
            .thenAnswer((_) async => contract);
        when(mockPropertyRepository.getPropertyById('property-1'))
            .thenAnswer((_) async => property);
        when(mockPropertyRepository.updateProperty(any))
            .thenAnswer((_) async => property);

        // Act
        final result = await controller.createContract(contract);

        // Assert
        expect(result, equals(contract));
        verify(mockValidationService.validateContractCreation(contract)).called(1);
        verify(mockContractRepository.createContract(contract)).called(1);
        verify(mockPropertyRepository.updateProperty(any)).called(1);
      });
    });
  });
}
