import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/services/transaction_service.dart';
import '../../widgets/form_field_with_label.dart';
import '../../widgets/new_customer_form_card.dart';
import '../../widgets/transaction_type_selector.dart';
import '../../widgets/orange_money_header.dart';
import '../../widgets/operator_balance_summary.dart';
import 'transactions_history_screen.dart';

/// New transactions screen with tabs for new transaction and history.
class TransactionsV2Screen extends ConsumerStatefulWidget {
  const TransactionsV2Screen({super.key});

  @override
  ConsumerState<TransactionsV2Screen> createState() =>
      _TransactionsV2ScreenState();
}

class _TransactionsV2ScreenState extends ConsumerState<TransactionsV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionType _selectedType = TransactionType.cashIn;
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // État pour le formulaire d'enregistrement
  bool _showCustomerForm = false;
  String? _existingCustomerName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = _phoneController.text.trim();

    // Rechercher si le client existe déjà (logique dans le controller)
    final controller = ref.read(orangeMoneyControllerProvider);
    final existingCustomerName = await controller.findCustomerByPhoneNumber(
      phoneNumber,
    );

    setState(() {
      _existingCustomerName = existingCustomerName;
      _showCustomerForm = true;
    });
  }

  Future<void> _handleSaveCustomer({
    required String firstName,
    required String lastName,
    required String idType,
    required String idNumber,
    DateTime? idIssueDate,
    DateTime? idExpiryDate,
  }) async {
    final phoneNumber = _phoneController.text.trim();
    final amountStr = _amountController.text.trim();
    final customerName = '$firstName $lastName';

    try {
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
      final controller = ref.read(orangeMoneyControllerProvider);
      await controller.createTransactionFromInput(
        enterpriseId: enterpriseId,
        type: _selectedType,
        phoneNumber: phoneNumber,
        amountStr: amountStr,
        customerName: customerName,
      );

      if (mounted) {
        final amount = int.parse(amountStr);
        NotificationService.showSuccess(
          context,
          'Transaction ${_selectedType == TransactionType.cashIn ? "dépôt" : "retrait"} de ${CurrencyFormatter.formatFCFA(amount)} créée avec succès',
        );

        // Reset form
        _phoneController.clear();
        _amountController.clear();
        setState(() {
          _showCustomerForm = false;
          _existingCustomerName = null;
        });

        // Invalider le provider des transactions pour rafraîchir la liste
        ref.invalidate(filteredTransactionsProvider);
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        NotificationService.showWarning(
          context,
          e.message ?? 'Erreur de validation',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Erreur lors de la création: $e',
        );
      }
    }
  }

  void _handleCancelCustomerForm() {
    setState(() {
      _showCustomerForm = false;
      _existingCustomerName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          OrangeMoneyHeader(
            title: 'Flux de Trésorerie',
            subtitle: 'Gérez vos dépôts et retraits avec une traçabilité complète.',
            badgeText: 'TRANSACTIONS',
            badgeIcon: Icons.swap_horiz_rounded,
            asSliver: true,
          ),
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNewTransactionTab(),
            const TransactionsHistoryScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final theme = Theme.of(context);
        final currentIndex = _tabController.index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  icon: Icons.add_circle_outline,
                  label: 'Nouvelle transaction',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    if (_tabController.index != 0) {
                      _tabController.animateTo(0);
                    }
                  },
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  icon: Icons.history,
                  label: 'Historique',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    if (_tabController.index != 1) {
                      _tabController.animateTo(1);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTransactionTab() {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isKeyboardOpen ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperatorBalanceSummary(),
          SizedBox(height: isKeyboardOpen ? 12 : 24),
          TransactionTypeSelector(
            selectedType: _selectedType,
            onTypeChanged: (TransactionType type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          SizedBox(height: isKeyboardOpen ? 12 : 24),
          if (!_showCustomerForm)
            _buildSearchClientCard(theme)
          else
            _buildCustomerFormCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nouvelle transaction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enregistrez rapidement vos dépôts et retraits',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF4A5565),
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchClientCard(ThemeData theme) {
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_search, size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Détails de la Transaction',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElyfField(
              label: 'Numéro de téléphone client',
              controller: _phoneController,
              hint: 'Ex: 0670000000',
              prefixIcon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: TransactionService.validatePhoneNumber,
            ),
            const SizedBox(height: 20),
            ElyfField(
              label: 'Montant de l\'opération (FCFA)',
              controller: _amountController,
              hint: 'Ex: 10000',
              prefixIcon: Icons.account_balance_wallet,
              keyboardType: TextInputType.number,
              suffixText: 'CFA',
              validator: TransactionService.validateAmount,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Valider les informations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFormCard() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    return NewCustomerFormCard(
      phoneNumber: _phoneController.text.trim(),
      amount: amount,
      type: _selectedType,
      existingCustomerName: _existingCustomerName,
      onCancel: _handleCancelCustomerForm,
      onSave: _handleSaveCustomer,
    );
  }
}
