import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/core/pdf/gaz_report_pdf_service.dart';
import '../../widgets/report_period_selector_v2.dart';
import '../../widgets/report_tabs_v2.dart';
import '../../widgets/sales_report_content_v2.dart';
import '../../../domain/entities/report_data.dart';
import '../../widgets/expenses_report_content_v2.dart';
import '../../widgets/financial_report_content_v2.dart';
import '../../widgets/profit_report_content_v2.dart';
import '../../widgets/report_kpi_cards_v2.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/stock_summary_content.dart';
import '../../widgets/stock_history_content.dart';
import '../../widgets/pos_network_report_tab.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

/// Reports screen with professional UI - style boutique.
class GazReportsScreen extends ConsumerStatefulWidget {
  const GazReportsScreen({super.key});

  @override
  ConsumerState<GazReportsScreen> createState() => _GazReportsScreenState();
}

class _GazReportsScreenState extends ConsumerState<GazReportsScreen> {
  GazReportTab _selectedTab = GazReportTab.activity;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    // Initialize with current month by default
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    
    // Cap end date to today
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    _endDate = endOfMonth.isAfter(now) ? now : endOfMonth;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = isStartDate ? _startDate : _endDate;
    
    // Ensure initialDate is within bounds [firstDate, lastDate]
    final safeInitialDate = initialDate.isAfter(now) ? now : initialDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(2020),
      lastDate: now,
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

  Future<void> _downloadPdf() async {
    try {
      // Afficher un indicateur de chargement
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Récupérer les données du rapport
      final reportDataAsync = ref.read(
        gazReportDataProvider(
          (
            period: GazReportPeriod.custom,
            startDate: _startDate,
            endDate: _endDate,
          )
              as ({
            GazReportPeriod period,
            DateTime? startDate,
            DateTime? endDate,
          }),
        ),
      );

      final reportData = reportDataAsync.when(
        data: (data) => data,
        loading: () => throw Exception('Chargement des données en cours'),
        error: (error, _) => throw Exception('Erreur: $error'),
      );

      // Générer le PDF
      final pdfService = GazReportPdfService.instance;
      final file = await pdfService.generateReport(
        reportData: reportData,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog de chargement

      // Ouvrir le fichier PDF
      final result = await OpenFile.open(file.path);
      if (!mounted) return;

      if (result.type != ResultType.done) {
        NotificationService.showInfo(
          context,
          'PDF généré: ${file.path}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog de chargement en cas d'erreur
      NotificationService.showError(
        context,
        'Erreur lors de la génération PDF: $e',
      );
    }
  }



  void _invalidateProviders() {
    ref.invalidate(gazReportDataProvider);
    ref.invalidate(gasSalesProvider);
    ref.invalidate(gazExpensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final activeEnterprise = activeEnterpriseAsync.when(
      data: (e) => e,
      loading: () => null,
      error: (_, __) => null,
    );
    final isPOS = activeEnterprise?.isPointOfSale ?? true;
    final showPosTab = !isPOS;

    return LayoutBuilder(
      builder: (context, constraints) {

        return CustomScrollView(
          slivers: [
            // Header section with Premium Background
            GazHeader(
              title: 'GAZ',
              subtitle: 'Rapports',
              actions: [
                ElyfIconButton(
                  onPressed: _invalidateProviders,
                  icon: Icons.refresh,
                  tooltip: 'Actualiser les rapports',
                ),
              ],
            ),

            // Period selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GazReportPeriodSelectorV2(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateSelected: () => _selectDate(context, true),
                  onEndDateSelected: () => _selectDate(context, false),
                  onDownloadPdf: _downloadPdf,
                ),
              ),
            ),

            // KPI Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: GazReportKpiCardsV2(
                  startDate: _startDate,
                  endDate: _endDate,
                  selectedTab: _selectedTab == GazReportTab.stock ? 2 : 0,
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: GazReportTabsV2(
                  selectedTab: _selectedTab,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                  showPosTab: showPosTab,
                  isPOS: isPOS,
                ),
              ),
            ),

            // Tab content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTabContent(isPOS),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(bool isPOS) {
    final reportDataAsync = ref.watch(
      gazReportDataProvider(
        (
              period: GazReportPeriod.custom,
              startDate: _startDate,
              endDate: _endDate,
            )
            as ({
              GazReportPeriod period,
              DateTime? startDate,
              DateTime? endDate,
            }),
      ),
    );

    switch (_selectedTab) {
      case GazReportTab.activity: // Activité
        return Column(
          children: [
            GazSalesReportContentV2(
              startDate: _startDate,
              endDate: _endDate,
            ),
            if (!isPOS) ...[
              const SizedBox(height: 24),
              GazProfitReportContentV2(
                startDate: _startDate,
                endDate: _endDate,
              ),
            ],
          ],
        );
      case GazReportTab.finance: // Trésorerie
        return Column(
          children: [
            GazExpensesReportContentV2(
              startDate: _startDate,
              endDate: _endDate,
            ),
            const SizedBox(height: 24),
            reportDataAsync.when(
              data: (reportData) => GazFinancialReportContentV2(
                startDate: _startDate,
                endDate: _endDate,
                totalRevenue: reportData.salesRevenue,
              ),
              loading: () => AppShimmers.list(context),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const SizedBox.shrink(), // Sessions report removed
          ],
        );
      case GazReportTab.stock: // Stocks
        final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
        final enterpriseId = activeEnterpriseAsync.when(
          data: (e) => e?.id ?? '',
          loading: () => '',
          error: (_, __) => '',
        );
        if (enterpriseId.isEmpty) return const SizedBox.shrink();
        
        return Column(
          children: [
            GazStockSummaryContent(enterpriseId: enterpriseId),
            const SizedBox(height: 24),
            GazStockHistoryContent(
              enterpriseId: enterpriseId,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ],
        );
      case GazReportTab.posNetwork: // Réseau POS
        return PosNetworkReportTab(
          startDate: _startDate,
          endDate: _endDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
