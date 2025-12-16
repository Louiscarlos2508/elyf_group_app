import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/electricity_meter_type.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import 'production_period_formatter.dart';
import '../screens/sections/production_sessions_screen.dart';

/// Widget pour afficher un rapport détaillé d'une production spécifique.
class ProductionDetailReport extends ConsumerWidget {
  const ProductionDetailReport({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  String _formatDate(DateTime date) {
    return ProductionPeriodFormatter.formatDate(date);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Récupérer les dépenses liées à cette production
    final expensesAsync = ref.watch(financesStateProvider);
    final linkedExpenses = expensesAsync.maybeWhen(
      data: (data) => data.expenses
          .where((e) => e.productionId == session.id)
          .toList(),
      orElse: () => <ExpenseRecord>[],
    );
    
    // Récupérer toutes les sessions pour vérifier si les bobines viennent d'une session précédente
    final allSessionsAsync = ref.watch(productionSessionsStateProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rapport de Production',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Production du ${_formatDate(session.date)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: session.status),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          
          // Informations générales
          _SectionTitle(title: 'Informations Générales'),
          const SizedBox(height: 16),
          _InfoGrid(
            items: [
              _InfoItem(
                label: 'Date de début',
                value: _formatDate(session.date),
                icon: Icons.calendar_today,
              ),
              _InfoItem(
                label: 'Heure de début',
                value: _formatTime(session.heureDebut),
                icon: Icons.access_time,
              ),
              if (session.heureFin != null)
                _InfoItem(
                  label: 'Heure de fin',
                  value: _formatTime(session.heureFin!),
                  icon: Icons.check_circle,
                ),
              _InfoItem(
                label: 'Durée',
                value: '${session.dureeHeures.toStringAsFixed(1)} heures',
                icon: Icons.timer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Machines et bobines
          _SectionTitle(title: 'Machines et Bobines'),
          const SizedBox(height: 16),
          _InfoItem(
            label: 'Nombre de machines',
            value: '${session.machinesUtilisees.length}',
            icon: Icons.precision_manufacturing,
          ),
          const SizedBox(height: 12),
          allSessionsAsync.when(
            data: (allSessions) {
              return Column(
                children: session.bobinesUtilisees.map((bobine) {
                  // Vérifier si la bobine vient d'une session précédente
                  // On cherche dans toutes les sessions antérieures si cette machine a une bobine non finie
                  // de la même session (en triant de la plus récente à la plus ancienne)
                  final sessionsPrecedentes = allSessions.where(
                    (s) => s.date.isBefore(session.date) ||
                           (s.date.isAtSameMomentAs(session.date) &&
                            s.id != session.id),
                  ).toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  
                  bool estBobineReutilisee = false;
                  String? sessionOrigine;
                  
                  // Parcourir les sessions de la plus récente à la plus ancienne
                  // pour trouver la bobine non finie la plus récente sur cette machine
                  for (final s in sessionsPrecedentes) {
                    try {
                      // Chercher une bobine non finie sur cette machine dans cette session
                      final bobineDansSessionPrecedente = s.bobinesUtilisees.firstWhere(
                        (b) => b.machineId == bobine.machineId && !b.estFinie,
                      );
                      
                      // Si on trouve une bobine non finie sur cette machine,
                      // vérifier si c'est le même type (pour confirmer que c'est la même bobine)
                      if (bobineDansSessionPrecedente.bobineType == bobine.bobineType) {
                        estBobineReutilisee = true;
                        sessionOrigine = _formatDate(s.date);
                        break; // Prendre la session la plus récente
                      }
                    } catch (_) {
                      // Pas de bobine non finie trouvée sur cette machine dans cette session, continuer
                      continue;
                    }
                  }
                  
                  // Déterminer le statut à la clôture (seulement pour les sessions terminées)
                  String? statutCloture;
                  if (session.effectiveStatus == ProductionSessionStatus.completed) {
                    statutCloture = bobine.estFinie ? 'Finie' : 'Reste en machine';
                  }
                  
                  return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bobine.estFinie
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: estBobineReutilisee
                      ? Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          bobine.estFinie
                              ? Icons.check_circle
                              : Icons.rotate_right,
                          size: 20,
                          color: bobine.estFinie
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bobine.bobineType,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (estBobineReutilisee)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Réutilisée',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Machine: ${bobine.machineName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (estBobineReutilisee) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sessionOrigine != null
                                      ? 'Bobine non finie de la session du $sessionOrigine'
                                      : 'Bobine non finie d\'une session précédente',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (statutCloture != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bobine.estFinie
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Statut à la clôture: $statutCloture',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: bobine.estFinie
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Column(
              children: session.bobinesUtilisees.map((bobine) {
                // Fallback sans vérification des sessions précédentes
                final statutCloture = session.effectiveStatus == ProductionSessionStatus.completed
                    ? (bobine.estFinie ? 'Finie' : 'Reste en machine')
                    : null;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          bobine.estFinie ? Icons.check_circle : Icons.rotate_right,
                          size: 20,
                          color: bobine.estFinie ? Colors.green : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bobine.bobineType,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Machine: ${bobine.machineName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (statutCloture != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Statut à la clôture: $statutCloture',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: bobine.estFinie ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          
          // Consommation électrique
          if (session.consommationCourant > 0) ...[
            _SectionTitle(title: 'Consommation'),
            const SizedBox(height: 16),
            _ConsumptionInfoItem(session: session),
            const SizedBox(height: 24),
          ],
          
          // Personnel
          if (session.productionDays.isNotEmpty) ...[
            _SectionTitle(title: 'Personnel'),
            const SizedBox(height: 16),
            ...session.productionDays.map((day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${day.nombrePersonnes} personne(s) le ${_formatDate(day.date)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Salaire journalier: ${_formatCurrency(day.salaireJournalierParPersonne)}/personne',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Coût total: ${_formatCurrency(day.coutTotalPersonnel)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          // Dépenses liées
          if (linkedExpenses.isNotEmpty) ...[
            _SectionTitle(title: 'Dépenses Liées'),
            const SizedBox(height: 16),
            ...linkedExpenses.map((expense) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${expense.category.label} • ${_formatDate(expense.date)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(expense.amountCfa),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          // Résumé financier
          _SectionTitle(title: 'Résumé Financier'),
          const SizedBox(height: 16),
          _FinancialSummary(
            session: session,
            linkedExpenses: linkedExpenses,
            formatCurrency: _formatCurrency,
          ),
        ],
      ),
    );
  }
}

class _ConsumptionInfoItem extends ConsumerWidget {
  const _ConsumptionInfoItem({required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return _InfoItem(
          label: 'Consommation électrique',
          value: '${session.consommationCourant.toStringAsFixed(2)} ${meterType.unit}',
          icon: Icons.bolt,
        );
      },
      loading: () => _InfoItem(
        label: 'Consommation électrique',
        value: '${session.consommationCourant.toStringAsFixed(2)}',
        icon: Icons.bolt,
      ),
      error: (_, __) => _InfoItem(
        label: 'Consommation électrique',
        value: '${session.consommationCourant.toStringAsFixed(2)}',
        icon: Icons.bolt,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ProductionSessionStatus status;

  Color _getStatusColor() {
    switch (status) {
      case ProductionSessionStatus.draft:
        return Colors.grey;
      case ProductionSessionStatus.started:
        return Colors.blue;
      case ProductionSessionStatus.inProgress:
        return Colors.green;
      case ProductionSessionStatus.suspended:
        return Colors.orange;
      case ProductionSessionStatus.completed:
        return Colors.green.shade700;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case ProductionSessionStatus.draft:
        return Icons.edit_outlined;
      case ProductionSessionStatus.started:
        return Icons.play_circle_outline;
      case ProductionSessionStatus.inProgress:
        return Icons.sync;
      case ProductionSessionStatus.suspended:
        return Icons.pause_circle_outline;
      case ProductionSessionStatus.completed:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) => _InfoItem(
        label: item.label,
        value: item.value,
        icon: item.icon,
      )).toList(),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.session,
    required this.linkedExpenses,
    required this.formatCurrency,
  });

  final ProductionSession session;
  final List<ExpenseRecord> linkedExpenses;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final coutPersonnel = session.coutTotalPersonnel;
    final coutBobines = session.coutBobines ?? 0;
    final coutElectricite = session.coutElectricite ?? 0;
    final coutDepenses = linkedExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCfa,
    );
    final coutTotal = session.coutTotal + coutDepenses;
    
    // Revenus estimés basés sur la quantité produite (à adapter selon votre logique)
    final revenusEstimes = 0; // TODO: Calculer les revenus estimés
    final marge = revenusEstimes - coutTotal;
    final margePourcentage = revenusEstimes > 0
        ? (marge / revenusEstimes * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coûts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _CostRow(
            label: 'Personnel',
            amount: coutPersonnel,
            formatCurrency: formatCurrency,
          ),
          _CostRow(
            label: 'Bobines',
            amount: coutBobines,
            formatCurrency: formatCurrency,
          ),
          _CostRow(
            label: 'Électricité',
            amount: coutElectricite,
            formatCurrency: formatCurrency,
          ),
          if (coutDepenses > 0)
            _CostRow(
              label: 'Dépenses liées',
              amount: coutDepenses,
              formatCurrency: formatCurrency,
            ),
          const Divider(),
          _CostRow(
            label: 'Total des coûts',
            amount: coutTotal,
            formatCurrency: formatCurrency,
            isTotal: true,
          ),
          if (revenusEstimes > 0) ...[
            const SizedBox(height: 16),
            Text(
              'Revenus',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _CostRow(
              label: 'Revenus estimés',
              amount: revenusEstimes,
              formatCurrency: formatCurrency,
              isRevenue: true,
            ),
            const Divider(),
            _CostRow(
              label: 'Marge',
              amount: marge,
              formatCurrency: formatCurrency,
              isMargin: true,
              percentage: margePourcentage,
            ),
          ],
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.amount,
    required this.formatCurrency,
    this.isTotal = false,
    this.isRevenue = false,
    this.isMargin = false,
    this.percentage,
  });

  final String label;
  final int amount;
  final String Function(int) formatCurrency;
  final bool isTotal;
  final bool isRevenue;
  final bool isMargin;
  final double? percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.onSurface;
    
    if (isMargin) {
      color = amount >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    } else if (isRevenue) {
      color = Colors.green.shade700;
    } else if (isTotal) {
      color = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal || isMargin ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${percentage!.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


