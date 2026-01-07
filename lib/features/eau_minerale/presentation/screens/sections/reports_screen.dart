import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../shared.dart';
import '../../../../core.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/report_period.dart';
import '../../widgets/expense_report_content.dart';
import '../../widgets/forecast_report_content.dart';
import '../../widgets/production_report_content.dart';
import '../../widgets/profitability_report_content.dart';
import '../../widgets/report_kpi_cards.dart';
import '../../widgets/report_period_selector.dart';
import '../../widgets/report_tabs.dart';
import '../../widgets/salary_report_content.dart';
import '../../widgets/sales_report_content.dart';
import '../../widgets/trends_report_content.dart';
import '../../widgets/weekly_monthly_report_content.dart';

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

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
  ) async {
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
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer les données du rapport
      final period = ReportPeriod(startDate: _startDate, endDate: _endDate);
      final reportData = await ref.read(
        reportDataProvider(period).future,
      );

      // Générer le PDF
      final pdfService = EauMineraleReportPdfService.instance;
      final file = await pdfService.generateReport(
        period: period,
        reportData: reportData,
      );

      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Ouvrir le fichier
      if (mounted) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF généré: ${file.path}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _invalidateProviders() {
    final period = ReportPeriod(startDate: _startDate, endDate: _endDate);
    ref.invalidate(reportDataProvider(period));
    ref.invalidate(reportSalesProvider(period));
    ref.invalidate(reportProductSummaryProvider(period));
    ref.invalidate(reportProductionProvider(period));
    ref.invalidate(reportExpenseProvider(period));
    ref.invalidate(reportSalaryProvider(period));
    ref.invalidate(salesStateProvider);
    ref.invalidate(productionSessionsStateProvider);
    ref.invalidate(financesStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                child: isWide
                    ? Row(
                        children: [
                          Text(
                            'Rapports',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          RefreshButton(
                            onRefresh: _invalidateProviders,
                            tooltip: 'Actualiser les rapports',
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Rapports',
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
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
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ReportPeriodSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateSelected: () => _selectDate(context, true),
                  onEndDateSelected: () => _selectDate(context, false),
                  onDownload: _downloadReport,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ReportKpiCards(
                  period:
                      ReportPeriod(startDate: _startDate, endDate: _endDate),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ReportTabs(
                  selectedTab: _selectedTab,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTabContent(context),
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

  Widget _buildTabContent(BuildContext context) {
    final period = ReportPeriod(startDate: _startDate, endDate: _endDate);

    // Détecter si c'est une période hebdomadaire ou mensuelle
    final days = period.endDate.difference(period.startDate).inDays;
    final isWeeklyOrMonthly = days <= 31; // Semaine ou mois

    switch (_selectedTab) {
      case 0:
        return SalesReportContent(period: period);
      case 1:
        if (isWeeklyOrMonthly) {
          return WeeklyMonthlyReportContent(period: period);
        }
        return ProductionReportContent(period: period);
      case 2:
        return ExpenseReportContent(period: period);
      case 3:
        return SalaryReportContent(period: period);
      case 4:
        return ProfitabilityReportContent(period: period);
      case 5:
        return TrendsReportContent(period: period);
      case 6:
        return ForecastReportContent(period: period);
      default:
        return const SizedBox.shrink();
    }
  }
}
