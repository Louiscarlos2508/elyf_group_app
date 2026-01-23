import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/tenant_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/tenant_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/tenant.dart';
import '../../../../helpers/test_helpers.dart';

import 'tenant_controller_test.mocks.dart';

@GenerateMocks([TenantRepository, ImmobilierValidationService])
void main() {
  late TenantController controller;
  late MockTenantRepository mockRepository;
  late MockImmobilierValidationService mockValidationService;

  setUp(() {
    mockRepository = MockTenantRepository();
    mockValidationService = MockImmobilierValidationService();
    controller = TenantController(mockRepository, mockValidationService);
  });

  group('TenantController', () {
    group('fetchTenants', () {
      test('should return list of tenants from repository', () async {
        // Arrange
        final tenants = [
          createTestTenant(id: 'tenant-1'),
          createTestTenant(id: 'tenant-2'),
        ];
        when(mockRepository.getAllTenants()).thenAnswer((_) async => tenants);

        // Act
        final result = await controller.fetchTenants();

        // Assert
        expect(result, equals(tenants));
        verify(mockRepository.getAllTenants()).called(1);
      });
    });

    group('searchTenants', () {
      test('should search tenants when query provided', () async {
        // Arrange
        final tenants = [createTestTenant(id: 'tenant-1', fullName: 'John Doe')];
        when(mockRepository.searchTenants('John')).thenAnswer((_) async => tenants);

        // Act
        final result = await controller.searchTenants('John');

        // Assert
        expect(result, equals(tenants));
        verify(mockRepository.searchTenants('John')).called(1);
      });

      test('should return all tenants when query is empty', () async {
        // Arrange
        final tenants = [createTestTenant(id: 'tenant-1')];
        when(mockRepository.getAllTenants()).thenAnswer((_) async => tenants);

        // Act
        final result = await controller.searchTenants('');

        // Assert
        expect(result, equals(tenants));
        verify(mockRepository.getAllTenants()).called(1);
        verifyNever(mockRepository.searchTenants(any));
      });
    });

    group('deleteTenant', () {
      test('should delete tenant when validation passes', () async {
        // Arrange
        when(mockValidationService.validateTenantDeletion('tenant-1'))
            .thenAnswer((_) async => null);
        when(mockRepository.deleteTenant('tenant-1')).thenAnswer((_) async => {});

        // Act
        await controller.deleteTenant('tenant-1');

        // Assert
        verify(mockValidationService.validateTenantDeletion('tenant-1')).called(1);
        verify(mockRepository.deleteTenant('tenant-1')).called(1);
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        when(mockValidationService.validateTenantDeletion('tenant-1'))
            .thenAnswer((_) async => 'Cannot delete: active contracts');

        // Act & Assert
        expect(
          () => controller.deleteTenant('tenant-1'),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.deleteTenant(any));
      });
    });
  });
}
