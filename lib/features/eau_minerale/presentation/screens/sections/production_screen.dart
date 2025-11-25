import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/production_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/production.dart';
import '../../../domain/entities/production_period_config.dart';
import '../../../domain/permissions/eau_minerale_permissions.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/production_form.dart';
import '../../widgets/production_history_table.dart';
import '../../widgets/production_summary_section.dart';
import '../../widgets/section_placeholder.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<ProductionFormState>();
    showDialog(
      context: context,
      builder: (dialogContext) => FormDialog(
        title: 'Nouvelle Production',
        child: ProductionForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  int _calculateTodayProduction(List<Production> productions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return productions
        .where((p) {
          final prodDate = DateTime(p.date.year, p.date.month, p.date.day);
          return prodDate.isAtSameMomentAs(today);
        })
        .fold<int>(0, (sum, p) => sum + p.quantity);
  }

  int _calculateWeekProduction(List<Production> productions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 6));
    
    return productions
        .where((p) {
          final prodDate = DateTime(p.date.year, p.date.month, p.date.day);
          return prodDate.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                 prodDate.isBefore(weekEnd.add(const Duration(days: 1)));
        })
        .fold<int>(0, (sum, p) => sum + p.quantity);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productionStateProvider);
    final periodConfigAsync = ref.watch(productionPeriodConfigProvider);
    
    return Scaffold(
      body: state.when(
        data: (data) {
          final todayProduction = _calculateTodayProduction(data.productions);
          final weekProduction = _calculateWeekProduction(data.productions);
          
          return periodConfigAsync.when(
            data: (periodConfig) => _ProductionContent(
              state: data,
              periodConfig: periodConfig,
              todayProduction: todayProduction,
              weekProduction: weekProduction,
              onNewProduction: () => _showForm(context),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ProductionContent(
              state: data,
              periodConfig: null,
              todayProduction: todayProduction,
              weekProduction: weekProduction,
              onNewProduction: () => _showForm(context),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.factory_outlined,
          title: 'Production indisponible',
          subtitle: 'Impossible de récupérer les lots pour le moment.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(productionStateProvider),
        ),
      ),
    );
  }
}

class _ProductionContent extends StatelessWidget {
  const _ProductionContent({
    required this.state,
    required this.periodConfig,
    required this.todayProduction,
    required this.weekProduction,
    required this.onNewProduction,
  });

  final ProductionState state;
  final ProductionPeriodConfig? periodConfig;
  final int todayProduction;
  final int weekProduction;
  final VoidCallback onNewProduction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Sort productions by date (newest first)
    final sortedProductions = List<Production>.from(state.productions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'Production',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    EauMineralePermissionGuard(
                      permission: EauMineralePermissions.createProduction,
                      child: IntrinsicWidth(
                        child: FilledButton.icon(
                          onPressed: onNewProduction,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle Production'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProductionSummarySection(
                  todayProduction: todayProduction,
                  weekProduction: weekProduction,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ProductionHistoryTable(
                  productions: sortedProductions,
                  periodConfig: periodConfig ?? const ProductionPeriodConfig(daysPerPeriod: 10),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}
