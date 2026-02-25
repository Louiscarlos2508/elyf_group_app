import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/transport_expense.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';

/// Formulaire d'ajout d'une dépense de transport selon le design Figma.
class TransportExpenseFormDialog extends ConsumerStatefulWidget {
  const TransportExpenseFormDialog({
    super.key,
    required this.tour,
    this.initialExpense,
  });

  final Tour tour;
  final TransportExpense? initialExpense;

  @override
  ConsumerState<TransportExpenseFormDialog> createState() =>
      _TransportExpenseFormDialogState();
}

class _TransportExpenseFormDialogState
    extends ConsumerState<TransportExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialExpense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: (widget.initialExpense?.amount ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      NotificationService.showWarning(
        context,
        'Le montant doit être supérieur à 0',
      );
      return;
    }

    try {
      final controller = ref.read(tourControllerProvider);

      List<TransportExpense> updatedExpenses;
      final isEditing = widget.initialExpense != null;

      if (isEditing) {
        updatedExpenses = widget.tour.transportExpenses.map((e) {
          if (e.id == widget.initialExpense!.id) {
            return e.copyWith(
              description: _descriptionController.text.trim(),
              amount: amount,
            );
          }
          return e;
        }).toList();
      } else {
        final expense = TransportExpense(
          id: 'expense_${DateTime.now().millisecondsSinceEpoch}',
          description: _descriptionController.text.trim(),
          amount: amount,
          expenseDate: DateTime.now(),
        );
        updatedExpenses = [...widget.tour.transportExpenses, expense];
      }

      final updatedTour = widget.tour.copyWith(
        transportExpenses: updatedExpenses,
        updatedAt: DateTime.now(),
      );

      await controller.updateTour(updatedTour);

      if (mounted) {
        // Invalider les providers pour rafraîchir l'UI
        ref.invalidate(
          toursProvider((
            enterpriseId: widget.tour.enterpriseId,
            status: null,
          )),
        );
        // Forcer le rechargement du tour
        ref.refresh(tourProvider(widget.tour.id).future).ignore();
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFF3F3F5);
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final isEditing = widget.initialExpense != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Modifier la dépense' : 'Ajouter une dépense',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enregistrez les frais du trajet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElyfIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    useGlassEffect: false,
                    size: 32,
                    iconSize: 16,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Description
                      Text(
                        'Description',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          hintText: 'Ex: Carburant, péage, repas...',
                          hintStyle: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Montant
                      Text(
                        'Montant',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: backgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ce champ est requis';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0) {
                                return 'Montant invalide';
                              }
                              return null;
                            },
                          ),
                          Positioned(
                            right: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                'FCFA',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: ElyfButton(
                      onPressed: () => Navigator.of(context).pop(),
                      variant: ElyfButtonVariant.outlined,
                      width: double.infinity,
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElyfButton(
                      onPressed: _submit,
                      width: double.infinity,
                      child: Text(isEditing ? 'Modifier' : 'Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
