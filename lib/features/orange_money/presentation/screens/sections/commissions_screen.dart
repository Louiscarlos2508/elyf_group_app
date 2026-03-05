import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../domain/entities/commission.dart';
import '../../widgets/commission_alerts_card.dart';
import '../../widgets/commission_declaration_dialog.dart';
import '../../widgets/commission_status_badge.dart';
import '../../../domain/services/commission_calculation_service.dart';
import '../../widgets/commission_form_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/providers/storage_provider.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Screen for managing commissions.
class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final enterpriseKey = enterpriseId ?? '';
    final theme = Theme.of(context);

    final statsAsync = ref.watch(commissionsStatisticsProvider(enterpriseKey));
    final commissionsAsync = ref.watch(commissionsProvider(enterpriseKey));
    final currentMonthAsync = ref.watch(
      currentMonthCommissionProvider((enterpriseKey)),
    );

    return activeEnterpriseAsync.when(
      data: (activeEnterprise) {
        final isParent = activeEnterprise?.type.canHaveChildren ?? false;

        if (!isParent) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
              slivers: [
                const ElyfModuleHeader(
                  title: 'Gestion des Commissions',
                  subtitle:
                      'Déclarez vos SMS opérateurs et suivez vos gains mensuels.',
                  module: EnterpriseModule.mobileMoney,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _buildMainContent(
                      context,
                      ref,
                      statsAsync,
                      commissionsAsync,
                      currentMonthAsync,
                      enterpriseKey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const ElyfModuleHeader(
                  title: 'Gestion des Commissions',
                  subtitle:
                      'Basculez entre vos commissions personnelles et le suivi des agences.',
                  module: EnterpriseModule.mobileMoney,
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                      tabs: const [
                        Tab(text: 'Mes Commissions'),
                        Tab(text: 'Suivi Agences'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildMainContent(
                      context,
                      ref,
                      statsAsync,
                      commissionsAsync,
                      currentMonthAsync,
                      enterpriseKey,
                    ),
                  ),
                  _AgenciesCommissionsTab(enterpriseId: enterpriseKey),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, __) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> statsAsync,
    AsyncValue<List<Commission>> commissionsAsync,
    AsyncValue<Commission?> currentMonthAsync,
    String enterpriseKey,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statsAsync.when(
          data: (stats) => Column(
            children: [
              const CommissionAlertsCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildKpiCards(stats, theme),
            ],
          ),
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: LoadingIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Période Actuelle',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        currentMonthAsync.when(
          data: (commission) => _buildCurrentMonthCard(context, commission),
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Historique',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildInfoCard(context),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ElyfStatsCard(
      label: 'Mois Passé (Validé)',
      value: CurrencyFormatter.formatFCFA(
        stats['lastMonthAmount'] as int? ?? 0,
      ),
      icon: Icons.history_rounded,
      color: theme.colorScheme.secondary,
      isGlass: isDark,
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
              Expanded(
                child: Row(
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (commission != null)
                CommissionStatusBadge(
                  status: commission.status,
                  discrepancyStatus: commission.discrepancyStatus,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  'Transactions',
                  (commission?.transactionsCount ?? 0).toString(),
                  icon: Icons.receipt_long_rounded,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (commission?.declaredAmount != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatBox(
                    context,
                    'Montant Déclaré (SMS)',
                    CurrencyFormatter.formatFCFA(commission!.declaredAmount!),
                    icon: Icons.message_rounded,
                    iconColor: theme.colorScheme.secondary,
                    valueColor: theme.colorScheme.secondary,
                  ),
                ),
              ] else ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'En attente du SMS de l\'opérateur',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (commission != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
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
    final theme = Theme.of(context);
    // 1. Bouton DÉCLARER (pour Agent)
    if (commission.status == CommissionStatus.estimated) {
      return Consumer(
        builder: (context, ref, child) {
          return ElevatedButton.icon(
            onPressed: () => _showDeclarationDialog(context, ref, commission),
            icon: const Icon(Icons.message),
            label: const Text('Déclarer montant SMS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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


  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    Color? valueColor,
    IconData? icon,
    Color? iconColor,
    bool isStatus = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: isStatus ? 13 : 16,
                fontWeight: FontWeight.w800,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontFamily: 'Outfit',
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final theme = Theme.of(context);
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
                Text(
                  'Historique des commissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCommissionDialog(context, ref, enterpriseId),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Déclarer Commission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune commission enregistrée',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Les commissions apparaitront ici une fois calculées.',
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

  Widget _buildCommissionItem(
    BuildContext context,
    WidgetRef ref,
    Commission commission,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.date_range, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CommissionCalculationService.formatPeriod(
                  DateTime.parse('${commission.period}-01'),
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    '${commission.transactionsCount} transactions',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          enterpriseName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: 'Outfit',
              ),
            ),
            if (commission.discrepancyPercentage != null &&
                commission.discrepancyPercentage != 0)
              Text(
                'Écart: ${commission.discrepancyPercentage!.toStringAsFixed(1)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: commission.discrepancyStatus ==
                          DiscrepancyStatus.ecartSignificatif
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // Action rapide contextuelle
        if (commission.status == CommissionStatus.estimated)
          IconButton(
            icon: Icon(Icons.message, color: theme.colorScheme.primary),
            onPressed: () => _showDeclarationDialog(context, ref, commission),
            tooltip: 'Déclarer',
          )
        else if (commission.status == CommissionStatus.declared)
          IconButton(
            icon: const Icon(Icons.payment, color: AppColors.success),
            onPressed: () {
               // TODO: Mark as paid directly or show payment dialog
            },
            tooltip: 'Payer',
          )
        else
          IconButton(
            icon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () {
              // TODO: Afficher détails commission
            },
          ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.info, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Déclaration des commissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Chaque mois, dès que vous recevez le SMS de notification de commissions de la part d\'Orange, veuillez renseigner le montant exact reçu et joindre une capture d\'écran du SMS comme preuve de déclaration.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
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

            // Upload photo file if provided (to Firebase Storage)
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

class _AgenciesCommissionsTab extends ConsumerStatefulWidget {
  const _AgenciesCommissionsTab({required this.enterpriseId});
  final String enterpriseId;

  @override
  ConsumerState<_AgenciesCommissionsTab> createState() =>
      _AgenciesCommissionsTabState();
}

class _AgenciesCommissionsTabState extends ConsumerState<_AgenciesCommissionsTab> {
  String _selectedPeriod = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(agencyCommissionsStatisticsProvider(_selectedPeriod));
    final commissionsAsync = ref.watch(agencyCommissionsProvider('$_selectedPeriod|'));
    final networkEnterprisesAsync = ref.watch(networkEnterprisesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodFilter(theme),
          const SizedBox(height: AppSpacing.lg),
          statsAsync.when(
            data: (stats) => _buildNetworkStats(stats, theme),
            loading: () => const Center(child: LoadingIndicator()),
            error: (e, __) => Center(child: Text('Erreur stats: $e')),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Déclarations du réseau',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          commissionsAsync.when(
            data: (commissions) {
                if (commissions.isEmpty) {
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                                children: [
                                    Icon(Icons.no_accounts_rounded, size: 48, color: theme.colorScheme.outline),
                                    const SizedBox(height: 12),
                                    Text('Aucune déclaration pour cette période', style: theme.textTheme.bodyMedium),
                                ],
                            ),
                        ),
                    );
                }
                return networkEnterprisesAsync.when(
                    data: (enterpriseNames) => Column(
                        children: commissions.map((c) => _buildAgencyCommissionItem(context, c, enterpriseNames[c.enterpriseId] ?? 'Agence Inconnue')).toList(),
                    ),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (e, __) => Center(child: Text('Erreur agences: $e')),
                );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (e, __) => Center(child: Text('Erreur: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter(ThemeData theme) {
      return ElyfCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
              children: [
                  Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text('Période:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  // Simple period picker (could be improved)
                  DropdownButton<String>(
                      value: _selectedPeriod,
                      underline: const SizedBox(),
                      onChanged: (value) {
                          if (value != null) setState(() => _selectedPeriod = value);
                      },
                      items: _generatePeriods().map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                      )).toList(),
                  ),
              ],
          ),
      );
  }

  List<String> _generatePeriods() {
      final now = DateTime.now();
      return List.generate(6, (i) {
          final d = DateTime(now.year, now.month - i, 1);
          return '${d.year}-${d.month.toString().padLeft(2, '0')}';
      });
  }

  Widget _buildNetworkStats(Map<String, dynamic> stats, ThemeData theme) {
      final isDark = theme.brightness == Brightness.dark;
      return Row(
          children: [
              Expanded(
                  child: ElyfStatsCard(
                      label: 'Total Déclaré',
                      value: CurrencyFormatter.formatFCFA(stats['totalDeclared'] as int? ?? 0),
                      icon: Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                      isGlass: isDark,
                  ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: ElyfStatsCard(
                      label: 'Validé',
                      value: CurrencyFormatter.formatFCFA(stats['totalValidated'] as int? ?? 0),
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      isGlass: isDark,
                  ),
              ),
          ],
      );
  }

  Widget _buildAgencyCommissionItem(BuildContext context, Commission commission, String agencyName) {
      final theme = Theme.of(context);
      return ElyfCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                  children: [
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    agencyName, 
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text('Période: ${commission.period}', style: theme.textTheme.labelSmall),
                              ],
                          ),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                              Text(CurrencyFormatter.formatFCFA(commission.finalAmount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                              const SizedBox(height: AppSpacing.xs),
                              CommissionStatusBadge(status: commission.status),
                          ],
                      ),
                      if (commission.smsProofUrl != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                              onPressed: () => _showProofPhoto(context, commission.smsProofUrl!),
                              icon: Icon(Icons.image_rounded, color: theme.colorScheme.secondary),
                              tooltip: 'Voir preuve',
                          ),
                      ],
                  ],
              ),
          ),
      );
  }

  void _showProofPhoto(BuildContext context, String url) {
      showDialog(
          context: context,
          builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                              child: Image.network(url, fit: BoxFit.contain),
                          ),
                      ),
                      Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, color: Colors.white),
                              ),
                          ),
                      ),
                  ],
              ),
          ),
      );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
