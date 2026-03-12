import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/gaz_header.dart';
import 'finance/finance_tab_bar.dart';
import 'finance/expenses_tab.dart';
import 'finance/treasury_tab.dart';
import 'finance/payroll_tab.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

/// Unified Finance screen for the Gaz module.
/// Consolidates Expenses and Treasury management.
class GazFinanceScreen extends ConsumerStatefulWidget {
  const GazFinanceScreen({super.key});

  @override
  ConsumerState<GazFinanceScreen> createState() => _GazFinanceScreenState();
}

class _GazFinanceScreenState extends ConsumerState<GazFinanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool? _isPOS;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final bool isPOS = activeEnterprise?.isPointOfSale ?? true;
    final int targetLength = isPOS ? 2 : 3;

    if (_isPOS == null || _isPOS != isPOS) {
      if (_tabController.length != targetLength) {
        _tabController.removeListener(_onTabChanged);
        _tabController.dispose();
        _tabController = TabController(length: targetLength, vsync: this);
        _tabController.addListener(_onTabChanged);
      }
      _isPOS = isPOS;
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: 'FINANCES',
            subtitle: _getSubtitle(isPOS),
            asSliver: true,
            actions: const [],
            bottom: FinanceTabBar(
              tabController: _tabController,
              isPOS: isPOS,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const ExpensesTab(),
            const TreasuryTab(),
            if (!isPOS) const PayrollTab(),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(bool isPOS) {
    if (isPOS) return 'Trésorerie & Caisses';
    
    switch (_tabController.index) {
      case 0:
        return 'Gestion des Dépenses';
      case 1:
        return 'Trésorerie & Caisses';
      case 2:
        return 'Gestion des Salaires';
      default:
        return 'Suivi Financier';
    }
  }
}
