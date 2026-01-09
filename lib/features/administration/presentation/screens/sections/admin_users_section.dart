import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'widgets/user_section_header.dart';
import 'widgets/user_filters_bar.dart';
import 'widgets/user_list_item.dart';
import 'widgets/user_empty_state.dart';
import 'widgets/user_action_handlers.dart';

/// Section pour gérer les utilisateurs.
class AdminUsersSection extends ConsumerStatefulWidget {
  const AdminUsersSection({super.key});

  @override
  ConsumerState<AdminUsersSection> createState() => _AdminUsersSectionState();
}

class _AdminUsersSectionState extends ConsumerState<AdminUsersSection> {
  final _searchController = TextEditingController();
  String? _selectedEnterpriseFilter;
  String? _selectedModuleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  UserActionHandlers get _handlers => UserActionHandlers(ref: ref, context: context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersProvider);
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: UserSectionHeader(onCreateUser: _handlers.handleCreateUser),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: UserFiltersBar(
            searchController: _searchController,
            selectedEnterpriseId: _selectedEnterpriseFilter,
            selectedModuleId: _selectedModuleFilter,
            onEnterpriseChanged: (value) {
              setState(() {
                _selectedEnterpriseFilter = value;
                _selectedModuleFilter = null;
              });
            },
            onModuleChanged: (value) {
              setState(() {
                _selectedModuleFilter = value;
              });
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        usersAsync.when(
          data: (users) {
            return enterpriseModuleUsersAsync.when(
              data: (assignments) {
                final filterService = ref.read(userFilterServiceProvider);
                final filteredUsers = filterService.filterAndSort(
                  users: users,
                  assignments: assignments,
                  searchQuery: _searchController.text,
                  enterpriseId: _selectedEnterpriseFilter,
                  moduleId: _selectedModuleFilter,
                );

                if (filteredUsers.isEmpty) {
                  return SliverToBoxAdapter(
                    child: UserEmptyState(searchQuery: _searchController.text),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = filteredUsers[index];
                      final userAssignments = assignments
                          .where((a) => a.userId == user.id)
                          .toList();

                      return UserListItem(
                        user: user,
                        userAssignments: userAssignments,
                        onEdit: () => _handlers.handleEditUser(user),
                        onAssign: () => _handlers.handleAssignEnterprise(user),
                        onToggle: () => _handlers.handleToggleStatus(user),
                        onDelete: () => _handlers.handleDeleteUser(user),
                      );
                    },
                    childCount: filteredUsers.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Erreur: $error')),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Erreur de chargement', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

