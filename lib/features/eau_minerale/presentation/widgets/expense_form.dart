import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/production_session_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/production_session.dart';

/// Form for creating/editing an expense record.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key});

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
  String? _selectedProductionId;
  bool _linkToProduction = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation : si on veut lier à une production, il faut sélectionner une production
    if (_linkToProduction && _selectedProductionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une production'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final expense = ExpenseRecord(
        id: '',
        label: _labelController.text.trim(),
        amountCfa: int.parse(_amountController.text),
        category: _category,
        date: _selectedDate,
        productionId: _linkToProduction ? _selectedProductionId : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(financesControllerProvider).createExpense(expense);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(financesStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépense enregistrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.carburant:
        return Icons.local_gas_station;
      case ExpenseCategory.reparations:
        return Icons.build;
      case ExpenseCategory.achatsDivers:
        return Icons.shopping_cart;
      case ExpenseCategory.autres:
        return Icons.more_horiz;
    }
  }

  Future<void> _selectProduction(BuildContext context) async {
    final controller = ref.read(productionSessionControllerProvider);
    final sessions = await controller.fetchSessions();
    
    if (!context.mounted) return;
    
    final selected = await showDialog<ProductionSession>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sélectionner une production'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                title: Text('Production du ${_formatDate(session.date)}'),
                subtitle: Text('ID: ${session.id.substring(0, 8)}...'),
                onTap: () => Navigator.of(dialogContext).pop(session),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedProductionId = selected.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Motif (Label)
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Motif de la dépense',
                prefixIcon: Icon(Icons.receipt_long),
                helperText: 'Description détaillée de la dépense',
                hintText: 'Ex: Carburant pour livraison, Réparation pompe...',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Le motif est requis' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Category
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Type de dépense',
                prefixIcon: Icon(Icons.category),
                helperText: 'Sélectionnez le type de dépense',
              ),
              items: ExpenseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(category.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            // Date selection
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date de la dépense',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_selectedDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (CFA)',
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Montant de la dépense en francs CFA',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final amount = int.tryParse(v);
                if (amount == null || amount <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Liaison à une production
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Lier à une production'),
              subtitle: const Text(
                'Optionnel : associer cette dépense à une production spécifique',
              ),
              value: _linkToProduction,
              onChanged: (value) {
                setState(() {
                  _linkToProduction = value ?? false;
                  if (!_linkToProduction) {
                    _selectedProductionId = null;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_linkToProduction) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectProduction(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.factory,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Production',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedProductionId != null
                                  ? 'Production sélectionnée'
                                  : 'Sélectionner une production',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: _selectedProductionId != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
                helperText: 'Informations complémentaires sur cette dépense',
                hintText: 'Ex: Fournisseur, numéro de facture...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
