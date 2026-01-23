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

    // Dédupliquer les assignments par userId pour éviter d'afficher le même utilisateur plusieurs fois
    // On garde le premier assignment trouvé pour chaque utilisateur
    final seenUserIds = <String>{};
    final uniqueAssignments = <EnterpriseModuleUser>[];
    for (final assignment in assignments) {
      if (!seenUserIds.contains(assignment.userId)) {
        seenUserIds.add(assignment.userId);
        uniqueAssignments.add(assignment);
      }
    }

    // Collecter toutes les entreprises pour chaque utilisateur unique
    final userEnterprisesMap = <String, List<String>>{};
    for (final assignment in assignments) {
      if (seenUserIds.contains(assignment.userId)) {
        userEnterprisesMap.putIfAbsent(assignment.userId, () => []).add(
          assignment.enterpriseId,
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uniqueAssignments.length,
      itemBuilder: (context, index) {
        final assignment = uniqueAssignments[index];
        final user = usersMap[assignment.userId];
        final enterprise = enterprisesMap[assignment.enterpriseId];
        final userEnterprises = userEnterprisesMap[assignment.userId] ?? [];

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
                // Afficher toutes les entreprises pour cet utilisateur
                if (userEnterprises.isNotEmpty)
                  Text(
                    userEnterprises.length == 1
                        ? 'Entreprise: ${enterprise?.name ?? userEnterprises.first}'
                        : 'Entreprises: ${userEnterprises.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (userEnterprises.length > 1)
                  ...userEnterprises.map((entId) {
                    final ent = enterprisesMap[entId];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Text(
                        '• ${ent?.name ?? entId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                    );
                  }),
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
