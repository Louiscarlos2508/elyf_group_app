import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/commission.dart';
import '../../widgets/commission_form_dialog.dart';
import '../../widgets/kpi_card.dart';
import 'package:elyf_groupe_app/shared.dart';
/// Screen for managing commissions.
class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseKey = enterpriseId ?? '';
    
    final statsAsync = ref.watch(commissionsStatisticsProvider(enterpriseKey));
    final commissionsAsync = ref.watch(commissionsProvider(enterpriseKey));
    final currentMonthAsync = ref.watch(currentMonthCommissionProvider((enterpriseKey)));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statsAsync.when(
                  data: (stats) => _buildKpiCards(stats),
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                currentMonthAsync.when(
                  data: (commission) => _buildCurrentMonthCard(context, commission),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                commissionsAsync.when(
                  data: (commissions) =>
                      _buildCommissionsHistory(context, ref, enterpriseKey, commissions),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Erreur: $error'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'Périodes',
            value: (stats['periodsCount'] as int? ?? 0).toString(),
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'En attente',
            value: CurrencyFormatter.formatFCFA(stats['pendingAmount'] as int? ?? 0),
            icon: Icons.pending,
            valueColor: const Color(0xFFF54900),
            valueStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF54900),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Payées',
            value: CurrencyFormatter.formatFCFA(stats['paidAmount'] as int? ?? 0),
            icon: Icons.check_circle,
            valueColor: const Color(0xFF00A63E),
            valueStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A63E),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Estimé mois',
            value: CurrencyFormatter.formatFCFA(stats['estimatedAmount'] as int? ?? 0),
            icon: Icons.trending_up,
            valueColor: const Color(0xFF9810FA),
            valueStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9810FA),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentMonthCard(BuildContext context, Commission? commission) {
    final now = DateTime.now();
    final periodLabel = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        border: Border.all(
          color: const Color(0xFFE9D4FF),
          width: 1.22,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Color(0xFF59168B)),
              const SizedBox(width: 8),
              Text(
                'Mois en cours - $periodLabel',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF59168B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Transactions effectuées',
                  (commission?.transactionsCount ?? 0).toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBox(
                  'Commissions estimées',
                  CurrencyFormatter.formatFCFA(commission?.estimatedAmount ?? 0),
                  subtitle: 'Basé sur les transactions validées',
                  valueColor: const Color(0xFF9810FA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBox(
                  'Statut',
                  commission?.status.label ?? 'Pas encore calculée',
                  valueColor: const Color(0xFF6A7282),
                  isStatus: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value, {
    String? subtitle,
    Color? valueColor,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5565),
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isStatus ? 14 : 24,
              fontWeight: FontWeight.normal,
              color: valueColor ?? const Color(0xFF101828),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6A7282),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionsHistory(BuildContext context, WidgetRef ref, String enterpriseId, List<Commission> commissions) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Historique des commissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddCommissionDialog(context, ref, enterpriseId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter commission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF54900),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (commissions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commission enregistrée',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF6A7282),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les commissions sont calculées mensuellement par l\'administrateur',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF6A7282),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commissions.length,
                itemBuilder: (context, index) {
                  final commission = commissions[index];
                  return ListTile(
                    title: Text('Période: ${commission.period}'),
                    subtitle: Text(
                      '${commission.transactionsCount} transactions • ${commission.status.label}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatFCFA(commission.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: commission.isPaid
                                ? const Color(0xFF00A63E)
                                : const Color(0xFFF54900),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 1, 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(
          color: const Color(0xFFBEDBFF),
          width: 1.22,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.info,
              color: Color(0xFF1C398E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ℹ️ À propos des commissions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF1C398E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Les commissions sont calculées mensuellement par l\'administrateur selon les règles définies. Vous pouvez voir vos commissions estimées du mois en cours basées sur vos transactions validées.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF193CB8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCommissionDialog(
    BuildContext context,
    WidgetRef ref,
    String enterpriseId,
  ) {
    showDialog(
      context: context,
      builder: (context) => CommissionFormDialog(
        onSave: (period, amount, photoFile, notes) async {
          try {
            final controller = ref.read(commissionsControllerProvider);
            
            // TODO: Upload photo file if provided (to Firebase Storage or similar)
            // For now, we'll just create the commission without the photo
            
            final commission = Commission(
              id: 'commission_${DateTime.now().millisecondsSinceEpoch}',
              period: period,
              amount: amount,
              status: CommissionStatus.pending,
              transactionsCount: 0, // Manual commission
              estimatedAmount: 0, // Manual commission
              enterpriseId: enterpriseId,
              notes: notes,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await controller.createCommission(commission);

            // Invalidate providers to refresh the list
            ref.invalidate(commissionsProvider(enterpriseId));
            ref.invalidate(commissionsStatisticsProvider(enterpriseId));
            ref.invalidate(currentMonthCommissionProvider((enterpriseId)));

            if (context.mounted) {
              NotificationService.showSuccess(context, 'Commission enregistrée avec succès');
            }
          } catch (e) {
            if (context.mounted) {
              NotificationService.showError(context, 'Erreur lors de l\'enregistrement: $e');
            }
          }
        },
      ),
    );
  }
}

