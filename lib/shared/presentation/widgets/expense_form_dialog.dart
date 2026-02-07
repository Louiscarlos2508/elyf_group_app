import 'package:flutter/material.dart';

import 'form_dialog.dart';
import '../../utils/validators.dart';
import 'form_fields/amount_input_field.dart';
import 'form_fields/date_picker_field.dart';
import 'form_fields/category_selector_field.dart';
import 'form_image_picker.dart';


/// Dialog générique pour créer/modifier une dépense.
///
/// Utilise FormDialog et fournit les champs communs (montant, date, catégorie, description, notes).
/// Les champs supplémentaires peuvent être fournis via [additionalFields].
class ExpenseFormDialog<T extends Enum> extends StatefulWidget {
  const ExpenseFormDialog({
    super.key,
    required this.title,
    required this.categories,
    required this.getCategoryLabel,
    required this.onSave,
    this.descriptionLabel = 'Description',
    this.descriptionHint,
    this.amountLabel = 'Montant (FCFA) *',
    this.dateLabel = 'Date *',
    this.categoryLabel = 'Catégorie *',
    this.notesLabel = 'Notes (optionnel)',
    this.additionalFields = const [],
    this.initialAmount,
    this.initialDate,
    this.initialCategory,
    this.initialDescription,
    this.initialNotes,
    this.initialReceiptPath,
    this.isLoading = false,
  });

  /// Titre du dialog.
  final String title;

  /// Liste des catégories disponibles.
  final List<T> categories;

  /// Fonction pour obtenir le label d'une catégorie.
  final String Function(T) getCategoryLabel;

  /// Callback appelé lors de la sauvegarde.
  /// Reçoit les valeurs des champs communs et doit retourner null si succès, ou un message d'erreur.
  final Future<String?> Function({
    required double amount,
    required DateTime date,
    required T category,
    required String description,
    String? notes,
    String? receiptPath,
  })
  onSave;

  /// Label du champ description.
  final String descriptionLabel;

  /// Hint du champ description.
  final String? descriptionHint;

  /// Label du champ montant.
  final String amountLabel;

  /// Label du champ date.
  final String dateLabel;

  /// Label du champ catégorie.
  final String categoryLabel;

  /// Label du champ notes.
  final String notesLabel;

  /// Widgets supplémentaires à insérer avant les notes.
  final List<Widget> additionalFields;

  /// Valeur initiale du montant.
  final double? initialAmount;

  /// Valeur initiale de la date.
  final DateTime? initialDate;

  /// Valeur initiale de la catégorie.
  final T? initialCategory;

  /// Valeur initiale de la description.
  final String? initialDescription;

  /// Valeur initiale des notes.
  final String? initialNotes;

  /// Valeur initiale du reçu.
  final String? initialReceiptPath;

  /// Indique si le formulaire est en cours de sauvegarde.
  final bool isLoading;

  @override
  State<ExpenseFormDialog<T>> createState() => _ExpenseFormDialogState<T>();
}

class _ExpenseFormDialogState<T extends Enum>
    extends State<ExpenseFormDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late T _selectedCategory;
  late DateTime _selectedDate;
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _selectedCategory = widget.initialCategory ?? widget.categories.first;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _receiptPath = widget.initialReceiptPath;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Montant invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final error = await widget.onSave(
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      receiptPath: _receiptPath,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépense enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.title,
      saveLabel: 'Enregistrer',
      onSave: _handleSave,
      isLoading: widget.isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormImagePicker(
              initialImagePath: _receiptPath,
              label: 'Photo du reçu',
              onImageSelected: (file) {
                setState(() => _receiptPath = file?.path);
              },
            ),
            const SizedBox(height: 24),
            AmountInputField(
              controller: _amountController,
              label: widget.amountLabel,
              validator: (value) => Validators.amount(value),
            ),
            const SizedBox(height: 16),
            DatePickerField(
              selectedDate: _selectedDate,
              label: widget.dateLabel,
              onDateSelected: (date) {
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 16),
            CategorySelectorField<T>(
              value: _selectedCategory,
              items: widget.categories,
              labelBuilder: widget.getCategoryLabel,
              label: widget.categoryLabel,
              onChanged: (category) {
                if (category != null) {
                  setState(() => _selectedCategory = category);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '${widget.descriptionLabel} *',
                hintText: widget.descriptionHint,
                prefixIcon: const Icon(Icons.description),
              ),
              validator: (value) => Validators.required(value),
              maxLines: 2,
            ),
            ...widget.additionalFields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: field,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: widget.notesLabel,
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
