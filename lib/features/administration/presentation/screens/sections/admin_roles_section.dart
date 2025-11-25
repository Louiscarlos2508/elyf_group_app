import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../../../core/permissions/entities/user_role.dart';

/// Section for managing roles.
class AdminRolesSection extends ConsumerWidget {
  const AdminRolesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return FutureBuilder<List<UserRole>>(
      future: adminRepo.getAllRoles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final roles = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des Rôles',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez et gérez les rôles avec leurs permissions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        IntrinsicWidth(
                          child: FilledButton.icon(
                            onPressed: () {
                              // TODO: Show create role dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Créer un rôle - À implémenter')),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Nouveau Rôle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final role = roles[index];
                  return Card(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: ListTile(
                      title: Text(
                        role.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(role.description),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(
                                label: Text(
                                  '${role.permissions.length} permission${role.permissions.length > 1 ? 's' : ''}',
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (role.isSystemRole)
                                Chip(
                                  label: const Text('Système'),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO: Show edit role dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Modifier ${role.name} - À implémenter')),
                          );
                        },
                      ),
                    ),
                  );
                },
                childCount: roles.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

