import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/commission.dart';
import '../../widgets/commission_alerts_card.dart';
import '../../widgets/commission_declaration_dialog.dart';
import '../../widgets/commission_status_badge.dart';
import '../../widgets/commission_validation_dialog.dart';
import '../../../domain/services/commission_calculation_service.dart';
import '../../widgets/commission_form_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/providers/storage_provider.dart';
import '../../widgets/orange_money_header.dart';

/// Screen for managing commissions.
class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseKey = enterpriseId ?? '';
    final theme = Theme.of(context);

    final statsAsync = ref.watch(commissionsStatisticsProvider(enterpriseKey));
    final commissionsAsync = ref.watch(commissionsProvider(enterpriseKey));
    final currentMonthAsync = ref.watch(
      currentMonthCommissionProvider((enterpriseKey)),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          OrangeMoneyHeader(
            title: 'Gestion des Commissions',
            subtitle: 'Consultez vos estimations, déclarez vos SMS et validez vos gains mensuels.',
            badgeText: 'COMMISSIONS',
            badgeIcon: Icons.payments_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        const CommissionAlertsCard(),
                        const SizedBox(height: 32),
                        _buildKpiCards(stats, theme),
                      ],
                    ),
                    loading: () => const SizedBox(
                      height: 140,
                      child: Center(child: LoadingIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Période Actuelle',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  currentMonthAsync.when(
                    data: (commission) =>
                        _buildCurrentMonthCard(context, commission),
                    loading: () =>
                        const Center(child: LoadingIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Historique',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  commissionsAsync.when(
                    data: (commissions) => _buildCommissionsHistory(
                      context,
                      ref,
                      enterpriseKey,
                      commissions,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingIndicator(),
                      ),
                    ),
                    error: (error, stack) =>
                        Center(child: Text('Erreur: $error')),
                  ),
                  const SizedBox(height: 40),
                  _buildInfoCard(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElyfStatsCard(
                label: 'Estimé (Mois)',
                value: CurrencyFormatter.formatFCFA(
                  stats['estimatedAmount'] as int? ?? 0,
                ),
                icon: Icons.calculate_rounded,
                color: theme.colorScheme.primary,
                isGlass: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfStatsCard(
                label: 'Déclaré (Attente)',
                value: CurrencyFormatter.formatFCFA(
                  stats['declaredAmount'] as int? ?? 0,
                ),
                icon: Icons.pending_actions_rounded,
                color: theme.colorScheme.secondary,
                isGlass: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElyfStatsCard(
                label: 'Validé (Dû)',
                value: CurrencyFormatter.formatFCFA(
                  stats['validatedAmount'] as int? ?? 0,
                ),
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF00C897),
                isGlass: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfStatsCard(
                label: 'Payé (Total)',
                value: CurrencyFormatter.formatFCFA(
                  stats['paidAmount'] as int? ?? 0,
                ),
                icon: Icons.payments_rounded,
                color: theme.colorScheme.tertiary,
                isGlass: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentMonthCard(BuildContext context, Commission? commission) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final periodLabel = CommissionCalculationService.formatPeriodForDisplay(now);

    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_month_rounded,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mois en cours',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        periodLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (commission != null)
                CommissionStatusBadge(
                  status: commission.status,
                  discrepancyStatus: commission.discrepancyStatus,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Transactions',
                  (commission?.transactionsCount ?? 0).toString(),
                  icon: Icons.receipt_long_rounded,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBox(
                  'Estimé (Système)',
                  CurrencyFormatter.formatFCFA(
                    commission?.estimatedAmount ?? 0,
                  ),
                  icon: Icons.calculate_rounded,
                  iconColor: theme.colorScheme.primary,
                  valueColor: theme.colorScheme.primary,
                ),
              ),
              if (commission?.declaredAmount != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatBox(
                    'Décl. (SMS)',
                    CurrencyFormatter.formatFCFA(commission!.declaredAmount!),
                    icon: Icons.message_rounded,
                    iconColor: theme.colorScheme.secondary,
                    valueColor: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
          if (commission != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButtons(context, commission),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Commission commission) {
    // 1. Bouton DÉCLARER (pour Agent)
    if (commission.status == CommissionStatus.estimated) {
      return Consumer(
        builder: (context, ref, child) {
          return ElevatedButton.icon(
            onPressed: () => _showDeclarationDialog(context, ref, commission),
            icon: const Icon(Icons.message),
            label: const Text('Déclarer montant SMS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          );
        },
      );
    }

    // 2. Bouton VALIDER (pour Superviseur)
    if (commission.status == CommissionStatus.declared ||
        commission.status == CommissionStatus.disputed) {
      return Consumer(
        builder: (context, ref, child) {
          final canValidateAsync = ref.watch(canValidateCommissionProvider);

          return canValidateAsync.when(
            data: (canValidate) {
              if (canValidate) {
                return ElevatedButton.icon(
                  onPressed: () => _showValidationDialog(context, ref, commission),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Valider Commission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showDeclarationDialog(
    BuildContext context,
    WidgetRef ref,
    Commission commission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CommissionDeclarationDialog(commission: commission),
    );

    if (result == true) {
      ref.invalidate(commissionsProvider(enterpriseId ?? ''));
      ref.invalidate(commissionsStatisticsProvider(enterpriseId ?? ''));
      ref.invalidate(currentMonthCommissionProvider(enterpriseId ?? ''));
    }
  }

  Future<void> _showValidationDialog(
    BuildContext context,
    WidgetRef ref,
    Commission commission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CommissionValidationDialog(commission: commission),
    );

    if (result == true) {
      ref.invalidate(commissionsProvider(enterpriseId ?? ''));
      ref.invalidate(commissionsStatisticsProvider(enterpriseId ?? ''));
      ref.invalidate(currentMonthCommissionProvider(enterpriseId ?? ''));
    }
  }

  Widget _buildStatBox(
    String label,
    String value, {
    String? subtitle,
    Color? valueColor,
    IconData? icon,
    Color? iconColor,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? Colors.grey),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isStatus ? 14 : 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF101828),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6A7282),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionsHistory(
    BuildContext context,
    WidgetRef ref,
    String enterpriseId,
    List<Commission> commissions,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique des commissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                // Note: Bouton "Ajouter commission" supprimé en faveur du mode hybride
                // Si besoin, on pourrait ajouter un bouton "Calculer commissions"
              ],
            ),
            const SizedBox(height: 16),
            if (commissions.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commissions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final commission = commissions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _buildCommissionItem(context, ref, commission),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commission enregistrée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les commissions apparaitront ici une fois calculées.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionItem(
    BuildContext context,
    WidgetRef ref,
    Commission commission,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.date_range, color: Colors.black54),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CommissionCalculationService.formatPeriod(
                  DateTime.parse('${commission.period}-01'),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${commission.transactionsCount} transactions',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommissionStatusBadge(
                    status: commission.status,
                    discrepancyStatus: commission.discrepancyStatus,
                    showWarningIcon: true,
                  ),
                ],
              ),
              // Display enterprise name if in network view
              Consumer(
                builder: (context, ref, _) {
                  final enterprisesMap = ref.watch(networkEnterprisesProvider).value ?? {};
                  final enterpriseName = enterprisesMap[commission.enterpriseId];
                  
                  if (enterpriseName != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          enterpriseName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatFCFA(
                commission.declaredAmount ?? commission.estimatedAmount,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (commission.discrepancyPercentage != null &&
                commission.discrepancyPercentage != 0)
              Text(
                'Écart: ${commission.discrepancyPercentage!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: commission.discrepancyStatus ==
                          DiscrepancyStatus.ecartSignificatif
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // Action rapide contextuelle
        if (commission.status == CommissionStatus.estimated)
          IconButton(
            icon: const Icon(Icons.message, color: Colors.blue),
            onPressed: () => _showDeclarationDialog(context, ref, commission),
            tooltip: 'Déclarer',
          )
        else if (commission.status == CommissionStatus.declared)
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _showValidationDialog(context, ref, commission),
            tooltip: 'Valider',
          )
        else
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              // TODO: Afficher détails commission
            },
          ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 1, 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBEDBFF), width: 1.22),
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
            child: const Icon(Icons.info, color: Color(0xFF1C398E), size: 20),
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

            // ✅ TODO résolu: Upload photo file if provided (to Firebase Storage)
            String? photoUrl;
            if (photoFile != null) {
              try {
                final storageService = ref.read(storageServiceProvider);
                final fileName = 'commission_${DateTime.now().millisecondsSinceEpoch}.jpg';
                
                photoUrl = await storageService.uploadFile(
                  file: photoFile,
                  fileName: fileName,
                  enterpriseId: enterpriseId,
                  moduleId: 'orange_money',
                  subfolder: 'commissions',
                  contentType: 'image/jpeg',
                  metadata: {
                    'period': period,
                    'uploadedAt': DateTime.now().toIso8601String(),
                  },
                );
              } catch (uploadError) {
                if (!context.mounted) return;
                NotificationService.showWarning(
                  context,
                  'Photo non uploadée: $uploadError',
                );
                // Continue without photo
              }
            }

            final commission = Commission(
              id: 'commission_${DateTime.now().millisecondsSinceEpoch}',
              period: period,
              declaredAmount: amount,
              status: CommissionStatus.declared,
              transactionsCount: 0, // Manual commission
              estimatedAmount: 0, // Manual commission
              enterpriseId: enterpriseId,
              smsProofUrl: photoUrl, // URL de la photo uploadée
              notes: notes,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await controller.createCommission(commission);

            // Invalidate providers to refresh the list
            ref.invalidate(commissionsProvider(enterpriseId));
            ref.invalidate(commissionsStatisticsProvider(enterpriseId));
            ref.invalidate(currentMonthCommissionProvider((enterpriseId)));

            if (!context.mounted) return;
            NotificationService.showSuccess(
              context,
              'Commission enregistrée avec succès',
            );
          } catch (e) {
            if (!context.mounted) return;
            NotificationService.showError(
              context,
              'Erreur lors de l\'enregistrement: $e',
            );
          }
        },
      ),
    );
  }
}
