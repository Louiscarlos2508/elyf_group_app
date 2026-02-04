import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/administration/domain/services/real_permission_service.dart';
import 'package:elyf_groupe_app/features/administration/application/controllers/admin_controller.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mock_factories.dart';

import 'real_permission_service_test.mocks.dart';

@GenerateMocks([AdminController])
void main() {
  late RealPermissionService service;
  late MockAdminController mockAdminController;
  String? activeEnterpriseId;

  setUp(() {
    mockAdminController = MockAdminController();
    activeEnterpriseId = TestIds.enterprise1;
    service = RealPermissionService(
      adminController: mockAdminController,
      getActiveEnterpriseId: () => activeEnterpriseId,
    );
  });

  group('RealPermissionService', () {
    group('hasPermission', () {
      test('should return true when role has permission', () async {
        // Arrange
        final role = createTestUserRole(
          id: 'role-1',
          permissions: {'read', 'write'},
        );
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return true when role has wildcard permission', () async {
        // Arrange
        final role = createAdminRole(id: 'role-1');
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'any-permission',
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return true when custom permission exists', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1', permissions: {'read'});
        final access = createTestEnterpriseModuleUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
          customPermissions: {'custom-permission'},
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'custom-permission',
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false when permission denied', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1', permissions: {'read'});
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'write',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false when user is inactive', () async {
        // Arrange
        final access = createInactiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false when enterprise not found', () async {
        // Arrange
        activeEnterpriseId = null;

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          any,
          any,
        ));
      });

      test('should return false when user access not found', () async {
        // Arrange
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => []);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false when role not found (fail-safe)', () async {
        // Arrange
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'non-existent-role',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => []);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('getUserRole', () {
      test('should return role when found', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1');
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.getUserRole(TestIds.userId1, TestIds.moduleGaz);

        // Assert
        expect(result, equals(role));
      });

      test('should return null when user access not found', () async {
        // Arrange
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => []);

        // Act
        final result = await service.getUserRole(TestIds.userId1, TestIds.moduleGaz);

        // Assert
        expect(result, isNull);
      });
    });

    group('getUserPermissions', () {
      test('should return permissions from role and custom permissions', () async {
        // Arrange
        final role = createTestUserRole(
          id: 'role-1',
          permissions: {'read', 'write'},
        );
        final access = createTestEnterpriseModuleUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
          customPermissions: {'custom-permission'},
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.getUserPermissions(
          TestIds.userId1,
          TestIds.moduleGaz,
        );

        // Assert
        expect(result, containsAll({'read', 'write', 'custom-permission'}));
      });
    });

    group('hasAnyPermission', () {
      test('should return true when user has any of the permissions', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1', permissions: {'read'});
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasAnyPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          {'read', 'write'},
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user has none of the permissions', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1', permissions: {'other'});
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasAnyPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          {'read', 'write'},
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('hasAllPermissions', () {
      test('should return true when user has all permissions', () async {
        // Arrange
        final role = createTestUserRole(
          id: 'role-1',
          permissions: {'read', 'write'},
        );
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasAllPermissions(
          TestIds.userId1,
          TestIds.moduleGaz,
          {'read', 'write'},
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user missing some permissions', () async {
        // Arrange
        final role = createTestUserRole(id: 'role-1', permissions: {'read'});
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise1,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [role]);

        // Act
        final result = await service.hasAllPermissions(
          TestIds.userId1,
          TestIds.moduleGaz,
          {'read', 'write'},
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('multi-tenant', () {
      test('should filter by active enterprise', () async {
        // Arrange
        activeEnterpriseId = TestIds.enterprise2;
        final access = createActiveUser(
          userId: TestIds.userId1,
          enterpriseId: TestIds.enterprise2,
          moduleId: TestIds.moduleGaz,
          roleId: 'role-1',
        );
        when(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise2,
          TestIds.moduleGaz,
        )).thenAnswer((_) async => [access]);
        when(mockAdminController.getAllRoles()).thenAnswer((_) async => [
          createTestUserRole(id: 'role-1', permissions: {'read'}),
        ]);

        // Act
        final result = await service.hasPermission(
          TestIds.userId1,
          TestIds.moduleGaz,
          'read',
        );

        // Assert
        expect(result, isTrue);
        verify(mockAdminController.getEnterpriseModuleUsersByEnterpriseAndModule(
          TestIds.enterprise2,
          TestIds.moduleGaz,
        )).called(1);
      });
    });
  });
}
