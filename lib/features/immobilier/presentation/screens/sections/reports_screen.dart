import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/core/pdf/immobilier_report_pdf_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/report_period.dart';
import '../../widgets/expenses_report_content.dart';
import '../../widgets/payments_report_content.dart';
import '../../widgets/profit_report_content.dart';
import '../../widgets/report_kpi_cards_v2.dart';
import '../../widgets/report_period_selector_v2.dart';
import '../../widgets/report_tabs_v2.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

/// Reports screen with professional UI - style Boutique/Eau Minérale.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    // Initialize with current month by default
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _downloadReport() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final properties = await ref.read(propertiesProvider.future);
      final contracts = await ref.read(contractsProvider.future);
      final payments = await ref.read(paymentsProvider.future);
      final expenses = await ref.read(expensesProvider.future);

      final periodPayments = payments.where((p) {
        return p.paymentDate
                .isAfter(_startDate.subtract(const Duration(days: 1))) &&
            p.paymentDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      final periodExpenses = expenses.where((e) {
        return e.expenseDate
                .isAfter(_startDate.subtract(const Duration(days: 1))) &&
            e.expenseDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      final pdfService = ImmobilierReportPdfService.instance;
      final file = await pdfService.generateReport(
        period: ReportPeriod.custom,
        startDate: _startDate,
        endDate: _endDate,
        properties: properties,
        contracts: contracts,
        payments: payments,
        expenses: expenses,
        periodPayments: periodPayments,
        periodExpenses: periodExpenses,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          NotificationService.showInfo(context, 'PDF généré: ${file.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.showError(context, 'Erreur lors de la génération PDF: $e');
      }
    }
  }

  void _invalidateProviders() {
    ref.invalidate(propertiesProvider);
    ref.invalidate(contractsProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(expensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, isWide ? 24 : 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rapports',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RefreshButton(
                      onRefresh: _invalidateProviders,
                      tooltip: 'Actualiser les rapports',
                    ),
                  ],
                ),
              ),
            ),

            // Period selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ReportPeriodSelectorV2(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateSelected: () => _selectDate(context, true),
                  onEndDateSelected: () => _selectDate(context, false),
                  onDownload: _downloadReport,
                ),
              ),
            ),

            // KPI Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ReportKpiCardsV2(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ReportTabsV2(
                  selectedTab: _selectedTab,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),

            // Tab content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTabContent(),
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

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return PaymentsReportContent(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 1:
        return ExpensesReportContent(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 2:
        return ProfitReportContent(
          startDate: _startDate,
          endDate: _endDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
