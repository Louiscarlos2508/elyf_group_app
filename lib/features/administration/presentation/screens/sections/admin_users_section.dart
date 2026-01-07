import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/user.dart';
import '../../../../../core.dart';
import 'dialogs/create_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/assign_enterprise_dialog.dart';
import 'dialogs/manage_permissions_dialog.dart';
import '../../../../shared.dart';

/// Section pour gérer les utilisateurs.
class AdminUsersSection extends ConsumerStatefulWidget {
  const AdminUsersSection({super.key});

  @override
  ConsumerState<AdminUsersSection> createState() =>
      _AdminUsersSectionState();
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
        await ref.read(userRepositoryProvider).createUser(result);
        ref.invalidate(usersProvider);
        if (mounted) {
          NotificationService.showSuccess(context, 'Utilisateur créé avec succès');
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
        await ref.read(userRepositoryProvider).updateUser(result);
        ref.invalidate(usersProvider);
        if (mounted) {
          NotificationService.showSuccess(context, 'Utilisateur modifié avec succès');
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleAssignEnterprise(User user) async {
    final result = await showDialog<EnterpriseModuleUser>(
      context: context,
      builder: (context) => AssignEnterpriseDialog(user: user),
    );

    if (result != null && mounted) {
      ref.invalidate(enterpriseModuleUsersProvider);
      ref.invalidate(userEnterpriseModuleUsersProvider(result.userId));
    }
  }

  Future<void> _handleDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.fullName} ?',
        ),
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
        await ref.read(userRepositoryProvider).deleteUser(user.id);
        ref.invalidate(usersProvider);
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
          .read(userRepositoryProvider)
          .toggleUserStatus(user.id, !user.isActive);
      ref.invalidate(usersProvider);
      if (mounted) {
        NotificationService.showInfo(context, 
              user.isActive
                  ? 'Utilisateur désactivé'
                  : 'Utilisateur activé',
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
    final enterpriseModuleUsersAsync =
        ref.watch(enterpriseModuleUsersProvider);
    final enterprisesAsync = ref.watch(enterprisesProvider);
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Utilisateurs',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez les utilisateurs et leurs accès aux différents modules',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: _handleCreateUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter un utilisateur'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Rechercher',
                      hintText: 'Nom, prénom, username...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                enterprisesAsync.when(
                  data: (enterprises) {
                    if (enterprises.isEmpty) return const SizedBox.shrink();
                    return Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180, maxWidth: 250),
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedEnterpriseFilter,
                          decoration: const InputDecoration(
                            labelText: 'Entreprise',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Toutes'),
                            ),
                            ...enterprises.map((e) => DropdownMenuItem<String?>(
                                  value: e.id,
                                  child: Text(
                                    e.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEnterpriseFilter = value;
                              _selectedModuleFilter = null;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        usersAsync.when(
          data: (users) {
            final searchQuery = _searchController.text.toLowerCase();
            var filteredUsers = users.where((user) {
              if (searchQuery.isNotEmpty) {
                final matchesSearch = user.firstName
                        .toLowerCase()
                        .contains(searchQuery) ||
                    user.lastName.toLowerCase().contains(searchQuery) ||
                    user.username.toLowerCase().contains(searchQuery) ||
                    (user.email?.toLowerCase().contains(searchQuery) ?? false);
                if (!matchesSearch) return false;
              }
              return true;
            }).toList();

            return enterpriseModuleUsersAsync.when(
              data: (assignments) {
                // Filtrer par entreprise si sélectionné
                if (_selectedEnterpriseFilter != null) {
                  final userIds = assignments
                      .where((a) =>
                          a.enterpriseId == _selectedEnterpriseFilter &&
                          (_selectedModuleFilter == null ||
                              a.moduleId == _selectedModuleFilter))
                      .map((a) => a.userId)
                      .toSet();
                  filteredUsers = filteredUsers
                      .where((u) => userIds.contains(u.id))
                      .toList();
                }

                if (filteredUsers.isEmpty) {
                  return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
                      child: Center(
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
                              searchQuery.isNotEmpty
                                  ? 'Aucun résultat pour "$searchQuery"'
                                  : 'Créez votre premier utilisateur',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = filteredUsers[index];
                      final userAssignments = assignments
                          .where((a) => a.userId == user.id)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Card(
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(
                                user.firstName[0].toUpperCase(),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${user.username}'),
                                if (user.email != null) Text(user.email!),
                                if (userAssignments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: userAssignments
                                        .take(3)
                                        .map((a) => Chip(
                                              label: Text(
                                                '${a.enterpriseId} - ${a.moduleId}',
                                                style: theme.textTheme.labelSmall,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ))
                                        .toList(),
                                  ),
                                  if (userAssignments.length > 3)
                                    Text(
                                      '+${userAssignments.length - 3} autres',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!user.isActive)
                                  Chip(
                                    label: const Text('Inactif'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.grey,
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _handleEditUser(user);
                                        break;
                                      case 'assign':
                                        _handleAssignEnterprise(user);
                                        break;
                                      case 'toggle':
                                        _handleToggleStatus(user);
                                        break;
                                      case 'delete':
                                        _handleDeleteUser(user);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Modifier'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'assign',
                                      child: Row(
                                        children: [
                                          Icon(Icons.business, size: 20),
                                          SizedBox(width: 8),
                                          Text('Attribuer entreprise'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            user.isActive
                                                ? Icons.block
                                                : Icons.check_circle,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.isActive
                                                ? 'Désactiver'
                                                : 'Activer',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: userAssignments.map((assignment) {
                              return ListTile(
                                title: Text(
                                  '${assignment.enterpriseId} - ${assignment.moduleId}',
                                ),
                                subtitle: Text('Rôle: ${assignment.roleId}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: () async {
                                    final result = await showDialog<Set<String>>(
                                      context: context,
                                      builder: (context) =>
                                          ManagePermissionsDialog(
                                        enterpriseModuleUser: assignment,
                                      ),
                                    );
                                    if (result != null) {
                                      ref.invalidate(enterpriseModuleUsersProvider);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
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
