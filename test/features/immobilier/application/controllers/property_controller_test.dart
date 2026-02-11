import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/property_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/property_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import '../../../../helpers/test_helpers.dart';

import 'property_controller_test.mocks.dart';

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

@GenerateMocks([PropertyRepository, ImmobilierValidationService])
void main() {
  late PropertyController controller;
  late MockPropertyRepository mockRepository;
  late MockImmobilierValidationService mockValidationService;
  late MockAuditTrailService mockAuditService;

  setUp(() {
    mockRepository = MockPropertyRepository();
    mockValidationService = MockImmobilierValidationService();
    mockAuditService = MockAuditTrailService();
    controller = PropertyController(
      mockRepository,
      mockValidationService,
      mockAuditService,
      'test-enterprise',
      'test-user',
    );
  });

  group('PropertyController', () {
    group('fetchProperties', () {
      test('should return list of properties from repository', () async {
        // Arrange
        final properties = [
          createTestProperty(id: 'property-1'),
          createTestProperty(id: 'property-2'),
        ];
        when(mockRepository.getAllProperties()).thenAnswer((_) async => properties);

        // Act
        final result = await controller.fetchProperties();

        // Assert
        expect(result, equals(properties));
        verify(mockRepository.getAllProperties()).called(1);
      });
    });

    group('getProperty', () {
      test('should return property when found', () async {
        // Arrange
        final property = createTestProperty(id: 'property-1');
        when(mockRepository.getPropertyById('property-1'))
            .thenAnswer((_) async => property);

        // Act
        final result = await controller.getProperty('property-1');

        // Assert
        expect(result, equals(property));
        verify(mockRepository.getPropertyById('property-1')).called(1);
      });
    });

    group('createProperty', () {
      test('should create property via repository', () async {
        // Arrange
        final property = createTestProperty(id: 'property-1');
        when(mockRepository.createProperty(any)).thenAnswer((_) async => property);

        // Act
        final result = await controller.createProperty(property);

        // Assert
        expect(result, equals(property));
        verify(mockRepository.createProperty(property)).called(1);
      });
    });

    group('updateProperty', () {
      test('should update property when status unchanged', () async {
        // Arrange
        final property = createTestProperty(id: 'property-1');
        when(mockRepository.getPropertyById('property-1'))
            .thenAnswer((_) async => property);
        when(mockRepository.updateProperty(any)).thenAnswer((_) async => property);

        // Act
        final result = await controller.updateProperty(property);

        // Assert
        expect(result, equals(property));
        verify(mockRepository.getPropertyById('property-1')).called(1);
        verify(mockRepository.updateProperty(property)).called(1);
        verifyNever(mockValidationService.validatePropertyStatusUpdate(any, any));
      });

      test('should validate status change when status changed', () async {
        // Arrange
        final oldProperty = createTestProperty(
          id: 'property-1',
          status: PropertyStatus.available,
        );
        final newProperty = createTestProperty(
          id: 'property-1',
          status: PropertyStatus.rented,
        );
        when(mockRepository.getPropertyById('property-1'))
            .thenAnswer((_) async => oldProperty);
        when(mockValidationService.validatePropertyStatusUpdate(
          'property-1',
          PropertyStatus.rented,
        )).thenAnswer((_) async => null);
        when(mockRepository.updateProperty(any)).thenAnswer((_) async => newProperty);

        // Act
        final result = await controller.updateProperty(newProperty);

        // Assert
        expect(result, equals(newProperty));
        verify(mockValidationService.validatePropertyStatusUpdate(
          'property-1',
          PropertyStatus.rented,
        )).called(1);
        verify(mockRepository.updateProperty(newProperty)).called(1);
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        final oldProperty = createTestProperty(
          id: 'property-1',
          status: PropertyStatus.available,
        );
        final newProperty = createTestProperty(
          id: 'property-1',
          status: PropertyStatus.available,
        );
        when(mockRepository.getPropertyById('property-1'))
            .thenAnswer((_) async => oldProperty);
        when(mockValidationService.validatePropertyStatusUpdate(
          'property-1',
          PropertyStatus.available,
        )).thenAnswer((_) async => 'Validation error');

        // Act & Assert
        expect(
          () => controller.updateProperty(newProperty),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Validation error'),
          )),
        );
        verifyNever(mockRepository.updateProperty(any));
      });
    });

    group('deleteProperty', () {
      test('should delete property when validation passes', () async {
        // Arrange
        when(mockValidationService.validatePropertyDeletion('property-1'))
            .thenAnswer((_) async => null);
        when(mockRepository.deleteProperty('property-1'))
            .thenAnswer((_) async => {});

        // Act
        await controller.deleteProperty('property-1');

        // Assert
        verify(mockValidationService.validatePropertyDeletion('property-1')).called(1);
        verify(mockRepository.deleteProperty('property-1')).called(1);
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        when(mockValidationService.validatePropertyDeletion('property-1'))
            .thenAnswer((_) async => 'Cannot delete: active contracts');

        // Act & Assert
        expect(
          () => controller.deleteProperty('property-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot delete: active contracts'),
          )),
        );
        verifyNever(mockRepository.deleteProperty(any));
      });
    });
  });
}
