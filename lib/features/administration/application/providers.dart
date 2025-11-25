import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/services/permission_service.dart'
    show PermissionService, MockPermissionService;
import '../../../core/permissions/services/permission_registry.dart';
import '../data/repositories/mock_admin_repository.dart';
import '../domain/repositories/admin_repository.dart';

/// Provider for admin repository
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => MockAdminRepository(),
);

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => MockPermissionService(),
);

/// Provider for permission registry
final permissionRegistryProvider = Provider<PermissionRegistry>(
  (ref) => PermissionRegistry.instance,
);

