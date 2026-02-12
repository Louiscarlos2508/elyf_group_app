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
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          OrangeMoneyHeader(
            title: 'Flux de Trésorerie',
            subtitle: 'Gérez vos dépôts et retraits avec une traçabilité complète.',
            badgeText: 'TRANSACTIONS',
            badgeIcon: Icons.swap_horiz_rounded,
            asSliver: false,
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewTransactionTab(),
                const TransactionsHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentIndex = _tabController.index;
        return Container(
          margin: const EdgeInsets.all(16),
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFECECF0),
            borderRadius: BorderRadius.circular(14),
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
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(2.99),
        height: 29.428,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.transparent, width: 1.219)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0A0A0A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  height: 1.43,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransactionTypeSelector(
            selectedType: _selectedType,
            onTypeChanged: (TransactionType type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          const SizedBox(height: 24),
          if (!_showCustomerForm)
            _buildSearchClientCard()
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

  Widget _buildSearchClientCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.219),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_search, size: 20, color: Color(0xFF0A0A0A)),
                  SizedBox(width: 8),
                  Text(
                    'Rechercher le client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FormFieldWithLabel(
                label: 'Numéro de téléphone',
                controller: _phoneController,
                hintText: 'Ex: 0670000000',
                keyboardType: TextInputType.phone,
                validator: TransactionService.validatePhoneNumber,
              ),
              const SizedBox(height: 16),
              FormFieldWithLabel(
                label: 'Montant (FCFA)',
                controller: _amountController,
                hintText: 'Ex: 10000',
                keyboardType: TextInputType.number,
                validator: TransactionService.validateAmount,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF54900),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Continuer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
