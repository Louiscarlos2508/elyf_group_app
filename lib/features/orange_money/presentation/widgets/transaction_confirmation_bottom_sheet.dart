import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/app_theme.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/services/customer_service.dart';

class TransactionConfirmationBottomSheet extends StatefulWidget {
  const TransactionConfirmationBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.type,
    this.existingCustomer,
    required this.onConfirm,
  });

  final String phoneNumber;
  final int amount;
  final TransactionType type;
  final Customer? existingCustomer;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String idType,
    required String idNumber,
    DateTime? idIssueDate,
    String? town,
    String? reference,
  }) onConfirm;

  @override
  State<TransactionConfirmationBottomSheet> createState() =>
      _TransactionConfirmationBottomSheetState();
}

class _TransactionConfirmationBottomSheetState
    extends State<TransactionConfirmationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _townController = TextEditingController();
  final _referenceController = TextEditingController();

  String _idType = "CNIB";
  DateTime? _idIssueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      final parts = widget.existingCustomer!.name.split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
      _idNumberController.text = widget.existingCustomer!.idNumber ?? '';
      _idType = widget.existingCustomer!.idType ?? "CNIB";
      _idIssueDate = widget.existingCustomer!.idIssueDate;
      _townController.text = widget.existingCustomer!.town ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _townController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onConfirm(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        idType: _idType,
        idNumber: _idNumberController.text.trim(),
        idIssueDate: _idIssueDate,
        town: _townController.text.trim(),
        reference: _referenceController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _idIssueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Standard Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: AppSpacing.dialogPadding.copyWith(top: 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormDialogHeader(
                        title: 'Confirmer la Transaction',
                        subtitle: 'Vérifiez les informations avant de valider.',
                        icon: Icons.check_circle_outline,
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Summary Card with Premium Styling
                      ElyfCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        elevation: 0,
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              context,
                              'Opération',
                              widget.type == TransactionType.cashIn ? 'DEPOT (CASH-IN)' : 'RETRAIT (CASH-OUT)',
                              widget.type == TransactionType.cashIn 
                                ? theme.extension<StatusColors>()?.success ?? Colors.green 
                                : colorScheme.primary,
                            ),
                            Divider(height: AppSpacing.xl, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            _buildSummaryRow(
                              context,
                              'Montant',
                              CurrencyFormatter.formatFCFA(widget.amount),
                              colorScheme.primary,
                              isBold: true,
                            ),
                            Divider(height: AppSpacing.xl, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            _buildSummaryRow(
                              context,
                              'Numéro',
                              widget.phoneNumber,
                              colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Customer details Section Title
                      Text(
                        'Identité du Client',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElyfField(
                              label: 'Prénom',
                              controller: _firstNameController,
                              hint: 'ex: Ibrahim',
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElyfField(
                              label: 'Nom',
                              controller: _lastNameController,
                              hint: 'ex: Ouedraogo',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Village/Ville & Référence
                      Row(
                        children: [
                          Expanded(
                            child: ElyfField(
                              label: 'Village/Ville',
                              controller: _townController,
                              hint: 'ex: Ouagadougou',
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElyfField(
                              label: 'N° Transaction',
                              controller: _referenceController,
                              hint: 'Référence externe',
                              prefixIcon: Icons.receipt_long_outlined,
                            ),
                          ),
                        ],
                      ),
  
                      const SizedBox(height: AppSpacing.md),
  
                      // ID Details with Expandable UI
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            'Informations complémentaires',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _idType,
                                    dropdownColor: colorScheme.surface,
                                    decoration: InputDecoration(
                                      labelText: 'Type de pièce',
                                      labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerLowest,
                                    ),
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                    items: [
                                      "CNIB",
                                      "Passeport",
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _idType = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElyfField(
                                    label: 'Numéro de pièce',
                                    controller: _idNumberController,
                                    hint: 'Ex: B12345678',
                                    prefixIcon: Icons.numbers_rounded,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: IgnorePointer(
                                      child: ElyfField(
                                        label: 'Date de délivrance',
                                        controller: TextEditingController(
                                          text: _idIssueDate != null
                                              ? DateFormat('dd/MM/yyyy').format(_idIssueDate!)
                                              : '',
                                        ),
                                        hint: 'Sélectionner la date',
                                        prefixIcon: Icons.calendar_today_outlined,
                                        suffixIcon: const Icon(Icons.arrow_drop_down),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      ElyfButton(
                        onPressed: _isSaving ? null : _handleConfirm,
                        isLoading: _isSaving,
                        icon: Icons.check_circle_outline,
                        height: 54,
                        child: const Text('Confirmer la Transaction'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Center(
                          child: Text(
                            'Annuler',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildSummaryRow(BuildContext context, String label, String value, Color valueColor, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
