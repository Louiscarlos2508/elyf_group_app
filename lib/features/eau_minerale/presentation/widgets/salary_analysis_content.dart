import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import '../../../../shared/utils/notification_service.dart';
import '../../application/providers/repository_providers.dart';

import '../../application/providers/state_providers.dart';
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
        // Filtre de mois - Modernized
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 24),
            ),
            title: Text(
              DateFormat.yMMMM('fr_FR').format(_selectedMonth).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Text(
              'Période d\'analyse',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: FilledButton.tonalIcon(
              onPressed: () => _selectMonth(context),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text('Modifier'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Contenu
        ref.watch(workerMonthlyStatsProvider(_selectedMonth)).when(
          data: (stats) {
            if (stats.isEmpty) {
              return _EmptyStatsPlaceholder();
            }

            // Calcul des totaux
            final totalAmount = stats.fold(0, (sum, s) => sum + s.totalEarned);
            final totalPaid = stats.fold(0, (sum, s) => sum + s.amountPaid);
            final totalRemaining = stats.fold(0, (sum, s) => sum + s.remainingAmount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartes résumées - Modernized
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _AnalysisSummaryCard(
                      label: 'TOTAL DÛ',
                      value: CurrencyFormatter.formatFCFA(totalAmount),
                      icon: Icons.payments_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    _AnalysisSummaryCard(
                      label: 'RESTE À PAYER',
                      value: CurrencyFormatter.formatFCFA(totalRemaining),
                      icon: Icons.pending_actions_rounded,
                        color: totalRemaining > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'DÉTAILS PAR OUVRIER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des ouvriers
                ...stats.map((stat) {
                    final isUnknown = stat.workerName.startsWith('Ouvrier inconnu') || 
                                     (stat.workerName.startsWith('Ouvrier ') && stat.workerName.contains(stat.workerId));
                    return _WorkerStatCard(
                      stat: stat,
                      currencyFormat: currencyFormat,
                      onTap: isUnknown ? () => _showNameCorrectionDialog(context, stat) : null,
                    );
                }),
              ],
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          )),
          error: (error, _) => _ErrorState(error: error, onRetry: () => ref.invalidate(workerMonthlyStatsProvider(_selectedMonth))),
        ),
      ],
    );
  }

  Future<void> _showNameCorrectionDialog(BuildContext context, WorkerMonthlyStat stat) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Attempt to fetch existing details to preserve salary/phone if any
    try {
      final repo = ref.read(dailyWorkerRepositoryProvider);
      final existingWorker = await repo.fetchWorkerById(stat.workerId);
      if (existingWorker != null) {
        if (!existingWorker.name.startsWith('Ouvrier inconnu')) {
           nameController.text = existingWorker.name;
        }
        phoneController.text = existingWorker.phone;
      }
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corriger l\'ouvrier'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ID: ${stat.workerId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'ouvrier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final repo = ref.read(dailyWorkerRepositoryProvider);
                  
                  // Fetch again to ensure we don't overwrite concurrent changes
                  // and to get the correct salarioJournalier
                  final current = await repo.fetchWorkerById(stat.workerId);
                  
                  final newWorker = DailyWorker(
                    id: stat.workerId,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    salaireJournalier: current?.salaireJournalier ?? 0,
                    joursTravailles: current?.joursTravailles ?? [],
                    createdAt: current?.createdAt,
                  );

                  await repo.createWorker(newWorker);

                  if (context.mounted) {
                    Navigator.pop(context);
                    NotificationService.showSuccess(
                        context, 'Informations mises à jour');
                    ref.invalidate(workerMonthlyStatsProvider);
                    ref.invalidate(allDailyWorkersProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    NotificationService.showError(
                        context, 'Erreur: $e');
                  }
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerStatCard extends StatelessWidget {
  const _WorkerStatCard({
    required this.stat,
    required this.currencyFormat,
    this.onTap,
  });
  
  final WorkerMonthlyStat stat;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = stat.totalEarned > 0 ? stat.amountPaid / stat.totalEarned : 0.0;
    
    // Show visual cue for unknown workers
    final isUnknown = stat.workerName.startsWith('Ouvrier inconnu') || 
                      (stat.workerName.startsWith('Ouvrier ') && stat.workerName.contains(stat.workerId));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnknown ? theme.colorScheme.errorContainer.withValues(alpha: 0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnknown ? theme.colorScheme.error : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isUnknown ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Text(
                  stat.workerName.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.workerName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${stat.daysWorked} jours travaillés',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(stat.totalEarned),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (stat.isFullyPaid)
                    const Text('PAYÉ', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900))
                  else
                    Text(
                      'Reste: ${currencyFormat.format(stat.remainingAmount)}',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              color: stat.isFullyPaid ? Colors.green : Colors.orange,
              minHeight: 6,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _EmptyStatsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Pas de données pour ce mois',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Impossible de charger les statistiques'),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
