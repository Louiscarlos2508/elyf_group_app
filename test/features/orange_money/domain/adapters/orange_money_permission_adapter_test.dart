import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_service.dart' hide MockPermissionService;
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/adapters/orange_money_permission_adapter.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';

// Generate Mocks
@GenerateMocks([PermissionService, AdminRepository, EnterpriseRepository])
import 'orange_money_permission_adapter_test.mocks.dart';

void main() {
  late OrangeMoneyPermissionAdapter adapter;
  late MockPermissionService mockPermissionService;
  late MockAdminRepository mockAdminRepo;
  late MockEnterpriseRepository mockEnterpriseRepo;
  const userId = 'user_123';

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockAdminRepo = MockAdminRepository();
    mockEnterpriseRepo = MockEnterpriseRepository();

    adapter = OrangeMoneyPermissionAdapter(
      permissionService: mockPermissionService,
      userId: userId,
      adminRepository: mockAdminRepo,
      enterpriseRepository: mockEnterpriseRepo,
    );
  });

  group('OrangeMoneyPermissionAdapter', () {
    test('getAccessibleEnterpriseIds returns only rootId if no view_network_dashboard permission', () async {
      // Arrange
      const rootId = 'root_ent';
      when(mockPermissionService.hasPermission(userId, 'orange_money', 'view_network_dashboard'))
          .thenAnswer((_) async => false);

      // Act
      final result = await adapter.getAccessibleEnterpriseIds(rootId);

      // Assert
      expect(result, {rootId});
    });

    test('getAccessibleEnterpriseIds returns all enterprise IDs if permission and includesChildren is true', () async {
      // Arrange
      const rootId = 'root_ent';
      
      // 1. Has permission
      when(mockPermissionService.hasPermission(userId, 'orange_money', 'view_network_dashboard'))
          .thenAnswer((_) async => true);

      // 2. User has includesChildren on root
      final moduleUser = EnterpriseModuleUser(
        userId: userId,
        enterpriseId: rootId,
        moduleId: 'orange_money',
        roleIds: ['role_admin'],
        includesChildren: true,
        createdAt: DateTime.now(),
      );

      when(mockAdminRepo.getUserEnterpriseModuleUser(userId: userId, enterpriseId: rootId, moduleId: 'orange_money'))
          .thenAnswer((_) async => moduleUser);

      // 3. Setup enterprise hierarchy
      final rootEnt = Enterprise(
          id: rootId, 
          name: 'Root', 
          type: EnterpriseType.fromId('mm_agent'), // Corrected: Using a valid type
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now(),
          ancestorIds: [],
      );
      final child1 = Enterprise(
          id: 'child_1', 
          name: 'Child 1', 
          type: EnterpriseType.fromId('mm_sub_agent'),
          parentEnterpriseId: rootId, 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now(),
          ancestorIds: [rootId],
      );
      final child2 = Enterprise(
          id: 'child_2', 
          name: 'Child 2', 
          type: EnterpriseType.fromId('mm_sub_agent'),
          parentEnterpriseId: rootId, 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now(),
          ancestorIds: [rootId],
      );
      final grandChild = Enterprise(
          id: 'grand_child', 
          name: 'Grand Child', 
          type: EnterpriseType.fromId('mm_distributor'),
          parentEnterpriseId: 'child_1', 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now(),
          ancestorIds: [rootId, 'child_1'],
      );
      final unrelated = Enterprise(
          id: 'unrelated', 
          name: 'Unrelated', 
          type: EnterpriseType.fromId('mm_agent'),
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now(),
          ancestorIds: [],
      );

      final List<Enterprise> allEnterprises = [rootEnt, child1, child2, grandChild, unrelated];

      when(mockEnterpriseRepo.getAllEnterprises())
          .thenAnswer((_) async => allEnterprises);

      // Act
      final result = await adapter.getAccessibleEnterpriseIds(rootId);

      // Assert
      expect(result.length, 4);
      expect(result, contains(rootId));
      expect(result, contains('child_1'));
      expect(result, contains('child_2'));
      expect(result, contains('grand_child'));
      expect(result, isNot(contains('unrelated')));
    });

     test('getAccessibleEnterpriseIds returns only rootId if permission but includesChildren is false', () async {
      // Arrange
      const rootId = 'root_ent';
      
      // 1. Has permission (global role might allow, but specific association matters)
      when(mockPermissionService.hasPermission(userId, 'orange_money', 'view_network_dashboard'))
          .thenAnswer((_) async => true);

      // 2. User has includesChildren = FALSE on root
      final moduleUser = EnterpriseModuleUser(
        userId: userId,
        enterpriseId: rootId,
        moduleId: 'orange_money',
        roleIds: ['role_agent'],
        includesChildren: false, // Key difference
        createdAt: DateTime.now(),
      );

      when(mockAdminRepo.getUserEnterpriseModuleUser(userId: userId, enterpriseId: rootId, moduleId: 'orange_money'))
          .thenAnswer((_) async => moduleUser);

      // Act
      final result = await adapter.getAccessibleEnterpriseIds(rootId);

      // Assert
      expect(result, {rootId});
      verifyNever(mockEnterpriseRepo.getAllEnterprises());
    });
  });
}
