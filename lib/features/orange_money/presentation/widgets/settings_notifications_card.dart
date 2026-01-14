import 'package:flutter/material.dart';

import '../../domain/entities/settings.dart';
import 'settings_toggle_item.dart';

/// Card widget for notification settings.
class SettingsNotificationsCard extends StatelessWidget {
  const SettingsNotificationsCard({
    super.key,
    required this.notifications,
    required this.onNotificationsChanged,
  });

  final NotificationSettings notifications;
  final ValueChanged<NotificationSettings> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notifications et alertes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsToggleItem(
              label: '🔴 Alerte liquidité basse',
              description:
                  'Recevoir une notification quand la liquidité est en dessous du seuil critique',
              value: notifications.lowLiquidityAlert,
              onChanged: (value) {
                onNotificationsChanged(
                  notifications.copyWith(lowLiquidityAlert: value),
                );
              },
            ),
            const SizedBox(height: 16),
            SettingsToggleItem(
              label: '📅 Rappel calcul commission mensuelle',
              description:
                  'Notification automatique en début de mois pour calculer les commissions',
              value: notifications.monthlyCommissionReminder,
              onChanged: (value) {
                onNotificationsChanged(
                  notifications.copyWith(monthlyCommissionReminder: value),
                );
              },
            ),
            const SizedBox(height: 16),
            SettingsToggleItem(
              label: '⏰ Alerte échéance de paiement',
              description:
                  'Notification avant l\'échéance de paiement des commissions aux agents',
              value: notifications.paymentDueAlert,
              onChanged: (value) {
                onNotificationsChanged(
                  notifications.copyWith(paymentDueAlert: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
