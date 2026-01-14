import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart'
    show currentUserIdProvider;
import '../../../domain/entities/user.dart';
import 'package:elyf_groupe_app/core.dart';
import 'dialogs/create_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/assign_enterprise_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import 'widgets/user_section_header.dart';
import 'widgets/user_filters_bar.dart';
import 'widgets/user_list_item.dart';
import 'widgets/user_empty_state.dart';

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

  Future<void> _handleCreateUser() async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );

    if (result != null && mounted) {
      try {
        await ref.read(userControllerProvider).createUser(result);
        ref.invalidate(usersProvider);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Utilisateur créé avec succès',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleEditUser(User user) async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result != null && mounted) {
      try {
        await ref.read(userControllerProvider).updateUser(result);
        ref.invalidate(usersProvider);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Utilisateur modifié avec succès',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleAssignEnterprise(User user) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AssignEnterpriseDialog(user: user),
    );

    if (result != null && mounted) {
      ref.invalidate(enterpriseModuleUsersProvider);
      // Si c'est un EnterpriseModuleUser (mode classique), invalider pour cet utilisateur
      if (result is EnterpriseModuleUser) {
        ref.invalidate(userEnterpriseModuleUsersProvider(result.userId));
      } else {
        // Mode batch : invalider pour l'utilisateur concerné
        ref.invalidate(userEnterpriseModuleUsersProvider(user.id));
      }
    }
  }

  Future<void> _handleDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(userControllerProvider).deleteUser(user.id);
        ref.refresh(usersProvider);
        if (mounted) {
          NotificationService.showSuccess(context, 'Utilisateur supprimé');
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleToggleStatus(User user) async {
    try {
      await ref
          .read(userControllerProvider)
          .toggleUserStatus(user.id, !user.isActive);
      ref.invalidate(usersProvider);
      if (mounted) {
        NotificationService.showInfo(
          context,
          user.isActive ? 'Utilisateur désactivé' : 'Utilisateur activé',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersProvider);
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: UserSectionHeader(onCreateUser: _handleCreateUser),
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
                final currentUserId = ref.watch(currentUserIdProvider);
                final filteredUsers = filterService.filterAndSort(
                  users: users,
                  assignments: assignments,
                  searchQuery: _searchController.text,
                  enterpriseId: _selectedEnterpriseFilter,
                  moduleId: _selectedModuleFilter,
                  excludeUserId: currentUserId,
                );

                if (filteredUsers.isEmpty) {
                  return SliverToBoxAdapter(
                    child: UserEmptyState(searchQuery: _searchController.text),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = filteredUsers[index];
                    final userAssignments = assignments
                        .where((a) => a.userId == user.id)
                        .toList();

                    return UserListItem(
                      user: user,
                      userAssignments: userAssignments,
                      onEdit: () => _handleEditUser(user),
                      onAssign: () => _handleAssignEnterprise(user),
                      onToggle: () => _handleToggleStatus(user),
                      onDelete: () => _handleDeleteUser(user),
                    );
                  }, childCount: filteredUsers.length),
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
                    Text(
                      'Erreur de chargement',
                      style: theme.textTheme.titleLarge,
                    ),
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
