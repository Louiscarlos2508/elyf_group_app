import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/core/pdf/gaz_report_pdf_service.dart';
import '../../../domain/entities/report_data.dart';
import '../../widgets/expenses_report_content_v2.dart';
import '../../widgets/financial_report_content_v2.dart';
import '../../widgets/profit_report_content_v2.dart';
import '../../widgets/report_kpi_cards_v2.dart';
import '../../widgets/report_period_selector_v2.dart';
import '../../widgets/report_tabs_v2.dart';
import '../../widgets/sales_report_content_v2.dart';

/// Reports screen with professional UI - style boutique.
class GazReportsScreen extends ConsumerStatefulWidget {
  const GazReportsScreen({super.key});

  @override
  ConsumerState<GazReportsScreen> createState() => _GazReportsScreenState();
}

class _GazReportsScreenState extends ConsumerState<GazReportsScreen> {
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
                child: GazReportPeriodSelectorV2(
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
                child: GazReportKpiCardsV2(
                  startDate: _startDate,
                  endDate: _endDate,
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
      case 0:
        return GazSalesReportContentV2(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 1:
        return GazExpensesReportContentV2(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 2:
        return GazProfitReportContentV2(
          startDate: _startDate,
          endDate: _endDate,
        );
      case 3:
        return reportDataAsync.when(
          data: (reportData) => GazFinancialReportContentV2(
            startDate: _startDate,
            endDate: _endDate,
            totalRevenue: reportData.salesRevenue,
          ),
          loading: () => AppShimmers.list(context),
          error: (_, __) => const SizedBox.shrink(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
