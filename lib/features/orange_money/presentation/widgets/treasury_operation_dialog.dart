import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart' show LocalIdGenerator;
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class OrangeMoneyTreasuryOperationDialog extends ConsumerStatefulWidget {
  final TreasuryOperationType type;

  const OrangeMoneyTreasuryOperationDialog({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<OrangeMoneyTreasuryOperationDialog> createState() => _OrangeMoneyTreasuryOperationDialogState();
}

class _OrangeMoneyTreasuryOperationDialogState extends ConsumerState<OrangeMoneyTreasuryOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  
  PaymentMethod? _fromAccount;
  PaymentMethod? _toAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default accounts based on type
    if (widget.type == TreasuryOperationType.supply) {
      _toAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.removal) {
      _fromAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.transfer) {
      _fromAccount = PaymentMethod.cash;
      _toAccount = PaymentMethod.mobileMoney;
    } else if (widget.type == TreasuryOperationType.adjustment) {
      _toAccount = PaymentMethod.cash;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
      if (activeEnterpriseId == null) throw Exception('Entreprise active non trouvée');

      final userId = ref.read(authControllerProvider).currentUser?.id ?? 'system';
      final operation = TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: activeEnterpriseId,
        userId: userId,
        amount: int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        type: widget.type,
        fromAccount: _fromAccount,
        toAccount: _toAccount,
        date: DateTime.now(),
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
        recipient: _recipientController.text.isNotEmpty ? _recipientController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
      );

      await ref.read(orangeMoneyTreasuryRepositoryProvider).saveOperation(operation);
      
      // Invalidate providers
      ref.invalidate(orangeMoneyTreasuryBalanceProvider(activeEnterpriseId));
      ref.invalidate(orangeMoneyTreasuryOperationsStreamProvider(activeEnterpriseId));
      
      if (mounted) {
        Navigator.of(context).pop(true);
        NotificationService.showSuccess(context, 'Opération enregistrée avec succès');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getOperationColor();
    final title = _getOperationTitle();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormDialogHeader(
              title: title,
              icon: _getOperationIcon(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Account Selection
                      if (widget.type == TreasuryOperationType.transfer) ...[
                        _buildAccountDropdown(
                          label: 'Source',
                          value: _fromAccount,
                          onChanged: (v) => setState(() => _fromAccount = v),
                        ),
                        SizedBox(height: AppSpacing.md),
                        _buildAccountDropdown(
                          label: 'Destination',
                          value: _toAccount,
                          onChanged: (v) => setState(() => _toAccount = v),
                        ),
                      ] else if (widget.type == TreasuryOperationType.removal) ...[
                        _buildAccountDropdown(
                          label: 'Compte source',
                          value: _fromAccount,
                          onChanged: (v) => setState(() => _fromAccount = v),
                        ),
                      ] else ...[
                        _buildAccountDropdown(
                          label: 'Compte destination',
                          value: _toAccount,
                          onChanged: (v) => setState(() => _toAccount = v),
                        ),
                      ],
                      SizedBox(height: AppSpacing.md),
                      ElyfField(
                        label: 'Montant (CFA)',
                        hint: '0',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requis';
                          final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                          if (amount == null) return 'Nombre invalide';
                          if (amount <= 0) return 'Le montant doit être > 0';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      ElyfField(
                        label: 'Motif / Raison',
                        hint: 'Ex: Approvisionnement caisse',
                        controller: _reasonController,
                        prefixIcon: Icons.description_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requis';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      ElyfField(
                        label: 'Bénéficiaire / Provenance',
                        hint: 'Nom ou référence',
                        controller: _recipientController,
                        prefixIcon: Icons.person_rounded,
                      ),
                      SizedBox(height: AppSpacing.md),
                      ElyfField(
                        label: 'Notes (Optionnel)',
                        hint: 'Informations complémentaires...',
                        controller: _notesController,
                        prefixIcon: Icons.note_alt_rounded,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ANNULER'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return color.withValues(alpha: 0.5);
                          }
                          return color;
                        }),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required PaymentMethod? value,
    required ValueChanged<PaymentMethod?> onChanged,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<PaymentMethod>(
      value: value,
      dropdownColor: theme.colorScheme.surface,
      elevation: 8,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.account_balance_outlined, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        PaymentMethod.cash,
        PaymentMethod.mobileMoney,
      ].map((m) => DropdownMenuItem(
        value: m,
        child: Text(m.label),
      )).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Requis' : null,
    );
  }

  Color _getOperationColor() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return Colors.green;
      case TreasuryOperationType.removal: return Colors.orange;
      case TreasuryOperationType.transfer: return Colors.blue;
      case TreasuryOperationType.adjustment: return Colors.grey;
    }
  }

  String _getOperationTitle() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return 'Nouvel Apport';
      case TreasuryOperationType.removal: return 'Nouveau Retrait';
      case TreasuryOperationType.transfer: return 'Nouveau Transfert';
      case TreasuryOperationType.adjustment: return 'Nouvel Ajustement';
    }
  }

  IconData _getOperationIcon() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return Icons.add_circle;
      case TreasuryOperationType.removal: return Icons.remove_circle;
      case TreasuryOperationType.transfer: return Icons.swap_horiz;
      case TreasuryOperationType.adjustment: return Icons.tune;
    }
  }
}
