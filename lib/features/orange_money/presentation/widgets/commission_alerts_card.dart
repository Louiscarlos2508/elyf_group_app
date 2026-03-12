import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/commission.dart';
import '../../../orange_money/application/providers.dart';

/// Type of commission alert
enum CommissionAlertType {
  pendingDeclaration,
}

/// Commission alert data
class CommissionAlert {
  final CommissionAlertType type;
  final int count;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CommissionAlert({
    required this.type,
    required this.count,
    required this.message,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// Card widget to display commission alerts on dashboard
class CommissionAlertsCard extends ConsumerWidget {
  final int daysThreshold;

  const CommissionAlertsCard({
    super.key,
    this.daysThreshold = 7,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commissionsAsync = ref.watch(commissionsProvider(''));

    return commissionsAsync.when(
      data: (commissions) {
        final alerts = _getAlerts(commissions, context);

        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.orange.shade50,
          elevation: 2,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Alertes Commission',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...alerts.map((alert) => _buildAlertItem(alert, context)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlertItem(CommissionAlert alert, BuildContext context) {
    return InkWell(
      onTap: alert.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alert.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alert.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(alert.icon, color: alert.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (alert.count > 1)
                    Text(
                      '${alert.count} élément${alert.count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  List<CommissionAlert> _getAlerts(
    List<Commission> commissions,
    BuildContext context,
  ) {
    final alerts = <CommissionAlert>[];
    final now = DateTime.now();

    // Commissions en attente de déclaration (> X jours)
    final pendingDeclaration = commissions.where((c) {
      if (c.status != CommissionStatus.estimated) return false;
      if (c.createdAt == null) return false;
      final daysSince = now.difference(c.createdAt!).inDays;
      return daysSince >= daysThreshold;
    }).toList();

    if (pendingDeclaration.isNotEmpty) {
      alerts.add(CommissionAlert(
        type: CommissionAlertType.pendingDeclaration,
        count: pendingDeclaration.length,
        message: '${pendingDeclaration.length} commission(s) en attente de déclaration',
        icon: Icons.message,
        color: Colors.blue,
        onTap: () {
          // TODO: Navigate to commissions filtered by 'estimated'
        },
      ));
    }

    return alerts;


  }
}
