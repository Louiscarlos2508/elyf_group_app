import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_record.dart';
import '../../domain/entities/production_session.dart';
import 'production_report/production_report_consumption.dart';
import 'production_report/production_report_expenses.dart';
import 'production_report/production_report_financial_summary.dart';
import 'production_report/production_report_general_info.dart';
import 'production_report/production_report_header.dart';
import 'production_report/production_report_machines_bobines.dart';
import 'production_report/production_report_personnel.dart';
import 'production_report/production_report_components.dart';

/// Widget pour afficher un rapport détaillé d'une production spécifique.
class ProductionDetailReport extends ConsumerWidget {
  const ProductionDetailReport({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final linkedExpenses = <ExpenseRecord>[];

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
          ProductionReportHeader(session: session),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          ProductionReportGeneralInfo(session: session),
          const SizedBox(height: 24),
          ProductionReportMachinesBobines(session: session),
          const SizedBox(height: 24),
          ProductionReportConsumption(session: session),
          if (session.consommationCourant > 0) const SizedBox(height: 24),
          ProductionReportPersonnel(session: session),
          if (session.productionDays.isNotEmpty) const SizedBox(height: 24),
          ProductionReportExpenses(expenses: linkedExpenses),
          if (linkedExpenses.isNotEmpty) const SizedBox(height: 24),
          ProductionReportFinancialSummary(
            session: session,
            linkedExpenses: linkedExpenses,
          ),
        ],
      ),
    );
  }
}

