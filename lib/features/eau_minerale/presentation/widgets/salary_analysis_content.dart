import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/controller_providers.dart';
import '../../domain/entities/worker_monthly_stat.dart';

/// Widget affichant les analyses de salaires (Rapports ouvriers).
class SalaryAnalysisContent extends ConsumerStatefulWidget {
  const SalaryAnalysisContent({super.key});

  @override
  ConsumerState<SalaryAnalysisContent> createState() => _SalaryAnalysisContentState();
}

class _SalaryAnalysisContentState extends ConsumerState<SalaryAnalysisContent> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year, // Approximation for month picker
      // Note: standard Flutter doesn't have a built-in month picker, usually we pick a day and ignore it
      // or implement a custom dialog. For simplicity, standard picker is used.
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Column(
      children: [
        // Filtre de mois
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
            title: Text(
              DateFormat.yMMMM('fr_FR').format(_selectedMonth).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: OutlinedButton(
              onPressed: () => _selectMonth(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Changer de mois'),
            ),
          ),
        ),

        // Contenu
        FutureBuilder<List<WorkerMonthlyStat>>(
            future: ref.read(salaryControllerProvider).fetchWorkerMonthlyStats(_selectedMonth),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Erreur: ${snapshot.error}'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                         onPressed: () => setState(() {}),
                         child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              final stats = snapshot.data ?? [];

              if (stats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off_outlined, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune donnée pour ce mois',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Calcul des totaux
              final totalWorked = stats.fold(0, (sum, s) => sum + s.daysWorked);
              final totalAmount = stats.fold(0, (sum, s) => sum + s.totalEarned);
              final totalPaid = stats.fold(0, (sum, s) => sum + s.amountPaid);
              final totalRemaining = stats.fold(0, (sum, s) => sum + s.remainingAmount);

              return Column(
                children: [
                  // Cartes résumées
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Jours Travaillés',
                          value: totalWorked.toString(),
                          icon: Icons.work_history,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Montant Total',
                          value: currencyFormat.format(totalAmount),
                          icon: Icons.attach_money,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Déjà Payé',
                          value: currencyFormat.format(totalPaid),
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Reste à Payer',
                          value: currencyFormat.format(totalRemaining),
                          icon: Icons.pending_outlined,
                          color: totalRemaining > 0 ? Colors.orange : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Liste des ouvriers
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final stat = stats[index];
                          final progress = stat.totalEarned > 0 
                              ? stat.amountPaid / stat.totalEarned 
                              : 0.0;
                              
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                stat.workerName.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: theme.colorScheme.primary),
                              ),
                            ),
                            title: Text(stat.workerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${stat.daysWorked} jours travaillés'),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  color: stat.isFullyPaid ? Colors.green : Colors.orange,
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(stat.totalEarned),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  stat.isFullyPaid 
                                      ? 'Payé' 
                                      : 'Reste: ${currencyFormat.format(stat.remainingAmount)}',
                                  style: TextStyle(
                                    color: stat.isFullyPaid ? Colors.green : Colors.orange.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
