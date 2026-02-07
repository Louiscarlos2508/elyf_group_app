import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../core/permissions/entities/user_role.dart';

/// Service for calculating role statistics.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class RoleStatisticsService {
  RoleStatisticsService();

  /// Counts unique users by role.
  ///
  /// Returns a map of roleId -> unique user count.
  /// A user is counted only once per role, even if assigned to multiple
  /// enterprises with the same role.
  Map<String, int> countUsersByRole({
    required List<UserRole> roles,
    required List<EnterpriseModuleUser> assignments,
  }) {
    final counts = <String, Set<String>>{};
    for (final assignment in assignments) {
      for (final roleId in assignment.roleIds) {
        counts.putIfAbsent(roleId, () => <String>{}).add(assignment.userId);
      }
    }
    return counts.map((key, value) => MapEntry(key, value.length));
  }

  /// Gets the unique user count for a specific role.
  ///
  /// A user is counted only once, even if assigned to multiple enterprises
  /// with the same role.
  int getUserCountForRole({
    required String roleId,
    required List<EnterpriseModuleUser> assignments,
  }) {
    final uniqueUsers = assignments
        .where((a) => a.roleIds.contains(roleId))
        .map((a) => a.userId)
        .toSet();
    return uniqueUsers.length;
  }
}
