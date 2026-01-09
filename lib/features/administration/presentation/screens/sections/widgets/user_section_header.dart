import 'package:flutter/material.dart';

/// Header widget for user section.
/// 
/// Extracted for better code organization.
class UserSectionHeader extends StatelessWidget {
  const UserSectionHeader({
    super.key,
    required this.onCreateUser,
  });

  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
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

