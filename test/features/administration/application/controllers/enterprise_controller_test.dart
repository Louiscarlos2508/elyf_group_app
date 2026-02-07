import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:drift/native.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/user_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';

import 'package:elyf_groupe_app/features/administration/application/controllers/enterprise_controller.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/services/audit/audit_service.dart';
import 'package:elyf_groupe_app/features/administration/data/services/firestore_sync_service.dart';
import 'package:elyf_groupe_app/features/administration/domain/services/validation/permission_validator_service.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'enterprise_controller_test.mocks.dart';

@GenerateMocks([
  EnterpriseRepository,
  AuditService,
  FirestoreSyncService,
  PermissionValidatorService,
  UserRepository,
  AdminRepository,
])
void main() {
  late EnterpriseController controller;
  late MockEnterpriseRepository mockRepository;
  late MockAuditService mockAuditService;
  late MockFirestoreSyncService mockFirestoreSync;
  late MockPermissionValidatorService mockPermissionValidator;
  late MockUserRepository mockUserRepository;
  late MockAdminRepository mockAdminRepository;

  setUp(() async {
    // Initialiser DriftService pour les tests (nécessaire pour certaines méthodes du controller)
    await DriftService.instance.initialize(connection: NativeDatabase.memory());

    mockRepository = MockEnterpriseRepository();
    mockAuditService = MockAuditService();
    mockFirestoreSync = MockFirestoreSyncService();
    mockPermissionValidator = MockPermissionValidatorService();
    mockUserRepository = MockUserRepository();
    mockAdminRepository = MockAdminRepository();

    controller = EnterpriseController(
      mockRepository,
      auditService: mockAuditService,
      firestoreSync: mockFirestoreSync,
      permissionValidator: mockPermissionValidator,
      userRepository: mockUserRepository,
      adminRepository: mockAdminRepository,
    );
  });

  group('EnterpriseController', () {
    group('createEnterprise', () {
      final testEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Test Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'Test Address',
        phone: '123456789',
        email: 'test@example.com',
        isActive: true,
      );

      test(
        'should create enterprise and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).thenAnswer((_) async => true);

          // Act
          await controller.createEnterprise(
            testEnterprise,
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).called(1);
          verify(mockRepository.createEnterprise(testEnterprise)).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              newValue: anyNamed('newValue'),
            ),
          ).called(1);
        },
      );

      test('should throw exception when permission denied', () async {
        // Arrange
        when(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.createEnterprise(
            testEnterprise,
            currentUserId: 'current-user',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.createEnterprise(any));
      });

      test(
        'should create enterprise without permission check when currentUserId is null',
        () async {
          // Act
          await controller.createEnterprise(testEnterprise);

          // Assert
          verifyNever(
            mockPermissionValidator.canManageEnterprises(
              userId: anyNamed('userId'),
            ),
          );
          verify(mockRepository.createEnterprise(testEnterprise)).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              newValue: anyNamed('newValue'),
            ),
          ).called(1);
        },
      );
    });

    group('updateEnterprise', () {
      final oldEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Old Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'Old Address',
        phone: '123456789',
        email: 'old@example.com',
        isActive: true,
      );

      final updatedEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Updated Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'New Address',
        phone: '987654321',
        email: 'new@example.com',
        isActive: true,
      );

      test(
        'should update enterprise and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).thenAnswer((_) async => true);
          when(
            mockRepository.getEnterpriseById('enterprise-1'),
          ).thenAnswer((_) async => oldEnterprise);

          // Act
          await controller.updateEnterprise(
            updatedEnterprise,
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).called(1);
          verify(mockRepository.getEnterpriseById('enterprise-1')).called(1);
          verify(mockRepository.updateEnterprise(updatedEnterprise)).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              oldValue: anyNamed('oldValue'),
              newValue: anyNamed('newValue'),
            ),
          ).called(1);
        },
      );

      test('should throw exception when permission denied', () async {
        // Arrange
        when(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.updateEnterprise(
            updatedEnterprise,
            currentUserId: 'current-user',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.updateEnterprise(any));
      });
    });

    group('deleteEnterprise', () {
      final testEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Test Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'Test Address',
        phone: '123456789',
        email: 'test@example.com',
        isActive: true,
      );

      test(
        'should delete enterprise and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).thenAnswer((_) async => true);
          when(
            mockRepository.getEnterpriseById('enterprise-1'),
          ).thenAnswer((_) async => testEnterprise);

          // Act
          await controller.deleteEnterprise(
            'enterprise-1',
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).called(1);
          verify(mockRepository.getEnterpriseById('enterprise-1')).called(1);
          verify(mockRepository.deleteEnterprise('enterprise-1')).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              oldValue: anyNamed('oldValue'),
            ),
          ).called(1);
        },
      );

      test('should throw exception when permission denied', () async {
        // Arrange
        when(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.deleteEnterprise(
            'enterprise-1',
            currentUserId: 'current-user',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.deleteEnterprise(any));
      });
    });

    group('toggleEnterpriseStatus', () {
      final inactiveEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Test Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'Test Address',
        phone: '123456789',
        email: 'test@example.com',
        isActive: false,
      );

      final activeEnterprise = Enterprise(
        id: 'enterprise-1',
        name: 'Test Enterprise',
        type: EnterpriseType.waterEntity,
        address: 'Test Address',
        phone: '123456789',
        email: 'test@example.com',
        isActive: true,
      );

      test(
        'should toggle status and log audit trail when permissions valid',
        () async {
          // Arrange
          var callCount = 0;
          when(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).thenAnswer((_) async => true);
          when(mockRepository.getEnterpriseById('enterprise-1')).thenAnswer((
            _,
          ) async {
            callCount++;
            return callCount == 1 ? inactiveEnterprise : activeEnterprise;
          });
          when(
            mockRepository.toggleEnterpriseStatus('enterprise-1', true),
          ).thenAnswer((_) async => Future.value());

          // Act
          await controller.toggleEnterpriseStatus(
            'enterprise-1',
            true,
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageEnterprises(
              userId: 'current-user',
            ),
          ).called(1);
          verify(
            mockRepository.toggleEnterpriseStatus('enterprise-1', true),
          ).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              oldValue: anyNamed('oldValue'),
              newValue: anyNamed('newValue'),
            ),
          ).called(1);
        },
      );

      test('should throw exception when permission denied', () async {
        // Arrange
        when(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.toggleEnterpriseStatus(
            'enterprise-1',
            true,
            currentUserId: 'current-user',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageEnterprises(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.toggleEnterpriseStatus(any, any));
      });
    });

    group('getAllEnterprises', () {
      test('should return list from repository', () async {
        // Arrange
        final expectedEnterprises = [
          Enterprise(
            id: 'enterprise-1',
            name: 'Enterprise 1',
            type: EnterpriseType.waterEntity,
            address: 'Address 1',
            phone: '123456789',
            email: 'test1@example.com',
            isActive: true,
          ),
        ];
        when(
          mockRepository.getAllEnterprises(),
        ).thenAnswer((_) async => expectedEnterprises);

        // Act
        final result = await controller.getAllEnterprises();

        // Assert
        expect(result, equals(expectedEnterprises));
        verify(mockRepository.getAllEnterprises()).called(1);
      });
    });

    group('getEnterpriseById', () {
      test('should return enterprise from repository', () async {
        // Arrange
        final expectedEnterprise = Enterprise(
          id: 'enterprise-1',
          name: 'Test Enterprise',
          type: EnterpriseType.waterEntity,
          address: 'Test Address',
          phone: '123456789',
          email: 'test@example.com',
          isActive: true,
        );
        when(
          mockRepository.getEnterpriseById('enterprise-1'),
        ).thenAnswer((_) async => expectedEnterprise);

        // Act
        final result = await controller.getEnterpriseById('enterprise-1');

        // Assert
        expect(result, equals(expectedEnterprise));
        verify(mockRepository.getEnterpriseById('enterprise-1')).called(1);
      });
    });
  });
}
