import 'package:flutter/material.dart';

import '../../../../../domain/entities/enterprise.dart';

/// Widget pour la sélection d'une seule entreprise (mode classique).
class SingleEnterpriseSelection extends StatelessWidget {
  const SingleEnterpriseSelection({
    super.key,
    required this.enterprises,
    required this.selectedEnterpriseId,
    required this.onChanged,
    required this.moduleId,
  });

  final List<Enterprise> enterprises;
  final String? selectedEnterpriseId;
  final ValueChanged<String?> onChanged;
  final String moduleId;

  /// Obtient le type d'entreprise correspondant au module.
  EnterpriseType? _getEnterpriseTypeForModule(String moduleId) {
    if (moduleId == 'eau_minerale') return EnterpriseType.waterEntity;
    if (moduleId == 'gaz') return EnterpriseType.gasCompany;
    if (moduleId == 'orange_money') return EnterpriseType.mobileMoneyAgent;
    if (moduleId == 'immobilier') return EnterpriseType.realEstateAgency;
    if (moduleId == 'boutique') return EnterpriseType.shop;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enterpriseType = _getEnterpriseTypeForModule(moduleId);

    // Filtrer les entreprises actives du même type que le module
    final availableEnterprises = enterprises
        .where((e) => e.isActive && e.type == enterpriseType)
        .toList();

    if (availableEnterprises.isEmpty) {
      return const Text('Aucune entreprise active pour ce module');
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedEnterpriseId,
      decoration: const InputDecoration(labelText: 'Entreprise *'),
      items: availableEnterprises.map((enterprise) {
        return DropdownMenuItem(
          value: enterprise.id,
          child: Text(enterprise.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Sélectionnez une entreprise';
        }
        return null;
      },
    );
  }
}

/// Widget pour la sélection multiple d'entreprises (mode batch).
class MultipleEnterpriseSelection extends StatelessWidget {
  const MultipleEnterpriseSelection({
    super.key,
    required this.enterprises,
    required this.selectedEnterpriseIds,
    required this.onChanged,
    required this.moduleId,
  });

  final List<Enterprise> enterprises;
  final Set<String> selectedEnterpriseIds;
  final ValueChanged<Set<String>> onChanged;
  final String moduleId;

  EnterpriseType? _getEnterpriseTypeForModule(String moduleId) {
    if (moduleId == 'eau_minerale') return EnterpriseType.waterEntity;
    if (moduleId == 'gaz') return EnterpriseType.gasCompany;
    if (moduleId == 'orange_money') return EnterpriseType.mobileMoneyAgent;
    if (moduleId == 'immobilier') return EnterpriseType.realEstateAgency;
    if (moduleId == 'boutique') return EnterpriseType.shop;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enterpriseType = _getEnterpriseTypeForModule(moduleId);

    // Filtrer les entreprises actives du même type que le module
    final availableEnterprises = enterprises
        .where((e) => e.isActive && e.type == enterpriseType)
        .toList();

    if (availableEnterprises.isEmpty) {
      return const Text('Aucune entreprise active pour ce module');
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
