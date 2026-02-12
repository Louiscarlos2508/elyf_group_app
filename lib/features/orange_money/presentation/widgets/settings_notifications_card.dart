import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'settings_toggle_item.dart';

/// Card widget for notification settings.
class SettingsNotificationsCard extends StatelessWidget {
  const SettingsNotificationsCard({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final OrangeMoneySettings settings;
  final ValueChanged<OrangeMoneySettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 4,
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
                child: Icon(Icons.notifications_active_rounded,
                    size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Notifications et Alertes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsToggleItem(
            label: 'Alerte liquidité critique',
            description: 'Notification immédiate quand vos fonds sont insuffisants pour opérer.',
            value: settings.enableLiquidityAlerts,
            onChanged: (value) {
              onSettingsChanged(
                settings.copyWith(enableLiquidityAlerts: value),
              );
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          SettingsToggleItem(
            label: 'Rappel commission mensuelle',
            description: 'Aide à ne pas oublier la déclaration de vos commissions en fin de période.',
            value: settings.enableCommissionReminders,
            onChanged: (value) {
              onSettingsChanged(
                settings.copyWith(enableCommissionReminders: value),
              );
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          SettingsToggleItem(
            label: 'Rappel de pointage journalier',
            description: 'Maintenez une traçabilité rigoureuse avec deux pointages par jour.',
            value: settings.enableCheckpointReminders,
            onChanged: (value) {
              onSettingsChanged(
                settings.copyWith(enableCheckpointReminders: value),
              );
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          SettingsToggleItem(
            label: 'Alertes transactions majeures',
            description: 'Soyez notifié pour toute opération dépassant votre seuil de sécurité.',
            value: settings.enableTransactionAlerts,
            onChanged: (value) {
              onSettingsChanged(
                settings.copyWith(enableTransactionAlerts: value),
              );
            },
          ),
        ],
      ),
    );
  }
}
