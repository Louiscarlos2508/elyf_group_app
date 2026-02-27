import 'package:flutter/material.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../domain/entities/enterprise.dart';
import '../../../../../../../core/permissions/entities/user_role.dart';

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
    this.selectedRoles = const [],
  });

  final List<Enterprise> enterprises;
  final Set<String> selectedEnterpriseIds;
  final ValueChanged<Set<String>> onChanged;
  final Set<String> moduleIds;
  final List<UserRole> selectedRoles;

  /// Obtient les types d'entreprises correspondant aux modules.
  Set<String> _getEnterpriseTypesForModules(Set<String> moduleIds) {
    final compatibleTypes = <String>{};

    for (final moduleId in moduleIds) {
      // Logique de compatibilité STRICTE entre Modules et Types d'Entreprises
      switch (moduleId) {
        case 'gaz':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isGas)
              .map((t) => t.id));
          break;
          
        case 'eau_minerale':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isWater)
              .map((t) => t.id));
          break;
          
        case 'orange_money':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isMobileMoney)
              .map((t) => t.id));
          break;
          
        case 'immobilier':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isRealEstate)
              .map((t) => t.id));
          break;
          
        case 'boutique':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isShop)
              .map((t) => t.id));
          break;
          
        default:
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.module.id == moduleId)
              .map((t) => t.id));
      }
    }

    return compatibleTypes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterpriseTypes = _getEnterpriseTypesForModules(moduleIds);

    // Filtrer les entreprises actives qui correspondent à au moins un des types
    // ET qui sont compatibles avec TOUS les rôles sélectionnés
    final availableEnterprises = enterprises.where((e) {
      // 1. Vérification du module
      final isCompatibleWithModule = e.isActive && enterpriseTypes.contains(e.type.id);
      if (!isCompatibleWithModule) return false;

      // 2. Vérification du niveau d'entreprise (si des rôles sont sélectionnés)
      if (selectedRoles.isNotEmpty) {
        return selectedRoles.every((role) => role.canBeAssignedTo(e.type));
      }

      return true;
    }).toList();
    
    // Debug: Log pour voir si les points de vente sont inclus
    final posCount = availableEnterprises.where((e) => e.isPointOfSale).length;
    AppLogger.debug(
      'MultipleModuleEnterpriseSelection: ${enterprises.length} entreprises au total, ${availableEnterprises.length} disponibles pour modules $moduleIds (dont $posCount points de vente)',
      name: 'admin.enterprise',
    );

    if (availableEnterprises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: theme.colorScheme.surfaceContainerLow,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
         ),
        child: Row(
          children: [
            Icon(Icons.business_outlined, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune entreprise active pour les modules sélectionnés',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.secondaryContainer,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Icon(
                     Icons.business,
                     size: 16,
                     color: theme.colorScheme.onSecondaryContainer,
                   ),
                 ),
                 const SizedBox(width: 12),
                 Text(
                   'Entreprises',
                   style: theme.textTheme.titleMedium?.copyWith(
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ],
             ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${selectedEnterpriseIds.length} sélectionnée(s)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            shrinkWrap: true,
            itemCount: availableEnterprises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final enterprise = availableEnterprises[index];
              final isSelected = selectedEnterpriseIds.contains(enterprise.id);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final newSelection = Set<String>.from(selectedEnterpriseIds);
                    if (isSelected) {
                      newSelection.remove(enterprise.id);
                    } else {
                      newSelection.add(enterprise.id);
                    }
                    onChanged(newSelection);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            enterprise.type.icon,
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enterprise.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected 
                                    ? theme.colorScheme.primary 
                                    : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: enterprise.type.module.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      enterprise.type.label,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                           Container(
                             margin: const EdgeInsets.only(left: 8),
                             padding: const EdgeInsets.all(2),
                             decoration: BoxDecoration(
                               color: theme.colorScheme.primary,
                               shape: BoxShape.circle,
                             ),
                             child: Icon(
                               Icons.check,
                               size: 10,
                               color: theme.colorScheme.onPrimary,
                             ),
                           ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (selectedEnterpriseIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                 Icon(Icons.info_outline, size: 14, color: theme.colorScheme.error),
                 const SizedBox(width: 4),
                 Text(
                   'Sélectionnez au moins une entreprise',
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                     color: Theme.of(context).colorScheme.error,
                   ),
                 ),
              ],
            ),
          ),
      ],
    );
  }
}
