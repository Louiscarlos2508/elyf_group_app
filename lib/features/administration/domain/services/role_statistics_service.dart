import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../core/permissions/entities/user_role.dart';

/// Service for calculating role statistics.
/// 
/// Extracts business logic from UI widgets to make it testable and reusable.
class RoleStatisticsService {
  RoleStatisticsService();

  /// Counts users by role.
  /// 
  /// Returns a map of roleId -> user count.
  Map<String, int> countUsersByRole({
    required List<UserRole> roles,
    required List<EnterpriseModuleUser> assignments,
  }) {
    final counts = <String, int>{};
    for (final assignment in assignments) {
      counts[assignment.roleId] = (counts[assignment.roleId] ?? 0) + 1;
    }
    return counts;
  }

  /// Gets the user count for a specific role.
  int getUserCountForRole({
    required String roleId,
    required List<EnterpriseModuleUser> assignments,
  }) {
    return assignments.where((a) => a.roleId == roleId).length;
  }
}

