import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../../../shared/utils/responsive_helper.dart';
import 'widgets/user_filters_bar.dart';
import 'widgets/user_list_item.dart';
import 'widgets/user_empty_state.dart';
import 'widgets/user_action_handlers.dart';
import '../../widgets/admin_shimmers.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart'
    show currentUserIdProvider;
import 'package:elyf_groupe_app/core.dart';
import 'widgets/role_list_item.dart';
import 'dialogs/create_role_dialog.dart';
import 'dialogs/edit_role_dialog.dart';
import '../../../../../shared/utils/notification_service.dart';
import '../../../domain/entities/user.dart';

/// Section fusionnée pour gérer les utilisateurs et les rôles
class AdminAccessSection extends ConsumerStatefulWidget {
  const AdminAccessSection({super.key});

  @override
  ConsumerState<AdminAccessSection> createState() =>
      _AdminAccessSectionState();
}

class _AdminAccessSectionState extends ConsumerState<AdminAccessSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _selectedEnterpriseFilter;
  String? _selectedModuleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  UserActionHandlers get _handlers =>
      UserActionHandlers(ref: ref, context: context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      children: [
        // Premium Header avec TabBar intégrée
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.secondary.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Formes décoratives
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -10,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gestion des Accès',
                                      style: (isMobile
                                              ? theme.textTheme.headlineSmall
                                              : theme.textTheme.headlineMedium)
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Utilisateurs, Rôles & Permissions',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tabs avec style "Barre flottante"
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Utilisateurs'),
                            Tab(text: 'Rôles'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersView(),
              _buildRolesView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersView() {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersProvider);
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveHelper.adaptivePadding(context),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Liste des Utilisateurs',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Gérez les accès et les permissions de votre équipe',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _handlers.handleCreateUser,
                      icon: const Icon(Icons.person_add_rounded, size: 20),
                      label: Text(ResponsiveHelper.isMobile(context)
                          ? 'Créer'
                          : 'Nouvel utilisateur'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                _buildUserStats(usersAsync.value ?? []),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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
                  excludeUserId: currentUserId,
                );

                if (filteredUsers.isEmpty) {
                  return SliverFillRemaining(
                    child: UserEmptyState(searchQuery: _searchController.text),
                  );
                }

                return SliverPadding(
                  padding: ResponsiveHelper.adaptivePadding(context),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final user = filteredUsers[index];
                      final userAssignments = assignments
                          .where((a) => a.userId == user.id)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UserListItem(
                          user: user,
                          userAssignments: userAssignments,
                          onEdit: () => _handlers.handleEditUser(user),
                          onAssign: () =>
                              _handlers.handleAssignEnterprise(user),
                          onToggle: () => _handlers.handleToggleStatus(user),
                          onDelete: () => _handlers.handleDeleteUser(user),
                        ),
                      );
                    }, childCount: filteredUsers.length),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: AdminShimmers.enterpriseListShimmer(context),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Erreur: $error')),
              ),
            );
          },
          loading: () => SliverToBoxAdapter(
            child: AdminShimmers.enterpriseListShimmer(context),
          ),
          error: (error, stack) => SliverFillRemaining(
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

  Widget _buildRolesView() {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(rolesProvider);
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);

    return rolesAsync.when(
      data: (roles) {
        return enterpriseModuleUsersAsync.when(
          data: (assignments) {
            final statsService = ref.read(roleStatisticsServiceProvider);
            final usersByRole = statsService.countUsersByRole(
              roles: roles,
              assignments: assignments,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsiveHelper.adaptivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rôles & Permissions',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _handleCreateRole(context, ref),
                              icon: const Icon(Icons.add),
                              label: Text(ResponsiveHelper.isMobile(context)
                                  ? 'Créer'
                                  : 'Nouveau rôle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Définissez les rôles et leurs permissions associées',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (roles.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun rôle',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez votre premier rôle',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _handleCreateRole(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer un rôle'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: ResponsiveHelper.adaptivePadding(context),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final role = roles[index];
                        final userCount = usersByRole[role.id] ?? 0;

                        return RoleListItem(
                          role: role,
                          userCount: userCount,
                          onEdit: () => _handleEditRole(context, ref, role),
                          onDelete: () => _handleDeleteRole(context, ref, role),
                        );
                      }, childCount: roles.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
          loading: () => AdminShimmers.enterpriseListShimmer(context),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        );
      },
      loading: () => AdminShimmers.enterpriseListShimmer(context),
      error: (error, stack) => Center(
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
    );
  }

  Future<void> _handleCreateRole(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => const CreateRoleDialog(),
    );

    if (result != null) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        NotificationService.showSuccess(context, 'Rôle créé avec succès');
      }
    }
  }

  Future<void> _handleEditRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => EditRoleDialog(role: role),
    );

    if (result != null) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        NotificationService.showSuccess(context, 'Rôle modifié avec succès');
      }
    }
  }

  Future<void> _handleDeleteRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    if (role.isSystemRole) {
      NotificationService.showInfo(
        context,
        'Les rôles système ne peuvent pas être supprimés',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${role.name}" ?'),
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

    if (confirmed == true) {
      try {
        final currentUserId = ref.read(currentUserIdProvider);

        await ref
            .read(adminControllerProvider)
            .deleteRole(role.id, currentUserId: currentUserId, roleData: role);

        await Future.delayed(const Duration(milliseconds: 100));
        ref.invalidate(rolesProvider);

        if (context.mounted) {
          NotificationService.showSuccess(context, 'Rôle supprimé');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }
  Widget _buildUserStats(List<User> users) {
    if (users.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final activeCount = users.where((u) => u.isActive).length;
    
    return Row(
      children: [
        _buildStatItem(
          theme,
          'Total',
          users.length.toString(),
          Icons.people_alt_rounded,
          theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          theme,
          'Actifs',
          activeCount.toString(),
          Icons.check_circle_rounded,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          theme,
          'Inactifs',
          (users.length - activeCount).toString(),
          Icons.block_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
