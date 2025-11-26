import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../../core/pdf/immobilier_report_pdf_service.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/report_period.dart';
import '../../widgets/report_period_selector.dart';
import '../../widgets/reports_helpers.dart';
import '../../widgets/reports_kpi_grid.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  void _onPeriodChanged(ReportPeriod period, DateTime? start, DateTime? end) {
    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _downloadReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une période'),
        ),
      );
      return;
    }

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer toutes les données nécessaires
      final properties = await ref.read(propertiesProvider.future);
      final contracts = await ref.read(contractsProvider.future);
      final payments = await ref.read(paymentsProvider.future);
      final expenses = await ref.read(expensesProvider.future);

      final periodPayments = ReportsHelpers.getPaymentsInPeriod(
        payments,
        _selectedPeriod,
        _startDate,
        _endDate,
      );
      final periodExpenses = ReportsHelpers.getExpensesInPeriod(
        expenses,
        _selectedPeriod,
        _startDate,
        _endDate,
      );

      // Générer le PDF
      final pdfService = ImmobilierReportPdfService.instance;
      final file = await pdfService.generateReport(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        properties: properties,
        contracts: contracts,
        payments: payments,
        expenses: expenses,
        periodPayments: periodPayments,
        periodExpenses: periodExpenses,
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertiesAsync = ref.watch(propertiesProvider);
    final contractsAsync = ref.watch(contractsProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rapports',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ReportPeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  startDate: _startDate,
                  endDate: _endDate,
                  onPeriodChanged: _onPeriodChanged,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _downloadReport,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Télécharger PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Vue d\'ensemble',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: propertiesAsync.when(
              data: (properties) => contractsAsync.when(
                data: (contracts) => paymentsAsync.when(
                  data: (payments) => expensesAsync.when(
                    data: (expenses) {
                      final periodPayments = ReportsHelpers.getPaymentsInPeriod(
                        payments,
                        _selectedPeriod,
                        _startDate,
                        _endDate,
                      );
                      final periodExpenses = ReportsHelpers.getExpensesInPeriod(
                        expenses,
                        _selectedPeriod,
                        _startDate,
                        _endDate,
                      );

                      return ReportsKpiGrid(
                        properties: properties,
                        contracts: contracts,
                        payments: payments,
                        expenses: expenses,
                        periodPayments: periodPayments,
                        periodExpenses: periodExpenses,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}

