import 'package:flutter/material.dart';

import '../../../../../domain/entities/admin_module.dart';

/// Widget pour la sélection multiple de modules.
class MultipleModuleSelection extends StatelessWidget {
  const MultipleModuleSelection({
    super.key,
    required this.selectedModuleIds,
    required this.onChanged,
  });

  final Set<String> selectedModuleIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final availableModules = AdminModules.all;

    if (availableModules.isEmpty) {
      return const Text('Aucun module disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez les modules * (${selectedModuleIds.length} sélectionné(s))',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableModules.length,
            itemBuilder: (context, index) {
              final module = availableModules[index];
              final isSelected = selectedModuleIds.contains(module.id);

              return CheckboxListTile(
                title: Text(module.name),
                subtitle: Text(
                  module.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                value: isSelected,
                onChanged: (value) {
                  final newSelection = Set<String>.from(selectedModuleIds);
                  if (value == true) {
                    newSelection.add(module.id);
                  } else {
                    newSelection.remove(module.id);
                  }
                  onChanged(newSelection);
                },
                dense: true,
              );
            },
          ),
        ),
        if (selectedModuleIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionnez au moins un module',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
