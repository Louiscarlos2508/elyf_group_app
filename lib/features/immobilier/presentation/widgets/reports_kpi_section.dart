import 'package:flutter/material.dart';

import '../../domain/entities/payment.dart';
import 'enhanced_kpi_card.dart';

/// Section des KPIs pour les rapports.
class ReportsKpiSection extends StatelessWidget {
  const ReportsKpiSection({
    super.key,
    required this.totalRevenue,
    required this.totalPayments,
    required this.pendingPayments,
    required this.overduePayments,
    required this.averagePayment,
  });

  final int totalRevenue;
  final int totalPayments;
  final int pendingPayments;
  final int overduePayments;
  final double averagePayment;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: EnhancedKpiCard(
                title: 'Revenus totaux',
                value: _formatCurrency(totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EnhancedKpiCard(
                title: 'Paiements',
                value: totalPayments.toString(),
                icon: Icons.payment,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: EnhancedKpiCard(
                title: 'En attente',
                value: pendingPayments.toString(),
                icon: Icons.pending,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EnhancedKpiCard(
                title: 'En retard',
                value: overduePayments.toString(),
                icon: Icons.warning,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: EnhancedKpiCard(
                title: 'Moyenne',
                value: _formatCurrency(averagePayment.toInt()),
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

