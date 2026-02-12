import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';
import '../../widgets/liquidity_checkpoint_dialog.dart';
import '../../widgets/liquidity/liquidity_daily_activity_section.dart';
import '../../widgets/liquidity/liquidity_filters_card.dart';
import '../../widgets/liquidity/liquidity_checkpoints_list.dart';
import '../../widgets/liquidity/liquidity_empty_state.dart';
import '../../widgets/liquidity/liquidity_checkpoint_card.dart';
import '../../widgets/liquidity/liquidity_tabs.dart';
import '../../widgets/orange_money_header.dart';
import '../../widgets/liquidity/justification_dialog.dart';

/// Screen for managing liquidity checkpoints.
class LiquidityScreen extends ConsumerStatefulWidget {
  const LiquidityScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<LiquidityScreen> createState() => _LiquidityScreenState();
}

class _LiquidityScreenState extends ConsumerState<LiquidityScreen> {
  int _selectedTab = 0;
  String? _selectedPeriodFilter;
  DateTime? _selectedDateFilter;

  @override
  Widget build(BuildContext context) {
    final enterpriseKey = widget.enterpriseId ?? '';
    final theme = Theme.of(context);
    final todayCheckpointAsync = ref.watch(
      todayLiquidityCheckpointProvider(enterpriseKey),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final recentCheckpointsKey =
        '$enterpriseKey|${sevenDaysAgo.millisecondsSinceEpoch}|${today.millisecondsSinceEpoch}';
    final recentCheckpointsAsync = ref.watch(
      liquidityCheckpointsProvider((recentCheckpointsKey)),
    );

    final allCheckpointsKey = enterpriseKey.isEmpty ? '' : '$enterpriseKey||';
    final allCheckpointsAsync = ref.watch(
      liquidityCheckpointsProvider((allCheckpointsKey)),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          OrangeMoneyHeader(
            title: 'Suivi de Liquidité',
            subtitle: 'Contrôlez vos pointages matin et soir pour garantir la sécurité de vos fonds.',
            badgeText: 'LIQUIDITÉ',
            badgeIcon: Icons.water_drop_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTodayTrackingCard(context, todayCheckpointAsync, theme),
                const SizedBox(height: 24),
                _buildHistorySection(
                  context,
                  _selectedTab == 0 ? recentCheckpointsAsync : allCheckpointsAsync,
                  _selectedTab == 0 ? recentCheckpointsKey : allCheckpointsKey,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTrackingCard(
    BuildContext context,
    AsyncValue<LiquidityCheckpoint?> todayCheckpointAsync,
    ThemeData theme,
  ) {
    final today = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr');
    final formattedDate = dateFormat.format(today);

    final enterpriseKey = widget.enterpriseId ?? '';
    final todayMillis = DateTime(
      today.year,
      today.month,
      today.day,
    ).millisecondsSinceEpoch;
    final dailyStatsKey = '$enterpriseKey|$todayMillis';
    final dailyStatsAsync = ref.watch(
      dailyTransactionStatsProvider(dailyStatsKey),
    );

    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(formattedDate, theme),
          const SizedBox(height: 32),
          todayCheckpointAsync.when(
            data: (checkpoint) => _buildCheckpointCards(context, checkpoint),
            loading: () => const LoadingIndicator(),
            error: (error, stackTrace) => _buildCheckpointCards(context, null),
          ),
          const SizedBox(height: 32),
          todayCheckpointAsync.when(
            data: (checkpoint) => dailyStatsAsync.when(
              data: (stats) => LiquidityDailyActivitySection(
                checkpoint: checkpoint,
                stats: stats,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String formattedDate, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_month_rounded, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aujourd\'hui',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              formattedDate,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckpointCards(
    BuildContext context,
    LiquidityCheckpoint? checkpoint,
  ) {
    return Row(
      children: [
        Expanded(
          child: LiquidityCheckpointCard(
            title: 'Pointage Matin',
            icon: Icons.wb_sunny,
            iconColor: const Color(0xFFF54900),
            hasCheckpoint: checkpoint?.hasMorningCheckpoint ?? false,
            cashAmount: checkpoint?.morningCashAmount,
            simAmount: checkpoint?.morningSimAmount,
            onPressed: () => _showCheckpointDialog(
              context,
              LiquidityCheckpointType.morning,
              checkpoint,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LiquidityCheckpointCard(
            title: 'Pointage Soir',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF7C3AED),
            hasCheckpoint: checkpoint?.hasEveningCheckpoint ?? false,
            cashAmount: checkpoint?.eveningCashAmount,
            simAmount: checkpoint?.eveningSimAmount,
            requiresJustification: checkpoint?.requiresJustification ?? false,
            discrepancyPercentage: checkpoint?.discrepancyPercentage,
            onPressed: () => _showCheckpointDialog(
              context,
              LiquidityCheckpointType.evening,
              checkpoint,
            ),
            onJustifyPressed: checkpoint?.requiresJustification == true && !checkpoint!.isValidated
                ? () => _showJustificationDialog(context, checkpoint!)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    AsyncValue<List<LiquidityCheckpoint>> checkpointsAsync,
    String providerKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiquidityTabs(
          selectedTab: _selectedTab,
          onTabChanged: (tab) => setState(() => _selectedTab = tab),
        ),
        SizedBox(height: AppSpacing.xs),
        _buildHistoryContent(checkpointsAsync, providerKey),
      ],
    );
  }

  Widget _buildHistoryContent(
    AsyncValue<List<LiquidityCheckpoint>> checkpointsAsync,
    String providerKey,
  ) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedTab == 0
                ? '7 derniers jours'
                : 'Tous les pointages (${checkpointsAsync.value?.length ?? 0})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedTab == 1) ...[
            LiquidityFiltersCard(
              selectedPeriodFilter: _selectedPeriodFilter,
              selectedDateFilter: _selectedDateFilter,
              onPeriodFilterTap: _showPeriodFilterDialog,
              onDateFilterTap: () => _selectDateFilter(context),
              onResetFilters: () {
                setState(() {
                  _selectedPeriodFilter = null;
                  _selectedDateFilter = null;
                });
              },
            ),
            SizedBox(height: AppSpacing.md),
          ],
          checkpointsAsync.when(
            data: (checkpoints) {
              final filteredCheckpoints = _applyFilters(checkpoints);
              if (filteredCheckpoints.isEmpty) {
                return LiquidityEmptyState(isRecent: _selectedTab == 0);
              }
              return LiquidityCheckpointsList(checkpoints: filteredCheckpoints);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: LoadingIndicator(),
              ),
            ),
            error: (error, stackTrace) => ErrorDisplayWidget(
              error: error,
              title: 'Erreur de chargement',
              message: 'Impossible de charger les pointages de liquidité.',
              onRetry: () => ref.refresh(
                liquidityCheckpointsProvider((providerKey)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LiquidityCheckpoint> _applyFilters(
    List<LiquidityCheckpoint> checkpoints,
  ) {
    var filtered = checkpoints;

    if (_selectedPeriodFilter != null) {
      final period = _selectedPeriodFilter == 'Matin'
          ? LiquidityCheckpointType.morning
          : LiquidityCheckpointType.evening;
      filtered = filtered.where((cp) => cp.type == period).toList();
    }

    if (_selectedDateFilter != null) {
      final filterDate = DateTime(
        _selectedDateFilter!.year,
        _selectedDateFilter!.month,
        _selectedDateFilter!.day,
      );
      filtered = filtered.where((cp) {
        final cpDate = DateTime(cp.date.year, cp.date.month, cp.date.day);
        return cpDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateFilter(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDateFilter = picked);
    }
  }

  void _showPeriodFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la période'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes les périodes'),
              onTap: () {
                setState(() => _selectedPeriodFilter = null);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Matin'),
              onTap: () {
                setState(() => _selectedPeriodFilter = 'Matin');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Soir'),
              onTap: () {
                setState(() => _selectedPeriodFilter = 'Soir');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckpointDialog(
    BuildContext context,
    LiquidityCheckpointType type,
    LiquidityCheckpoint? existingCheckpoint,
  ) async {
    final result = await showDialog<LiquidityCheckpoint>(
      context: context,
      builder: (context) => LiquidityCheckpointDialog(
        checkpoint: existingCheckpoint,
        enterpriseId: widget.enterpriseId,
        period: type,
      ),
    );

    if (result != null && mounted) {
      final controller = ref.read(liquidityControllerProvider);

      if (existingCheckpoint != null) {
        await controller.updateCheckpoint(result);
      } else {
        await controller.createCheckpoint(result);
      }

      _invalidateProviders();
    }
  }

  void _showJustificationDialog(BuildContext context, LiquidityCheckpoint checkpoint) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => JustificationDialog(
        checkpointId: checkpoint.id,
        discrepancyPercentage: checkpoint.discrepancyPercentage ?? 0.0,
      ),
    );

    if (result != null && mounted) {
      final controller = ref.read(liquidityControllerProvider);
      await controller.validateDiscrepancy(
        checkpointId: checkpoint.id,
        justification: result,
      );
      _invalidateProviders();
      NotificationService.showSuccess(context, 'Justification enregistrée');
    }
  }

  void _invalidateProviders() {
    final enterpriseKey = widget.enterpriseId ?? '';
    ref.invalidate(todayLiquidityCheckpointProvider(enterpriseKey));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final recentCheckpointsKey =
        '$enterpriseKey|${sevenDaysAgo.millisecondsSinceEpoch}|${today.millisecondsSinceEpoch}';
    final allCheckpointsKey = enterpriseKey.isEmpty ? '' : '$enterpriseKey||';

    ref.invalidate(liquidityCheckpointsProvider((recentCheckpointsKey)));
    ref.invalidate(liquidityCheckpointsProvider((allCheckpointsKey)));
  }
}
