import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/electricity_meter_type.dart';
import '../../domain/services/electricity_meter_config_service.dart';
import '../screens/sections/settings_screen.dart';

/// Carte pour configurer le type de compteur électrique.
class ElectricityMeterConfigCard extends ConsumerWidget {
  const ElectricityMeterConfigCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.electrical_services,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration compteur électrique',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez le type de compteur utilisé dans votre entreprise',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            meterTypeAsync.when(
              data: (currentType) => _buildMeterTypeSelector(
                context,
                ref,
                theme,
                currentType,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Erreur: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterTypeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ElectricityMeterType currentType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...ElectricityMeterType.values.map((type) {
          final isSelected = type == currentType;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectMeterType(context, ref, type),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<ElectricityMeterType>(
                      value: type,
                      groupValue: currentType,
                      onChanged: (value) {
                        if (value != null) {
                          _selectMeterType(context, ref, value);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                type.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  type.unit,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cette configuration sera utilisée dans tous les formulaires de session de production.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectMeterType(
    BuildContext context,
    WidgetRef ref,
    ElectricityMeterType type,
  ) async {
    final service = ref.read(electricityMeterConfigServiceProvider);
    await service.setMeterType(type);
    
    if (context.mounted) {
      ref.invalidate(electricityMeterTypeProvider);
      NotificationService.showInfo(context, 'Type de compteur configuré: ${type.label}');
    }
  }
}
