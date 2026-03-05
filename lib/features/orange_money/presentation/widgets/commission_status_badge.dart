import 'package:flutter/material.dart';
import '../../domain/entities/commission.dart';

/// Configuration for commission status display
class StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  const StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Badge widget to display commission status with color coding
class CommissionStatusBadge extends StatelessWidget {
  final CommissionStatus status;
  final DiscrepancyStatus? discrepancyStatus;
  final bool showWarningIcon;

  const CommissionStatusBadge({
    super.key,
    required this.status,
    this.discrepancyStatus,
    this.showWarningIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  StatusConfig _getStatusConfig() {
    switch (status) {
      case CommissionStatus.estimated:
        return const StatusConfig(
          label: 'À déclarer',
          icon: Icons.history_rounded,
          color: Colors.blue,
        );
      case CommissionStatus.declared:
        return const StatusConfig(
          label: 'Déclarée',
          icon: Icons.pending,
          color: Colors.orange,
        );
      case CommissionStatus.paid:
        return const StatusConfig(
          label: 'Payée',
          icon: Icons.payments,
          color: Colors.purple,
        );
    }
  }

}
