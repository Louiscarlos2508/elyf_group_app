import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/pdf/boutique_report_pdf_service.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import '../../../domain/entities/report_data.dart';
import '../../widgets/expenses_report_content_v2.dart';
import '../../widgets/profit_report_content_v2.dart';
import '../../widgets/purchases_report_content_v2.dart';
import '../../widgets/report_kpi_cards_v2.dart';
import '../../widgets/report_period_selector_v2.dart';
import '../../widgets/report_tabs_v2.dart';
import '../../widgets/sales_report_content_v2.dart';
import '../../widgets/boutique_header.dart';

/// Reports screen with professional UI - style eau_minerale.
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final reportData = await ref.read(
        reportDataProvider((
          period: ReportPeriod.custom,
          startDate: _startDate,
          endDate: _endDate,
        )).future,
      );

      final pdfService = BoutiqueReportPdfService.instance;
      final file = await pdfService.generateReport(
        reportData: reportData,
        startDate: _startDate,
        endDate: _endDate,
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
        NotificationService.showError(
          context,
          'Erreur lors de la génération PDF: $e',
        );
      }
    }
  }

  void _invalidateProviders() {
    ref.invalidate(reportDataProvider);
    ref.invalidate(salesReportProvider);
    ref.invalidate(purchasesReportProvider);
    ref.invalidate(expensesReportProvider);
    ref.invalidate(profitReportProvider);
    ref.invalidate(recentSalesProvider);
    ref.invalidate(purchasesProvider);
    ref.invalidate(expensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            BoutiqueHeader(
              title: "RAPPORTS",
              subtitle: "Statistiques & Analyses",
              gradientColors: [
                const Color(0xFF7C3AED), // Violet 600
                const Color(0xFF6D28D9), // Violet 700
              ],
              shadowColor: const Color(0xFF7C3AED),
              additionalActions: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _invalidateProviders,
                    tooltip: 'Actualiser les rapports',
                  ),
                ),
              ],
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return SalesReportContentV2(startDate: _startDate, endDate: _endDate);
      case 1:
        return PurchasesReportContentV2(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 2:
        return ExpensesReportContentV2(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 3:
        return ProfitReportContentV2(startDate: _startDate, endDate: _endDate);
      default:
        return const SizedBox.shrink();
    }
  }
}
