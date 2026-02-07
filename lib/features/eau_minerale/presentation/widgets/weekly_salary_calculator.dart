import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_payment_person.dart';
import '../../domain/entities/weekly_salary_info.dart';
import 'payment_signature_dialog.dart';

/// Widget pour calculer et afficher les salaires hebdomadaires des ouvriers journaliers.
class WeeklySalaryCalculator extends ConsumerStatefulWidget {
  const WeeklySalaryCalculator({super.key, this.selectedWeek});

  final DateTime? selectedWeek;

  @override
  ConsumerState<WeeklySalaryCalculator> createState() =>
      _WeeklySalaryCalculatorState();
}

class _WeeklySalaryCalculatorState
    extends ConsumerState<WeeklySalaryCalculator> {
  DateTime _selectedWeek = DateTime.now();
  @override
  void initState() {
    super.initState();
    if (widget.selectedWeek != null) {
      _selectedWeek = widget.selectedWeek!;
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Utiliser le nouveau provider qui gère la résolution asynchrone des ouvriers
    final salariesAsync = ref.watch(weeklySalariesProvider(_selectedWeek));

    return salariesAsync.when(
      data: (salariesList) {
        // Convert to map for compatibility if needed, but list is fine
        final Map<String, WeeklySalaryInfo> salaries = { for (var s in salariesList) s.workerId : s };
        
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

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Map<String, WeeklySalaryInfo> salaries,
    int total,
  ) {
    return Column(
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
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (salaries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
            ),
          )
        else ...[
          ...salaries.values.map(
            (info) => _SalaryCard(
              info: info,
              onPay: () => _showPaymentDialog(context, info),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  _showBulkPaymentDialog(context, salaries.values.toList()),
              icon: const Icon(Icons.payment),
              label: const Text('Payer tous les ouvriers'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
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
      // Le ref.watch(productionSessionsInPeriodProvider) s'occupera du rafraîchissement
    }
  }

  void _showPaymentDialog(BuildContext context, WeeklySalaryInfo info) {
    // Check if worker name is unknown/missing
    if (info.workerName.startsWith('Ouvrier inconnu') || 
       (info.workerName.startsWith('Ouvrier ') && info.workerName.contains(info.workerId))) {
       _showNameCorrectionDialog(context, info);
       return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => PaymentSignatureDialog(
        workerName: info.workerName,
        amount: info.totalSalary,
        daysWorked: info.daysWorked,
        week: _selectedWeek,
        onPaid: (signature, signerName) async {
          // Utilisation d'un ID temporaire, le repository en générera un réel si besoin
          final paymentId = 'local_${DateTime.now().millisecondsSinceEpoch}';
          
          final payment = ProductionPayment(
            id: paymentId,
            period: _formatWeek(_selectedWeek),
            paymentDate: DateTime.now(),
            persons: [
              ProductionPaymentPerson(
                workerId: info.workerId,
                name: info.workerName,
                pricePerDay: info.dailySalary,
                daysWorked: info.daysWorked,
                totalAmount: info.totalSalary,
              )
            ],
            signature: signature,
            signerName: signerName, // Ajout du nom du signataire
            isVerified: true, // Auto-verified by signature
            verifiedAt: DateTime.now(),
            sourceProductionDayIds: info.productionDayIds,
          );
          
          try {
            await ref.read(salaryControllerProvider).createProductionPayment(payment);
            
            if (context.mounted) {
              Navigator.of(context).pop();
              NotificationService.showSuccess(
                context,
                'Paiement de ${info.workerName} enregistré avec signature',
              );
              
              // Invalider le provider pour recharger les sessions et faire disparaître le paiement
              final debutSemaine = _getStartOfWeek(_selectedWeek);
              final finSemaine = debutSemaine.add(const Duration(days: 6));
              ref.invalidate(productionSessionsInPeriodProvider((
                start: debutSemaine,
                end: finSemaine,
              )));
              // Aussi invalider l'historique global des paiements et sessions
              ref.invalidate(salaryStateProvider);
              ref.invalidate(productionSessionsStateProvider);
            }
          } catch (e) {
            if (context.mounted) {
              NotificationService.showError(context, 'Erreur lors du paiement: $e');
            }
          }
        },
      ),
    );
  }

  void _showBulkPaymentDialog(
    BuildContext context,
    List<WeeklySalaryInfo> salaries,
  ) {
    final total = salaries.fold<int>(0, (sum, info) => sum + info.totalSalary);

    showDialog(
      context: context,
      builder: (dialogContext) => PaymentSignatureDialog(
        workerName: 'Tous les ouvriers (${salaries.length})',
        amount: total,
        daysWorked: salaries.fold<int>(0, (sum, info) => sum + info.daysWorked),
        week: _selectedWeek,
        onPaid: (signature, signerName) async {
          final paymentId = 'local_${DateTime.now().millisecondsSinceEpoch}';
          
          final allProductionDayIds = salaries
              .expand((s) => s.productionDayIds)
              .toList();
              
          final persons = salaries.map((s) => ProductionPaymentPerson(
            workerId: s.workerId,
            name: s.workerName,
            pricePerDay: s.dailySalary,
            daysWorked: s.daysWorked,
            totalAmount: s.totalSalary,
          )).toList();

          final payment = ProductionPayment(
            id: paymentId,
            period: _formatWeek(_selectedWeek),
            paymentDate: DateTime.now(),
            persons: persons,
            signature: signature,
            signerName: signerName, // Ajout du nom du signataire
            isVerified: true,
            verifiedAt: DateTime.now(),
            sourceProductionDayIds: allProductionDayIds,
          );
          
          try {
            await ref.read(salaryControllerProvider).createProductionPayment(payment);
            
            if (context.mounted) {
              Navigator.of(context).pop();
              NotificationService.showSuccess(
                context,
                'Tous les paiements enregistrés avec signature',
              );
              
              // Invalider les providers
              final debutSemaine = _getStartOfWeek(_selectedWeek);
              final finSemaine = debutSemaine.add(const Duration(days: 6));
              ref.invalidate(productionSessionsInPeriodProvider((
                start: debutSemaine,
                end: finSemaine,
              )));
              ref.invalidate(salaryStateProvider);
              ref.invalidate(productionSessionsStateProvider);
            }
          } catch (e) {
            if (context.mounted) {
              NotificationService.showError(context, 'Erreur lors du paiement groupé: $e');
            }
          }
        },
      ),
    );
  }

  void _showNameCorrectionDialog(BuildContext context, WeeklySalaryInfo info) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Informations ouvrier manquantes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${info.workerId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Veuillez entrer les informations pour continuer le paiement.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
               final name = nameController.text.trim();
               final phone = phoneController.text.trim();
               
               if (name.isEmpty) return;
               Navigator.pop(dialogContext);
               
               try {
                 final worker = DailyWorker(
                    id: info.workerId,
                    name: name,
                    phone: phone, 
                    salaireJournalier: info.dailySalary,
                    joursTravailles: [],
                 );
                 
                 await ref.read(dailyWorkerRepositoryProvider).createWorker(worker);
                 
                 ref.invalidate(allDailyWorkersProvider);
                 ref.invalidate(weeklySalariesProvider(_selectedWeek));
                 ref.invalidate(salaryStateProvider);
                 ref.invalidate(productionSessionsStateProvider);

                 if (context.mounted) {
                   NotificationService.showSuccess(context, 'Informations enregistrées avec succès');
                 }
               } catch (e) {
                 if (context.mounted) {
                   NotificationService.showError(context, 'Erreur: $e');
                 }
               }
            },
            child: const Text('Enregistrer'),
          ),
        ],
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


class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.info, required this.onPay});

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
                    minimumSize: const Size(0, 36), // Fix crash
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0, // Reduced vertical padding for compact look
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
