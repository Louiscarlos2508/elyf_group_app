import 'package:flutter/material.dart';

/// Tab widget displaying module enterprises
class ModuleEnterprisesTab extends StatelessWidget {
  const ModuleEnterprisesTab({super.key, required this.enterprises});

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
            subtitle: Text(enterprise.type.label),
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
