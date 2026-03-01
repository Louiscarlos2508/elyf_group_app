import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Card widget for threshold settings.
class SettingsThresholdsCard extends StatefulWidget {
  const SettingsThresholdsCard({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final OrangeMoneySettings settings;
  final ValueChanged<OrangeMoneySettings> onSettingsChanged;

  @override
  State<SettingsThresholdsCard> createState() => _SettingsThresholdsCardState();
}

class _SettingsThresholdsCardState extends State<SettingsThresholdsCard> {
  late TextEditingController _liquidityController;
  late TextEditingController _discrepancyController;
  late TextEditingController _reminderDaysController;
  late TextEditingController _largeTxController;

  @override
  void initState() {
    super.initState();
    _liquidityController = TextEditingController(
      text: widget.settings.criticalLiquidityThreshold.toString(),
    );
    _discrepancyController = TextEditingController(
      text: widget.settings.checkpointDiscrepancyThreshold.toString(),
    );
    _reminderDaysController = TextEditingController(
      text: widget.settings.commissionReminderDays.toString(),
    );
    _largeTxController = TextEditingController(
      text: widget.settings.largeTransactionThreshold.toString(),
    );
  }

  @override
  void didUpdateWidget(SettingsThresholdsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      if (_liquidityController.text !=
          widget.settings.criticalLiquidityThreshold.toString()) {
        _liquidityController.text =
            widget.settings.criticalLiquidityThreshold.toString();
      }
      if (_discrepancyController.text !=
          widget.settings.checkpointDiscrepancyThreshold.toString()) {
        _discrepancyController.text =
            widget.settings.checkpointDiscrepancyThreshold.toString();
      }
      if (_reminderDaysController.text !=
          widget.settings.commissionReminderDays.toString()) {
        _reminderDaysController.text =
            widget.settings.commissionReminderDays.toString();
      }
      if (_largeTxController.text !=
          widget.settings.largeTransactionThreshold.toString()) {
        _largeTxController.text =
            widget.settings.largeTransactionThreshold.toString();
      }
    }
  }

  @override
  void dispose() {
    _liquidityController.dispose();
    _discrepancyController.dispose();
    _reminderDaysController.dispose();
    _largeTxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune_rounded, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Seuils et limites',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  context,
                  label: 'Seuil liquidité critique (FCFA)',
                  controller: _liquidityController,
                  hint: '50000',
                  description: 'Alerte si la liquidité descend sous ce seuil',
                  icon: Icons.warning_amber_rounded,
                  onChanged: (value) {
                    final val = int.tryParse(value);
                    if (val != null) {
                      widget.onSettingsChanged(
                        widget.settings.copyWith(
                          criticalLiquidityThreshold: val,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  context,
                  label: 'Seuil écart pointage (%)',
                  controller: _discrepancyController,
                  hint: '2.0',
                  isDecimal: true,
                  description: 'Alerte si l\'écart théorique dépasse ce %',
                  icon: Icons.analytics_rounded,
                  onChanged: (value) {
                    final val = double.tryParse(value);
                    if (val != null) {
                      widget.onSettingsChanged(
                        widget.settings.copyWith(
                          checkpointDiscrepancyThreshold: val,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  context,
                  label: 'Rappel commission (jours)',
                  controller: _reminderDaysController,
                  hint: '7',
                  description: 'Jours avant fin de mois pour le rappel',
                  icon: Icons.calendar_month_rounded,
                  onChanged: (value) {
                    final val = int.tryParse(value);
                    if (val != null) {
                      widget.onSettingsChanged(
                        widget.settings.copyWith(commissionReminderDays: val),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  context,
                  label: 'Transaction importante (FCFA)',
                  controller: _largeTxController,
                  hint: '500000',
                  description: 'Seuil pour les alertes de gros montants',
                  icon: Icons.payments_rounded,
                  onChanged: (value) {
                    final val = int.tryParse(value);
                    if (val != null) {
                      widget.onSettingsChanged(
                        widget.settings.copyWith(
                          largeTransactionThreshold: val,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildRecommendationsBox(theme),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required String description,
    required ValueChanged<String> onChanged,
    required IconData icon,
    bool isDecimal = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType:
              isDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
          inputFormatters: [
            if (!isDecimal) FilteringTextInputFormatter.digitsOnly,
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Recommandations d\'Experts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            theme,
            'Maintenez un seuil de liquidité entre 50.000 et 100.000 F pour éviter les ruptures.',
          ),
          _buildRecommendationItem(theme, 'Un écart de pointage inférieur à 2% est considéré comme sain.'),
          _buildRecommendationItem(
            theme,
            'Configurez les transactions importantes à partir de 500.000 F pour un contrôle renforcé.',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
