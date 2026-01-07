import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../application/providers.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import 'invoice_print/invoice_print_service.dart';

/// Dialog for recording a credit payment.
class CreditPaymentDialog extends ConsumerStatefulWidget {
  const CreditPaymentDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.totalCredit,
  });

  final String customerId;
  final String customerName;
  final int totalCredit;

  @override
  ConsumerState<CreditPaymentDialog> createState() =>
      _CreditPaymentDialogState();
}

class _CreditPaymentDialogState extends ConsumerState<CreditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<Sale> _creditSales = [];
  Sale? _selectedSale;
  bool _isLoadingSales = true;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour accéder à ref après le montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCreditSales();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCreditSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final creditRepo = ref.read(creditRepositoryProvider);
      final sales = await creditRepo.fetchCustomerCredits(widget.customerId);
      setState(() {
        _creditSales = sales.where((s) => s.isCredit).toList();
        if (_creditSales.isNotEmpty && _selectedSale == null) {
          _selectedSale = _creditSales.first;
        }
        _isLoadingSales = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSales = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted CFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _showPrintOption(int paymentAmount, int remainingAfterPayment) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimer le reçu ?'),
        content: const Text('Voulez-vous imprimer ou générer un PDF du reçu de paiement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Non merci'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('PDF'),
          ),
          FutureBuilder<bool>(
            future: EauMineraleInvoiceService.instance.isSunmiAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return FilledButton(
                  onPressed: () => Navigator.pop(context, 'sunmi'),
                  child: const Text('Imprimer'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );

    if (result == null || result == 'skip' || !mounted) return;

    try {
      if (result == 'pdf') {
        final file = await EauMineraleInvoiceService.instance.generateCreditPaymentPdf(
          customerName: widget.customerName,
          sale: _selectedSale!,
          paymentAmount: paymentAmount,
          remainingAfterPayment: remainingAfterPayment,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        if (!mounted) return;
        await OpenFile.open(file.path);
      } else if (result == 'sunmi') {
        await EauMineraleInvoiceService.instance.printCreditPaymentReceipt(
          customerName: widget.customerName,
          sale: _selectedSale!,
          paymentAmount: paymentAmount,
          remainingAfterPayment: remainingAfterPayment,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une vente')),
      );
      return;
    }

    final amount = int.parse(_amountController.text);
    if (amount > _selectedSale!.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le montant ne peut pas dépasser le reste à payer (${_formatCurrency(_selectedSale!.remainingAmount)})',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final creditService = ref.read(creditServiceProvider);
      final payment = CreditPayment(
        id: '',
        saleId: _selectedSale!.id,
        amount: amount,
        date: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await creditService.recordPayment(payment);

      if (!mounted) return;
      // Invalider les providers pour rafraîchir les données
      ref.invalidate(clientsStateProvider);

      // Proposer d'imprimer le reçu
      final remainingAfterPayment = _selectedSale!.remainingAmount - amount;
      await _showPrintOption(amount, remainingAfterPayment);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(clientsStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement de ${_formatCurrency(amount)} enregistré'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encaisser un Paiement',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.customerName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crédit total',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(widget.totalCredit),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_creditSales.length} vente${_creditSales.length > 1 ? 's' : ''}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sales selection
                      if (_isLoadingSales)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_creditSales.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune vente en crédit',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Text(
                          'Sélectionner la vente',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._creditSales.map((sale) {
                          final isSelected = _selectedSale?.id == sale.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => setState(() => _selectedSale = sale),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale.productName,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatDate(sale.date)} • ${sale.quantity} unités',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatCurrency(sale.remainingAmount),
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                        Text(
                                          'Restant',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 24),
                      // Amount input
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Montant payé (CFA)',
                          prefixIcon: const Icon(Icons.attach_money),
                          helperText: _selectedSale != null
                              ? 'Maximum: ${_formatCurrency(_selectedSale!.remainingAmount)}'
                              : 'Sélectionnez une vente',
                          suffixIcon: _selectedSale != null
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () {
                                    _amountController.text = _selectedSale!.remainingAmount.toString();
                                  },
                                  tooltip: 'Remplir le montant total',
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: _selectedSale != null && !_isLoadingSales,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          final amount = int.tryParse(v);
                          if (amount == null || amount <= 0) return 'Montant invalide';
                          if (_selectedSale != null && amount > _selectedSale!.remainingAmount) {
                            return 'Ne peut pas dépasser le reste à payer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Notes input
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optionnel)',
                          prefixIcon: Icon(Icons.note_outlined),
                          helperText: 'Ajouter une note pour ce paiement',
                        ),
                        maxLines: 2,
                        enabled: !_isLoadingSales,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FilledButton.icon(
                        onPressed: (_isLoading || _selectedSale == null || _isLoadingSales)
                            ? null
                            : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

