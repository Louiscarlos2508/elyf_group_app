import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

import '../../widgets/gaz_header.dart';
import '../../widgets/expense_form_dialog.dart';
import 'finance/finance_tab_bar.dart';
import 'finance/expenses_tab.dart';
import 'finance/treasury_tab.dart';

/// Unified Finance screen for the Gaz module.
/// Consolidates Expenses and Treasury management.
class GazFinanceScreen extends ConsumerStatefulWidget {
  const GazFinanceScreen({super.key});

  @override
  ConsumerState<GazFinanceScreen> createState() => _GazFinanceScreenState();
}

class _GazFinanceScreenState extends ConsumerState<GazFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _showNewExpenseDialog() {
    try {
      showDialog(
        context: context,
        builder: (_) => const GazExpenseFormDialog(),
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog de dépense: $e',
        name: 'gaz.finance',
        error: e,
      );
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: 'FINANCES',
            subtitle: _getSubtitle(),
            asSliver: true,
            actions: [
              if (_tabController.index == 0)
                IconButton(
                  onPressed: _showNewExpenseDialog,
                  icon: const Icon(Icons.add_card, color: Colors.white),
                  tooltip: 'Nouvelle dépense',
                ),
            ],
            bottom: FinanceTabBar(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const ExpensesTab(),
            const TreasuryTab(),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_tabController.index) {
      case 0:
        return 'Gestion des Dépenses';
      case 1:
        return 'Trésorerie & Caisses';
      default:
        return 'Suivi Financier';
    }
  }
}
