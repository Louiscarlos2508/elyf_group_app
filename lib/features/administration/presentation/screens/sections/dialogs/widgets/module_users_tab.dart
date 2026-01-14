import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';

/// Tab widget displaying module users
class ModuleUsersTab extends StatelessWidget {
  const ModuleUsersTab({
    super.key,
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
    final usersMap = {for (var user in users) user.id: user};
    final enterprisesMap = {
      for (var enterprise in enterprises) enterprise.id: enterprise,
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
                if (enterprise != null) Text('Entreprise: ${enterprise.name}'),
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
