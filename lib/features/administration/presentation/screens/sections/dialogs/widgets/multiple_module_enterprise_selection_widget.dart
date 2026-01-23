import 'package:flutter/material.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../domain/entities/enterprise.dart';

/// Widget pour la sélection multiple d'entreprises avec support pour plusieurs modules.
///
/// Filtre les entreprises qui correspondent à au moins un des modules sélectionnés.
class MultipleModuleEnterpriseSelection extends StatelessWidget {
  const MultipleModuleEnterpriseSelection({
    super.key,
    required this.enterprises,
    required this.selectedEnterpriseIds,
    required this.onChanged,
    required this.moduleIds,
  });

  final List<Enterprise> enterprises;
  final Set<String> selectedEnterpriseIds;
  final ValueChanged<Set<String>> onChanged;
  final Set<String> moduleIds;

  /// Obtient les types d'entreprises correspondant aux modules.
  Set<String> _getEnterpriseTypesForModules(Set<String> moduleIds) {
    final moduleToTypeMap = {
      'eau_minerale': 'eau_minerale',
      'gaz': 'gaz',
      'orange_money': 'orange_money',
      'immobilier': 'immobilier',
      'boutique': 'boutique',
    };

    return moduleIds
        .map((moduleId) => moduleToTypeMap[moduleId])
        .whereType<String>()
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final enterpriseTypes = _getEnterpriseTypesForModules(moduleIds);

    // Filtrer les entreprises actives qui correspondent à au moins un des types
    final availableEnterprises = enterprises
        .where((e) => e.isActive && enterpriseTypes.contains(e.type))
        .toList();
    
    // Debug: Log pour voir si les points de vente sont inclus
    final posCount = availableEnterprises.where((e) => e.description?.contains("Point de vente") ?? false).length;
    AppLogger.debug(
      'MultipleModuleEnterpriseSelection: ${enterprises.length} entreprises au total, ${availableEnterprises.length} disponibles pour modules $moduleIds (dont $posCount points de vente)',
      name: 'admin.enterprise',
    );

    if (availableEnterprises.isEmpty) {
      return const Text(
        'Aucune entreprise active pour les modules sélectionnés',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez les entreprises * (${selectedEnterpriseIds.length} sélectionnée(s))',
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
            itemCount: availableEnterprises.length,
            itemBuilder: (context, index) {
              final enterprise = availableEnterprises[index];
              final isSelected = selectedEnterpriseIds.contains(enterprise.id);

              return CheckboxListTile(
                title: Text(enterprise.name),
                value: isSelected,
                onChanged: (value) {
                  final newSelection = Set<String>.from(selectedEnterpriseIds);
                  if (value == true) {
                    newSelection.add(enterprise.id);
                  } else {
                    newSelection.remove(enterprise.id);
                  }
                  onChanged(newSelection);
                },
                dense: true,
              );
            },
          ),
        ),
        if (selectedEnterpriseIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionnez au moins une entreprise',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
