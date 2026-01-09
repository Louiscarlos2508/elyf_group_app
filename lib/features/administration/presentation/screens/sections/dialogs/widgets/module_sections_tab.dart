import 'package:flutter/material.dart';

import '../../../../domain/entities/module_sections_info.dart';

/// Tab widget displaying module sections
class ModuleSectionsTab extends StatelessWidget {
  const ModuleSectionsTab({
    super.key,
    required this.sections,
  });

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

