import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';

/// Form for creating/editing an expense record.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key, this.expense});

  final ExpenseRecord? expense;

  @override
  ConsumerState<ExpenseForm> createState() => ExpenseFormState();
}

class ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.carburant;
  DateTime _selectedDate = DateTime.now();
  String? _receiptPath;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final expense = widget.expense!;
      _labelController.text = expense.label;
      _amountController.text = expense.amountCfa.toString();
      _category = expense.category;
      _selectedDate = expense.date;
      _notesController.text = expense.notes ?? '';
      _receiptPath = expense.receiptPath;
      _paymentMethod = expense.paymentMethod;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildSessionWarning(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(currentClosingSessionProvider);
    final theme = Theme.of(context);

    return sessionAsync.maybeWhen(
      data: (session) {
        if (session != null && session.status == ClosingStatus.open) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session de trésorerie fermée',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vous devez ouvrir une session dans l\'onglet "Trésorerie" avant de pouvoir enregistrer une dépense.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> submit() async {
    // 0. Vérifier la session de trésorerie
    final currentSession = await ref.read(currentClosingSessionProvider.future);
    if (currentSession == null || currentSession.status != ClosingStatus.open) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'La session de trésorerie est fermée. Veuillez l\'ouvrir avant d\'enregistrer une dépense.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
      final expense = ExpenseRecord(
        id: widget.expense?.id ?? '',
        enterpriseId: widget.expense?.enterpriseId ?? enterpriseId,
        label: _labelController.text.trim(),
        amountCfa: int.parse(_amountController.text),
        category: _category,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: widget.expense != null ? DateTime.now() : null,
        receiptPath: _receiptPath,
        paymentMethod: _paymentMethod,
      );

      if (widget.expense == null) {
        await ref.read(financesControllerProvider).createExpense(expense);
      } else {
        await ref.read(financesControllerProvider).updateExpense(expense);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(financesStateProvider);
      NotificationService.showSuccess(
        context,
        widget.expense == null ? 'Dépense enregistrée' : 'Dépense modifiée',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.carburant:
        return Icons.local_gas_station;
      case ExpenseCategory.reparations:
        return Icons.build;
      case ExpenseCategory.achatsDivers:
        return Icons.shopping_cart;
      case ExpenseCategory.salaires:
        return Icons.people_alt;
      case ExpenseCategory.achatMatieresPremieres:
        return Icons.inventory_2;
      case ExpenseCategory.autres:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSessionWarning(context, ref),
            // Section Reçu
            FormImagePicker(
              initialImagePath: _receiptPath,
              label: 'Photo du reçu',
              onImageSelected: (file) {
                setState(() => _receiptPath = file?.path);
              },
            ),
            const SizedBox(height: 16),

            // Section Détails Dépense
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Détails de la Dépense',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelController,
                    decoration: _buildInputDecoration(
                      label: 'Motif de la dépense',
                      icon: Icons.description_rounded,
                      hintText: 'Ex: Carburant livraison, Réparation...',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Le motif est requis' : null,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: _category,
                    decoration: _buildInputDecoration(
                      label: 'Type de dépense',
                      icon: Icons.category_rounded,
                    ),
                    items: ExpenseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              size: 18,
                              color: colors.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Montant & Date
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.payments_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Paiement & Date',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    decoration: _buildInputDecoration(
                      label: 'Montant',
                      icon: Icons.account_balance_wallet_rounded,
                      suffixText: 'CFA',
                    ),
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      final amount = int.tryParse(v);
                      if (amount == null || amount <= 0) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Notes
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.note_alt_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Notes Supplémentaires',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: _buildInputDecoration(
                      label: 'Notes (Optionnel)',
                      icon: Icons.edit_note_rounded,
                      hintText: 'Fournisseur, facture...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? suffixText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DropdownButtonFormField<PaymentMethod>(
      initialValue: _paymentMethod,
      decoration: _buildInputDecoration(
        label: 'Mode de paiement',
        icon: Icons.account_balance_wallet_rounded,
      ),
      items: [
        PaymentMethod.cash,
        PaymentMethod.mobileMoney,
      ].map((method) {
        return DropdownMenuItem(
          value: method,
          child: Row(
            children: [
              Icon(
                method == PaymentMethod.cash ? Icons.money : Icons.phone_android,
                size: 18,
                color: colors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(method.label),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _paymentMethod = v);
      },
    );
  }

  Widget _buildDateField() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_note_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de la dépense',
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    DateFormatter.formatDate(_selectedDate),
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          widget.expense == null ? 'ENREGISTRER LA DÉPENSE' : 'MODIFIER LA DÉPENSE',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}
