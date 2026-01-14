import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/administration/application/controllers/admin_controller.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/services/audit/audit_service.dart';
import 'package:elyf_groupe_app/features/administration/data/services/firestore_sync_service.dart';
import 'package:elyf_groupe_app/features/administration/domain/services/validation/permission_validator_service.dart';
import 'package:elyf_groupe_app/core/permissions/entities/user_role.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import 'admin_controller_test.mocks.dart';

@GenerateMocks([
  AdminRepository,
  AuditService,
  FirestoreSyncService,
  PermissionValidatorService,
])
void main() {
  late AdminController controller;
  late MockAdminRepository mockRepository;
  late MockAuditService mockAuditService;
  late MockFirestoreSyncService mockFirestoreSync;
  late MockPermissionValidatorService mockPermissionValidator;

  setUp(() {
    mockRepository = MockAdminRepository();
    mockAuditService = MockAuditService();
    mockFirestoreSync = MockFirestoreSyncService();
    mockPermissionValidator = MockPermissionValidatorService();

    controller = AdminController(
      mockRepository,
      auditService: mockAuditService,
      firestoreSync: mockFirestoreSync,
      permissionValidator: mockPermissionValidator,
    );
  });

  group('AdminController', () {
    group('assignUserToEnterprise', () {
      final testUser = EnterpriseModuleUser(
        userId: 'user-1',
        enterpriseId: 'enterprise-1',
        moduleId: 'module-1',
        roleId: 'role-1',
        customPermissions: {},
      );

      test(
        'should assign user and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageUsers(userId: 'current-user'),
          ).thenAnswer((_) async => true);

          // Act
          await controller.assignUserToEnterprise(
            testUser,
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageUsers(userId: 'current-user'),
          ).called(1);
          verify(mockRepository.assignUserToEnterprise(testUser)).called(1);
          verify(
            mockFirestoreSync.syncEnterpriseModuleUserToFirestore(testUser),
          ).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              newValue: anyNamed('newValue'),
              moduleId: anyNamed('moduleId'),
              enterpriseId: anyNamed('enterpriseId'),
            ),
          ).called(1);
        },
      );

      test('should throw exception when permission denied', () async {
        // Arrange
        when(
          mockPermissionValidator.canManageUsers(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.assignUserToEnterprise(
            testUser,
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
          mockPermissionValidator.canManageUsers(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.assignUserToEnterprise(any));
      });

      test(
        'should assign user without permission check when currentUserId is null',
        () async {
          // Act
          await controller.assignUserToEnterprise(testUser);

          // Assert
          verifyNever(
            mockPermissionValidator.canManageUsers(userId: anyNamed('userId')),
          );
          verify(mockRepository.assignUserToEnterprise(testUser)).called(1);
          verify(
            mockFirestoreSync.syncEnterpriseModuleUserToFirestore(testUser),
          ).called(1);
          verify(
            mockAuditService.logAction(
              action: anyNamed('action'),
              entityType: anyNamed('entityType'),
              entityId: anyNamed('entityId'),
              userId: anyNamed('userId'),
              description: anyNamed('description'),
              newValue: anyNamed('newValue'),
              moduleId: anyNamed('moduleId'),
              enterpriseId: anyNamed('enterpriseId'),
            ),
          ).called(1);
        },
      );
    });

    group('createRole', () {
      final testRole = UserRole(
        id: 'role-1',
        name: 'Test Role',
        description: 'Test Description',
        permissions: {'permission-1'},
        isSystemRole: false,
      );

      test(
        'should create role and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).thenAnswer((_) async => true);

          // Act
          await controller.createRole(testRole, currentUserId: 'current-user');

          // Assert
          verify(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).called(1);
          verify(mockRepository.createRole(testRole)).called(1);
          verify(mockFirestoreSync.syncRoleToFirestore(testRole)).called(1);
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
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.createRole(testRole, currentUserId: 'current-user'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.createRole(any));
      });
    });

    group('updateRole', () {
      final oldRole = UserRole(
        id: 'role-1',
        name: 'Old Role',
        description: 'Old Description',
        permissions: {'permission-1'},
        isSystemRole: false,
      );

      final updatedRole = UserRole(
        id: 'role-1',
        name: 'Updated Role',
        description: 'Updated Description',
        permissions: {'permission-1', 'permission-2'},
        isSystemRole: false,
      );

      test(
        'should update role and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).thenAnswer((_) async => true);
          when(
            mockRepository.getModuleRoles(updatedRole.id),
          ).thenAnswer((_) async => [oldRole]);

          // Act
          await controller.updateRole(
            updatedRole,
            currentUserId: 'current-user',
          );

          // Assert
          verify(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).called(1);
          verify(mockRepository.getModuleRoles(updatedRole.id)).called(1);
          verify(mockRepository.updateRole(updatedRole)).called(1);
          verify(
            mockFirestoreSync.syncRoleToFirestore(updatedRole, isUpdate: true),
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
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () =>
              controller.updateRole(updatedRole, currentUserId: 'current-user'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.updateRole(any));
      });
    });

    group('deleteRole', () {
      final testRole = UserRole(
        id: 'role-1',
        name: 'Test Role',
        description: 'Test Description',
        permissions: {'permission-1'},
        isSystemRole: false,
      );

      test(
        'should delete role and log audit trail when permissions valid',
        () async {
          // Arrange
          when(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).thenAnswer((_) async => true);
          when(
            mockRepository.getAllRoles(),
          ).thenAnswer((_) async => [testRole]);

          // Act
          await controller.deleteRole('role-1', currentUserId: 'current-user');

          // Assert
          verify(
            mockPermissionValidator.canManageRoles(userId: 'current-user'),
          ).called(1);
          verify(mockRepository.deleteRole('role-1')).called(1);
          verify(
            mockFirestoreSync.deleteFromFirestore(
              collection: 'roles',
              documentId: 'role-1',
            ),
          ).called(1);
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
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => controller.deleteRole('role-1', currentUserId: 'current-user'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Permission denied'),
            ),
          ),
        );

        verify(
          mockPermissionValidator.canManageRoles(userId: 'current-user'),
        ).called(1);
        verifyNever(mockRepository.deleteRole(any));
      });
    });

    group('getEnterpriseModuleUsers', () {
      test('should return list from repository', () async {
        // Arrange
        final expectedUsers = [
          EnterpriseModuleUser(
            userId: 'user-1',
            enterpriseId: 'enterprise-1',
            moduleId: 'module-1',
            roleId: 'role-1',
            customPermissions: {},
          ),
        ];
        when(
          mockRepository.getEnterpriseModuleUsers(),
        ).thenAnswer((_) async => expectedUsers);

        // Act
        final result = await controller.getEnterpriseModuleUsers();

        // Assert
        expect(result, equals(expectedUsers));
        verify(mockRepository.getEnterpriseModuleUsers()).called(1);
      });
    });
  });
}
