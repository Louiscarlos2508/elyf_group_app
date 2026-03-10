import 'package:flutter/material.dart';

import '../../../domain/entities/machine_material_usage.dart';

/// Widget d'alerte pour informer l'utilisateur des machines avec matières non finies.
/// (Anciennement BobineNonFinieAlert).
class MachineMaterialNonFinieAlert extends StatelessWidget {
  const MachineMaterialNonFinieAlert({
    super.key,
    required this.machinesAvecMatiereNonFinie,
  });

  final Map<String, MachineMaterialUsage> machinesAvecMatiereNonFinie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machines = machinesAvecMatiereNonFinie.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Matières non finies détectées',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Les machines suivantes ont des matières non finies (bobines, etc) qui seront réutilisées au lieu d\'utiliser le stock :',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...machines.map((machineId) {
            final usage = machinesAvecMatiereNonFinie[machineId]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${usage.machineName}: ${usage.materialType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ces matières seront réutilisées automatiquement. Le stock ne sera pas décrémenté.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
