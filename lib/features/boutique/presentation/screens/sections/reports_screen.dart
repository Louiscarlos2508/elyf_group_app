import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/report_data.dart';
import '../../widgets/expense_report_content.dart';
import '../../widgets/profit_report_content.dart';
import '../../widgets/purchase_report_content.dart';
import '../../widgets/report_kpi_cards.dart';
import '../../widgets/report_period_selector.dart';
import '../../widgets/sales_report_content.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;
  ReportPeriod _selectedPeriod = ReportPeriod.month;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _onPeriodChanged(ReportPeriod period, DateTime? start, DateTime? end) {
    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                Expanded(
                  child: Text(
                    'Rapports',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
            child: ReportPeriodSelector(
              selectedPeriod: _selectedPeriod,
              startDate: _startDate,
              endDate: _endDate,
              onPeriodChanged: _onPeriodChanged,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ReportKpiCards(
              period: _selectedPeriod,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildTabs(theme),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Ventes'), icon: Icon(Icons.shopping_cart)),
        ButtonSegment(value: 1, label: Text('Achats'), icon: Icon(Icons.shopping_bag)),
        ButtonSegment(value: 2, label: Text('Dépenses'), icon: Icon(Icons.receipt_long)),
        ButtonSegment(value: 3, label: Text('Bénéfices'), icon: Icon(Icons.trending_up)),
      ],
      selected: {_selectedTab},
      onSelectionChanged: (Set<int> selection) {
        setState(() => _selectedTab = selection.first);
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return SalesReportContent(
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
        );
      case 1:
        return PurchaseReportContent(
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
        );
      case 2:
        return ExpenseReportContent(
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
        );
      case 3:
        return ProfitReportContent(
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

