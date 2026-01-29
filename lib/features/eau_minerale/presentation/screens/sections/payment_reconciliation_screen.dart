import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/payment_status.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/services/payment_reconciliation_service.dart';
import '../../widgets/payment_status_badge.dart';
import 'package:intl/intl.dart';

/// Écran de réconciliation des paiements.
/// Affiche les jours de production non payés et les statistiques.
class PaymentReconciliationScreen extends ConsumerStatefulWidget {
  const PaymentReconciliationScreen({super.key});

  @override
  ConsumerState<PaymentReconciliationScreen> createState() =>
      _PaymentReconciliationScreenState();
}

class _PaymentReconciliationScreenState
    extends ConsumerState<PaymentReconciliationScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(productionSessionsStateProvider);
    final paymentsAsync = ref.watch(salaryStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réconciliation des Paiements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productionSessionsStateProvider);
              ref.invalidate(salaryStateProvider);
            },
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) => paymentsAsync.when(
          data: (salaryState) {
            final reconciliationService = PaymentReconciliationService();
            final report = reconciliationService.generateReport(
              sessions: sessions,
              payments: salaryState.productionPayments,
              startDate: _startDate,
              endDate: _endDate,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSelector(theme),
                  const SizedBox(height: 24),
                  _buildStatisticsCards(theme, report),
                  const SizedBox(height: 24),
                  _buildUnpaidDaysList(theme, report.unpaidDays),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Erreur: $error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48), // Fix infinite width
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(dateFormat.format(_startDate)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48), // Fix infinite width
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(dateFormat.format(_endDate)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(
    ThemeData theme,
    ReconciliationReport report,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'Jours non payés',
            report.unpaidDays.length.toString(),
            Icons.pending_actions,
            theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Jours payés',
            report.paidDays.length.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Montant dû',
            '${report.totalUnpaidAmount} FCFA',
            Icons.attach_money,
            theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidDaysList(ThemeData theme, List<ProductionDay> unpaidDays) {
    if (unpaidDays.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tous les jours sont payés !',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jours de production non payés',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidDays.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final day = unpaidDays[index];
                return _buildUnpaidDayTile(theme, day);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidDayTile(ThemeData theme, ProductionDay day) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ListTile(
      leading: PaymentStatusBadge(
        status: PaymentStatus.unpaid,
        showLabel: false,
      ),
      title: Text(dateFormat.format(day.date)),
      subtitle: Text(
        '${day.nombrePersonnes} personne(s) • ${day.coutTotalPersonnel} FCFA',
      ),
      trailing: Text(
        '${day.coutTotalPersonnel} FCFA',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
