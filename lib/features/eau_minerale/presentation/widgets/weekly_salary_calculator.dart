import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/production_session.dart';
import 'payment_signature_dialog.dart';

/// Widget pour calculer et afficher les salaires hebdomadaires des ouvriers journaliers.
class WeeklySalaryCalculator extends ConsumerStatefulWidget {
  const WeeklySalaryCalculator({
    super.key,
    this.selectedWeek,
  });

  final DateTime? selectedWeek;

  @override
  ConsumerState<WeeklySalaryCalculator> createState() =>
      _WeeklySalaryCalculatorState();
}

class _WeeklySalaryCalculatorState
    extends ConsumerState<WeeklySalaryCalculator> {
  DateTime _selectedWeek = DateTime.now();
  List<ProductionSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedWeek != null) {
      _selectedWeek = widget.selectedWeek!;
    }
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final controller = ref.read(productionSessionControllerProvider);
      final debutSemaine = _getStartOfWeek(_selectedWeek);
      final finSemaine = debutSemaine.add(const Duration(days: 6));
      
      final sessions = await controller.fetchSessions(
        startDate: debutSemaine,
        endDate: finSemaine,
      );
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Calcule les salaires hebdomadaires à partir des ProductionDay
  Map<String, WeeklySalaryInfo> _calculateWeeklySalaries(List<DailyWorker> workers) {
    final salaries = <String, WeeklySalaryInfo>{};
    final debutSemaine = _getStartOfWeek(_selectedWeek);
    final finSemaine = debutSemaine.add(const Duration(days: 6));

    // Créer une map pour accéder rapidement aux ouvriers par ID
    final workersMap = {for (var w in workers) w.id: w};

    for (final session in _sessions) {
      for (final day in session.productionDays) {
        // Vérifier si le jour est dans la semaine sélectionnée
        if (day.date.isAfter(debutSemaine.subtract(const Duration(days: 1))) &&
            day.date.isBefore(finSemaine.add(const Duration(days: 1)))) {
          
          // Pour chaque personne dans le jour de production
          for (final workerId in day.personnelIds) {
            final worker = workersMap[workerId];
            final workerName = worker?.name ?? 'Ouvrier $workerId';
            
            if (!salaries.containsKey(workerId)) {
              salaries[workerId] = WeeklySalaryInfo(
                workerId: workerId,
                workerName: workerName,
                daysWorked: 0,
                dailySalary: day.salaireJournalierParPersonne,
                totalSalary: 0,
              );
            }
            
            final info = salaries[workerId]!;
            salaries[workerId] = WeeklySalaryInfo(
              workerId: workerId,
              workerName: workerName,
              daysWorked: info.daysWorked + 1,
              dailySalary: day.salaireJournalierParPersonne,
              totalSalary: (info.daysWorked + 1) * day.salaireJournalierParPersonne,
            );
          }
        }
      }
    }

    return salaries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Utiliser ref.watch pour que le widget se reconstruise quand les ouvriers changent
    final workersAsync = ref.watch(allDailyWorkersProvider);
    
    return workersAsync.when(
      data: (workers) {
        final salaries = _calculateWeeklySalaries(workers);
    final total = salaries.values.fold<int>(
      0,
      (sum, info) => sum + info.totalSalary,
    );
        
        return _buildContent(context, theme, salaries, total);
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('Erreur: $error')),
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, ThemeData theme, Map<String, WeeklySalaryInfo> salaries, int total) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salaires Hebdomadaires',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Semaine du ${_formatDate(_getStartOfWeek(_selectedWeek))}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _selectWeek(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatWeek(_selectedWeek)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (salaries.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun salaire à calculer pour cette semaine',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...salaries.values.map((info) => _SalaryCard(
                    info: info,
                    onPay: () => _showPaymentDialog(context, info),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total à payer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$total CFA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showBulkPaymentDialog(context, salaries.values.toList()),
                icon: const Icon(Icons.payment),
                label: const Text('Payer tous les ouvriers'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectWeek(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeek,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Sélectionner une semaine',
    );
    if (picked != null) {
      setState(() => _selectedWeek = picked);
      _loadSessions();
    }
  }

  void _showPaymentDialog(BuildContext context, WeeklySalaryInfo info) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentSignatureDialog(
        workerName: info.workerName,
        amount: info.totalSalary,
        daysWorked: info.daysWorked,
        week: _selectedWeek,
        onPaid: (signature) {
          // TODO: Enregistrer le paiement avec la signature
          Navigator.of(context).pop();
          NotificationService.showSuccess(context, 'Paiement enregistré avec signature');
        },
      ),
    );
  }

  void _showBulkPaymentDialog(
    BuildContext context,
    List<WeeklySalaryInfo> salaries,
  ) {
    final total = salaries.fold<int>(
      0,
      (sum, info) => sum + info.totalSalary,
    );
    
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentSignatureDialog(
        workerName: 'Tous les ouvriers (${salaries.length})',
        amount: total,
        daysWorked: salaries.fold<int>(0, (sum, info) => sum + info.daysWorked),
        week: _selectedWeek,
        onPaid: (signature) {
          // TODO: Enregistrer tous les paiements avec la signature
          Navigator.of(context).pop();
          NotificationService.showSuccess(context, 'Tous les paiements enregistrés avec signature');
        },
      ),
    );
  }

  String _formatWeek(DateTime date) {
    final debut = _getStartOfWeek(date);
    final fin = debut.add(const Duration(days: 6));
    return '${_formatDate(debut)} - ${_formatDate(fin)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/// Informations sur le salaire hebdomadaire d'un ouvrier
class WeeklySalaryInfo {
  const WeeklySalaryInfo({
    required this.workerId,
    required this.workerName,
    required this.daysWorked,
    required this.dailySalary,
    required this.totalSalary,
  });

  final String workerId;
  final String workerName;
  final int daysWorked;
  final int dailySalary;
  final int totalSalary;
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({
    required this.info,
    required this.onPay,
  });

  final WeeklySalaryInfo info;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    info.workerName[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.workerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${info.daysWorked} jour${info.daysWorked > 1 ? 's' : ''} × ${CurrencyFormatter.formatFCFA(info.dailySalary)}/jour',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    CurrencyFormatter.formatFCFA(info.totalSalary),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Payer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
