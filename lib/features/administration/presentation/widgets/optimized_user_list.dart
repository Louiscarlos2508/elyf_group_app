import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/user.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import '../../application/providers.dart' show userFilterServiceProvider;

/// Optimized user list widget with pagination and filtering.
/// 
/// Uses memoization and selective rebuilds for better performance.
class OptimizedUserList extends ConsumerStatefulWidget {
  const OptimizedUserList({
    super.key,
    required this.users,
    required this.assignments,
    required this.onUserTap,
    this.searchQuery,
    this.enterpriseId,
    this.moduleId,
  });

  final List<User> users;
  final List<EnterpriseModuleUser> assignments;
  final void Function(User) onUserTap;
  final String? searchQuery;
  final String? enterpriseId;
  final String? moduleId;

  @override
  ConsumerState<OptimizedUserList> createState() => _OptimizedUserListState();
}

class _OptimizedUserListState extends ConsumerState<OptimizedUserList> {
  final ScrollController _scrollController = ScrollController();
  int _visibleItems = 50; // Initial load
  static const int _itemsPerPage = 50;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      setState(() {
        _visibleItems += _itemsPerPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Memoize filtered users
    final filterService = ref.watch(userFilterServiceProvider);
    final filteredUsers = filterService.filterAndSort(
      users: widget.users,
      assignments: widget.assignments,
      searchQuery: widget.searchQuery,
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    );

    final displayedUsers = filteredUsers.take(_visibleItems).toList();
    final hasMore = filteredUsers.length > _visibleItems;

    if (displayedUsers.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: displayedUsers.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayedUsers.length) {
          // Loading indicator at bottom
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = displayedUsers[index];
        final userAssignments = widget.assignments
            .where((a) => a.userId == user.id)
            .toList();

        return _UserListItem(
          key: ValueKey(user.id), // Stable key for list optimization
          user: user,
          assignments: userAssignments,
          onTap: () => widget.onUserTap(user),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                  ? 'Aucun résultat pour "${widget.searchQuery}"'
                  : 'Créez votre premier utilisateur',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized user list item with const constructor where possible.
class _UserListItem extends StatelessWidget {
  const _UserListItem({
    super.key,
    required this.user,
    required this.assignments,
    required this.onTap,
  });

  final User user;
  final List<EnterpriseModuleUser> assignments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        child: ExpansionTile(
          key: ValueKey('user_${user.id}'), // Stable key
          leading: CircleAvatar(
            child: Text(user.firstName[0].toUpperCase()),
          ),
          title: Text(
            user.fullName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: _UserListItemSubtitle(
            user: user,
            assignments: assignments,
          ),
          trailing: _UserListItemTrailing(
            user: user,
            onTap: onTap,
          ),
          children: assignments.map((assignment) {
            return ListTile(
              title: Text('${assignment.enterpriseId} - ${assignment.moduleId}'),
              subtitle: Text('Rôle: ${assignment.roleId}'),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Separate widget for subtitle to enable const optimization.
class _UserListItemSubtitle extends StatelessWidget {
  const _UserListItemSubtitle({
    required this.user,
    required this.assignments,
  });

  final User user;
  final List<EnterpriseModuleUser> assignments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('@${user.username}'),
        if (user.email != null) Text(user.email!),
        if (assignments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: assignments
                .take(3)
                .map((a) => Chip(
                      label: Text(
                        '${a.enterpriseId} - ${a.moduleId}',
                        style: theme.textTheme.labelSmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          if (assignments.length > 3)
            Text(
              '+${assignments.length - 3} autres',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ],
    );
  }
}

/// Separate widget for trailing actions.
class _UserListItemTrailing extends StatelessWidget {
  const _UserListItemTrailing({
    required this.user,
    required this.onTap,
  });

  final User user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!user.isActive)
          const Chip(
            label: Text('Inactif'),
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onTap,
        ),
      ],
    );
  }
}

