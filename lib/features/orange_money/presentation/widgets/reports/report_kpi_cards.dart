import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import 'package:elyf_groupe_app/shared.dart';

/// KPI cards row for reports screen.
class ReportKpiCards extends StatelessWidget {
  const ReportKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final totalCommission = stats['totalCommission'] as int? ?? 0;
    final depositsCount = stats['depositsCount'] as int? ?? 0;
    final withdrawalsCount = stats['withdrawalsCount'] as int? ?? 0;

    return Row(
      children: [
        _ReportKpiCard(
          icon: Icons.trending_up,
          iconColor: const Color(0xFF155DFC),
          label: 'Total transactions',
          value: totalTransactions.toString(),
          valueStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(width: 16),
        _ReportKpiCard(
          icon: Icons.arrow_downward,
          iconColor: const Color(0xFF00A63E),
          label: 'Dépôts',
          value: depositsCount.toString(),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFF00A63E),
          ),
          subtitle: CurrencyFormatter.formatFCFA(cashInTotal),
        ),
        const SizedBox(width: 16),
        _ReportKpiCard(
          icon: Icons.arrow_upward,
          iconColor: const Color(0xFFE7000B),
          label: 'Retraits',
          value: withdrawalsCount.toString(),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFFE7000B),
          ),
          subtitle: CurrencyFormatter.formatFCFA(cashOutTotal),
        ),
        const SizedBox(width: 16),
        _ReportKpiCard(
          icon: Icons.attach_money,
          iconColor: const Color(0xFFF54900),
          label: 'Commissions',
          value: CurrencyFormatter.formatFCFA(totalCommission),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFFF54900),
          ),
        ),
      ],
    );
  }
}

/// Individual KPI card for reports.
class _ReportKpiCard extends StatelessWidget {
  const _ReportKpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueStyle,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final TextStyle valueStyle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.219,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5565),
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(value, style: valueStyle, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5565),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
