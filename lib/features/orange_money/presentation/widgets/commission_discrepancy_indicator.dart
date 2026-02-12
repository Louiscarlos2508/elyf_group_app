import 'package:flutter/material.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/commission.dart';

/// Widget to display commission discrepancy with visual indicators
class CommissionDiscrepancyIndicator extends StatelessWidget {
  final int estimatedAmount;
  final int declaredAmount;
  final int? discrepancy;
  final double? discrepancyPercentage;
  final DiscrepancyStatus? discrepancyStatus;
  final bool showDetails;

  const CommissionDiscrepancyIndicator({
    super.key,
    required this.estimatedAmount,
    required this.declaredAmount,
    this.discrepancy,
    this.discrepancyPercentage,
    this.discrepancyStatus,
    this.showDetails = true,
  });

  /// Factory constructor to create from Commission entity
  factory CommissionDiscrepancyIndicator.fromCommission(
    Commission commission, {
    bool showDetails = true,
  }) {
    return CommissionDiscrepancyIndicator(
      estimatedAmount: commission.estimatedAmount,
      declaredAmount: commission.declaredAmount ?? 0,
      discrepancy: commission.discrepancy,
      discrepancyPercentage: commission.discrepancyPercentage,
      discrepancyStatus: commission.discrepancyStatus,
      showDetails: showDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculatedDiscrepancy = discrepancy ?? (declaredAmount - estimatedAmount);
    final calculatedPercentage = discrepancyPercentage ??
        (estimatedAmount > 0
            ? (calculatedDiscrepancy.abs() / estimatedAmount * 100)
            : 0.0);

    final status = discrepancyStatus ?? _calculateStatus(calculatedPercentage);
    final config = _getDiscrepancyConfig(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: config.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: config.color,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Écart',
              CurrencyFormatter.format(calculatedDiscrepancy),
              isNegative: calculatedDiscrepancy < 0,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              'Pourcentage',
              '${calculatedPercentage.toStringAsFixed(1)}%',
              isNegative: calculatedDiscrepancy < 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isNegative ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  DiscrepancyStatus _calculateStatus(double percentage) {
    if (percentage < 1) {
      return DiscrepancyStatus.conforme;
    } else if (percentage <= 5) {
      return DiscrepancyStatus.ecartMineur;
    } else {
      return DiscrepancyStatus.ecartSignificatif;
    }
  }

  StatusConfig _getDiscrepancyConfig(DiscrepancyStatus status) {
    switch (status) {
      case DiscrepancyStatus.conforme:
        return const StatusConfig(
          label: 'Conforme',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case DiscrepancyStatus.ecartMineur:
        return const StatusConfig(
          label: 'Écart Mineur',
          icon: Icons.warning_amber,
          color: Colors.orange,
        );
      case DiscrepancyStatus.ecartSignificatif:
        return const StatusConfig(
          label: 'Écart Significatif',
          icon: Icons.error,
          color: Colors.red,
        );
    }
  }
}

/// Configuration for discrepancy display
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
