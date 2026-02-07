import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
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

            return CustomScrollView(
              slivers: [
                // Premium Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          const Color(0xFF00C2FF), // Cyan for Water Module
                          const Color(0xFF0369A1), // Deep Blue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const BackButton(color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "RÉCONCILIATION",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Audit des Paiements",
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ref.invalidate(
                                        productionSessionsStateProvider);
                                    ref.invalidate(salaryStateProvider);
                                  },
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: Colors.white),
                                  tooltip: 'Actualiser',
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Date Selector embedded in Header
                            _buildHeaderDateSelector(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Statistics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStatisticsCards(theme, report),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Unpaid Days List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildUnpaidDaysList(theme, report.unpaidDays),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
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

  Widget _buildHeaderDateSelector(ThemeData theme) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr');
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateButton(
            context,
            label: dateFormat.format(_startDate),
            date: _startDate,
            onChanged: (d) => setState(() => _startDate = d),
            isStart: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ),
          _buildDateButton(
            context,
            label: dateFormat.format(_endDate),
            date: _endDate,
            onChanged: (d) => setState(() => _endDate = d),
            isStart: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
    required bool isStart,
  }) {
    return InkWell(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (newDate != null) {
          onChanged(newDate);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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
            'Non payés',
            report.unpaidDays.length.toString(),
            'Jours',
            Icons.pending_actions_rounded,
            theme.colorScheme.error,
            theme.colorScheme.errorContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Montant Dû',
            '${(report.totalUnpaidAmount / 1000).toStringAsFixed(1)}k',
            'FCFA',
            Icons.attach_money_rounded,
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    Color containerColor,
  ) {
    return ElyfCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: theme.colorScheme.surface,
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: containerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidDaysList(ThemeData theme, List<ProductionDay> unpaidDays) {
    if (unpaidDays.isEmpty) {
      return ElyfCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.green.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tout est à jour !',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aucun paiement en attente sur cette période.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Jours en attente (${unpaidDays.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: unpaidDays.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final day = unpaidDays[index];
            return _buildUnpaidDayTile(theme, day);
          },
        ),
      ],
    );
  }

  Widget _buildUnpaidDayTile(ThemeData theme, ProductionDay day) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr');
    return ElyfCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      borderColor: theme.colorScheme.error.withValues(alpha: 0.2),
      backgroundColor: theme.colorScheme.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateFormat.format(day.date).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.nombrePersonnes} personne(s)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Production non réglée',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${day.coutTotalPersonnel} F',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
