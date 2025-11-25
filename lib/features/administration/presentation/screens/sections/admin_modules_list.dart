import 'package:flutter/material.dart';

import '../../../domain/entities/admin_module.dart';

/// List of modules for administration.
class AdminModulesList extends StatelessWidget {
  const AdminModulesList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modules = AdminModules.all;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_getIcon(module.icon)),
            ),
            title: Text(
              module.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(module.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to module users management
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gestion de ${module.name} - À implémenter')),
              );
            },
          ),
        );
      },
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

