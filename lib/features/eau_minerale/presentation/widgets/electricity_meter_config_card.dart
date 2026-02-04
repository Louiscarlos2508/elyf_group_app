import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Carte pour configurer le type de compteur électrique et le taux du kWh.
class ElectricityMeterConfigCard extends ConsumerStatefulWidget {
  const ElectricityMeterConfigCard({super.key});

  @override
  ConsumerState<ElectricityMeterConfigCard> createState() =>
      _ElectricityMeterConfigCardState();
}

class _ElectricityMeterConfigCardState
    extends ConsumerState<ElectricityMeterConfigCard> {
  final _rateController = TextEditingController();
  bool _isSavingRate = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRate();
  }

  Future<void> _loadInitialRate() async {
    final rate =
        await ref.read(electricityMeterConfigServiceProvider).getElectricityRate();
    _rateController.text = rate.toString();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bolt_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration Électricité',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gérez le tarif et le type de compteur',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildRateInput(theme),
            const SizedBox(height: 32),
            Text(
              'TYPE DE COMPTEUR',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            meterTypeAsync.when(
              data: (currentType) =>
                  _buildMeterTypeSelector(context, ref, theme, currentType),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
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

  Widget _buildRateInput(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _rateController,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Prix du kWh (CFA)',
              prefixIcon: const Icon(Icons.flash_on_outlined),
              suffixText: 'CFA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSavingRate,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _isSavingRate ? null : _saveRate,
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSavingRate
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : const Text('Mettre à jour'),
        ),
      ],
    );
  }

  Future<void> _saveRate() async {
    final val = double.tryParse(_rateController.text);
    if (val == null) {
      NotificationService.showError(context, 'Prix invalide');
      return;
    }

    setState(() => _isSavingRate = true);
    try {
      await ref.read(electricityMeterConfigServiceProvider).setElectricityRate(val);
      ref.invalidate(electricityRateProvider);
      if (mounted) {
        NotificationService.showSuccess(context, 'Prix du kWh mis à jour');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRate = false);
      }
    }
  }

  Widget _buildMeterTypeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ElectricityMeterType currentType,
  ) {
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: ElectricityMeterType.values.map((type) {
            final isSelected = type == currentType;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == ElectricityMeterType.values.first ? 8 : 0,
                  left: type == ElectricityMeterType.values.last ? 8 : 0,
                ),
                child: _MeterTypeCard(
                  title: type.label,
                  subtitle: type.description,
                  unit: type.unit,
                  isSelected: isSelected,
                  onTap: () => _selectMeterType(context, ref, type),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cette configuration est utilisée pour les calculs de rentabilité.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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
      NotificationService.showInfo(
        context,
        'Type de compteur configuré: ${type.label}',
      );
    }
  }
}

class _MeterTypeCard extends StatelessWidget {
  const _MeterTypeCard({
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String unit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.05) : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
