import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/admin_module.dart';
import '../../../../domain/entities/module_sections_info.dart';
import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import '../admin_modules_section.dart';

/// Dialogue pour afficher les détails d'un module
class ModuleDetailsDialog extends ConsumerWidget {
  const ModuleDetailsDialog({
    super.key,
    required this.module,
  });

  final AdminModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(moduleStatsProvider(module.id));
    final enterpriseModuleUsersAsync =
        ref.watch(enterpriseModuleUsersProvider);
    final usersAsync = ref.watch(usersProvider);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(module.icon),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: statsAsync.when(
                data: (stats) => enterpriseModuleUsersAsync.when(
                  data: (assignments) => usersAsync.when(
                    data: (users) => enterprisesAsync.when(
                      data: (enterprises) => _ModuleDetailsContent(
                        module: module,
                        stats: stats,
                        assignments: assignments
                            .where((a) => a.moduleId == module.id)
                            .toList(),
                        users: users,
                        enterprises: enterprises,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Erreur: $error'),
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erreur: $error'),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Erreur: $error'),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Erreur: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'home_work':
        return Icons.home_work;
      case 'storefront':
        return Icons.storefront;
      default:
        return Icons.business;
    }
  }
}

/// Contenu des détails du module
class _ModuleDetailsContent extends ConsumerWidget {
  const _ModuleDetailsContent({
    required this.module,
    required this.stats,
    required this.assignments,
    required this.users,
    required this.enterprises,
  });

  final AdminModule module;
  final ModuleStats stats;
  final List<EnterpriseModuleUser> assignments;
  final List<dynamic> users; // User list
  final List<dynamic> enterprises; // Enterprise list

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ModuleSectionsRegistry.getSectionsForModule(module.id);
    
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Sections', icon: Icon(Icons.apps_outlined)),
              const Tab(text: 'Utilisateurs', icon: Icon(Icons.people_outline)),
              const Tab(text: 'Entreprises', icon: Icon(Icons.business_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SectionsTab(sections: sections),
                _UsersTab(
                  assignments: assignments,
                  users: users,
                  enterprises: enterprises,
                ),
                _EnterprisesTab(
                  enterprises: stats.enterprises,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet des sections développées
class _SectionsTab extends StatelessWidget {
  const _SectionsTab({required this.sections});

  final List<ModuleSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune section développée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final theme = Theme.of(context);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                section.icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            title: Text(section.name),
            subtitle: section.description != null
                ? Text(section.description!)
                : null,
            trailing: Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

/// Onglet des utilisateurs
class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.assignments,
    required this.users,
    required this.enterprises,
  });

  final List<EnterpriseModuleUser> assignments;
  final List<dynamic> users;
  final List<dynamic> enterprises;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur assigné',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Créer un map pour accéder rapidement aux utilisateurs et entreprises
    final usersMap = {
      for (var user in users) user.id: user
    };
    final enterprisesMap = {
      for (var enterprise in enterprises) enterprise.id: enterprise
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final user = usersMap[assignment.userId];
        final enterprise = enterprisesMap[assignment.enterpriseId];

        if (user == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
              ),
            ),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enterprise != null)
                  Text('Entreprise: ${enterprise.name}'),
                Text('Rôle: ${assignment.roleId}'),
                if (!assignment.isActive)
                  Chip(
                    label: const Text('Inactif'),
                    avatar: const Icon(Icons.block, size: 16),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            trailing: assignment.isActive
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Icon(
                    Icons.cancel,
                    color: Theme.of(context).colorScheme.error,
                  ),
          ),
        );
      },
    );
  }
}

/// Onglet des entreprises
class _EnterprisesTab extends StatelessWidget {
  const _EnterprisesTab({required this.enterprises});

  final List<dynamic> enterprises;

  @override
  Widget build(BuildContext context) {
    if (enterprises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune entreprise',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enterprises.length,
      itemBuilder: (context, index) {
        final enterprise = enterprises[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(enterprise.name[0].toUpperCase()),
            ),
            title: Text(enterprise.name),
            subtitle: Text(enterprise.type ?? ''),
            trailing: enterprise.isActive
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Icon(
                    Icons.cancel,
                    color: Theme.of(context).colorScheme.error,
                  ),
          ),
        );
      },
    );
  }
}

