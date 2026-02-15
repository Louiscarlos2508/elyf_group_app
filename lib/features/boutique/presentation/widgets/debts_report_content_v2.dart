import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/report_data.dart';

class DebtsReportContentV2 extends ConsumerWidget {
  const DebtsReportContentV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(debtsReportProvider);

    return reportAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(data),
          const SizedBox(height: 24),
          _buildAgingChart(context, data.aging),
          const SizedBox(height: 24),
          _buildTopSuppliers(context, data.debtBySupplier),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildSummaryCards(DebtsReportData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DETTE TOTALE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(data.totalDebt)} CFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingChart(BuildContext context, Map<String, int> aging) {
    final total = aging.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Âge de la Dette",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 12,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              _buildBarPart(aging['0-30'] ?? 0, total, Colors.green),
              _buildBarPart(aging['31-60'] ?? 0, total, Colors.orange),
              _buildBarPart(aging['61+'] ?? 0, total, Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('0-30 j', aging['0-30'] ?? 0, Colors.green),
            _buildLegendItem('31-60 j', aging['31-60'] ?? 0, Colors.orange),
            _buildLegendItem('61+ j', aging['61+'] ?? 0, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildBarPart(int value, int total, Color color) {
    if (value == 0) return const SizedBox.shrink();
    return Expanded(
      flex: value,
      child: Container(color: color),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${NumberFormat('#,###').format(value)} CFA', 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTopSuppliers(BuildContext context, List<SupplierDebtSummary> topSuppliers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top Fournisseurs Endeptés",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...topSuppliers.map((s) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.grey.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(s.supplierName, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(
              '${NumberFormat('#,###').format(s.balance)} CFA',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        )),
      ],
    );
  }
}
