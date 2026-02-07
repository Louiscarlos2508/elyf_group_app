import '../../../domain/entities/user.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';

/// Service for filtering users.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class UserFilterService {
  UserFilterService();

  /// Filters users by search query.
  ///
  /// Searches in firstName, lastName, username, and email.
  List<User> filterBySearch({
    required List<User> users,
    required String searchQuery,
  }) {
    if (searchQuery.isEmpty) {
      return users;
    }

    final lowerQuery = searchQuery.toLowerCase();
    return users.where((user) {
      return user.firstName.toLowerCase().contains(lowerQuery) ||
          user.lastName.toLowerCase().contains(lowerQuery) ||
          user.username.toLowerCase().contains(lowerQuery) ||
          (user.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filters users by enterprise and module assignments.
  ///
  /// Returns only users that have assignments matching the filters.
  List<User> filterByEnterpriseAndModule({
    required List<User> users,
    required List<EnterpriseModuleUser> assignments,
    String? enterpriseId,
    String? moduleId,
  }) {
    if (enterpriseId == null && moduleId == null) {
      return users;
    }

    final filteredAssignments = assignments.where((a) {
      if (enterpriseId != null && a.enterpriseId != enterpriseId) {
        return false;
      }
      if (moduleId != null && a.moduleId != moduleId) {
        return false;
      }
      return true;
    }).toList();

    final userIds = filteredAssignments.map((a) => a.userId).toSet();
    return users.where((u) => userIds.contains(u.id)).toList();
  }

  /// Filters and sorts users.
  ///
  /// Combines search and enterprise/module filtering.
  /// Excludes the current logged-in user from the results.
  List<User> filterAndSort({
    required List<User> users,
    required List<EnterpriseModuleUser> assignments,
    String? searchQuery,
    String? enterpriseId,
    String? moduleId,
    String? excludeUserId,
    List<String>? excludedUsernames,
  }) {
    var filtered = users;

    // Exclude current user
    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      filtered = filtered.where((user) => user.id != excludeUserId).toList();
    }

    // Exclude by username (e.g., 'admin') - Case insensitive
    if (excludedUsernames != null && excludedUsernames.isNotEmpty) {
      final lowercaseExcluded =
          excludedUsernames.map((u) => u.toLowerCase()).toSet();
      filtered = filtered
          .where((user) =>
              !lowercaseExcluded.contains(user.username.toLowerCase()))
          .toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filterBySearch(users: filtered, searchQuery: searchQuery);
    }

    // Apply enterprise/module filter
    filtered = filterByEnterpriseAndModule(
      users: filtered,
      assignments: assignments,
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    // Sort by full name
    filtered.sort((a, b) => a.fullName.compareTo(b.fullName));

    return filtered;
  }
}
