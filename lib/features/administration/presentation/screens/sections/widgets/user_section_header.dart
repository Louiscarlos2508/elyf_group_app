import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart' show usersProvider;

/// Header widget for user section.
///
/// Extracted for better code organization.
class UserSectionHeader extends ConsumerWidget {
  const UserSectionHeader({super.key, required this.onCreateUser});

  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
              IconButton(
                onPressed: () {
                  // Invalider le provider pour forcer une relecture depuis Firestore
                  ref.invalidate(usersProvider);
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser la liste depuis Firestore',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateUser,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un utilisateur'),
          ),
        ],
      ),
    );
  }
}
