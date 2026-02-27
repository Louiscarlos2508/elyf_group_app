import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Onglet affichant les dépenses extraites des tournées clôturées.
class TourExpensesTab extends ConsumerWidget {
  const TourExpensesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final toursAsync = ref.watch(
      toursProvider((enterpriseId: enterpriseId, status: TourStatus.closed)),
    );

    return toursAsync.when(
      data: (tours) {
        if (tours.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune tournée clôturée',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les dépenses apparaissent après la clôture d\'une tournée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        // KPIs globaux
        final totalAllTours = tours.fold<double>(
          0,
          (sum, t) => sum + t.totalExpenses,
        );
        final totalTransport = tours.fold<double>(
          0,
          (sum, t) => sum + t.totalTransportExpenses,
        );
        final totalGasPurchase = tours.fold<double>(
          0,
          (sum, t) => sum + t.totalGasPurchaseCost,
        );

        return Column(
          children: [
            // KPI Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiChip(
                      label: 'Total tournées',
                      value: CurrencyFormatter.formatDouble(totalAllTours),
                      icon: Icons.local_shipping_outlined,
                    ),
                  ),
                  Expanded(
                    child: _KpiChip(
                      label: 'Transport',
                      value: CurrencyFormatter.formatDouble(totalTransport),
                      icon: Icons.directions_car_outlined,
                    ),
                  ),
                  Expanded(
                    child: _KpiChip(
                      label: 'Achat gaz',
                      value: CurrencyFormatter.formatDouble(totalGasPurchase),
                      icon: Icons.gas_meter_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des tournées
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tours.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tour = tours[index];
                  return _TourExpenseCard(tour: tour);
                },
              ),
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (e, _) => ErrorDisplayWidget(
        error: e,
        title: 'Erreur de chargement des tournées',
        onRetry: () => ref.invalidate(toursProvider),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.error),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _TourExpenseCard extends StatelessWidget {
  const _TourExpenseCard({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final rows = <_ExpenseRow>[
      if (tour.gasPurchaseCost != null && tour.gasPurchaseCost! > 0)
        _ExpenseRow('Achat gaz (facture)', tour.totalGasPurchaseCost),
      if (tour.totalTransportExpenses > 0)
        _ExpenseRow('Transport', tour.totalTransportExpenses),
      if (tour.totalLoadingFees > 0)
        _ExpenseRow('Frais chargement', tour.totalLoadingFees),
      if (tour.totalUnloadingFees > 0)
        _ExpenseRow('Frais déchargement', tour.totalUnloadingFees),
      if (tour.totalExchangeFees > 0)
        _ExpenseRow('Frais d\'échange', tour.totalExchangeFees),
      if (tour.additionalInvoiceFees > 0)
        _ExpenseRow('Autres frais facture', tour.additionalInvoiceFees),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            Icons.local_shipping_outlined,
            color: theme.colorScheme.error,
            size: 20,
          ),
        ),
        title: Text(
          'Tournée du ${dateFmt.format(tour.tourDate)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          tour.supplierName ?? 'Fournisseur inconnu',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '${fmt.format(tour.totalExpenses.round())} CFA',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune dépense enregistrée sur cette tournée'),
            )
          else
            ...rows.map(
              (row) => ListTile(
                dense: true,
                title: Text(row.label, style: theme.textTheme.bodyMedium),
                trailing: Text(
                  '${fmt.format(row.amount.round())} CFA',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),

          // Détail des dépenses de transport si > 1
          if (tour.transportExpenses.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Détail transport',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...tour.transportExpenses.map(
              (te) => ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_right, size: 16),
                title: Text(te.description, style: theme.textTheme.bodySmall),
                trailing: Text(
                  '${fmt.format(te.amount.round())} CFA',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExpenseRow {
  const _ExpenseRow(this.label, this.amount);
  final String label;
  final double amount;
}
