import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/app_radius.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// Type de transaction pour la recharge/retrait d'un agent.
enum AgentTransactionType { recharge, retrait }

/// Dialog for recharging or withdrawing from an agent's liquidity.
class AgentRechargeDialog extends StatefulWidget {
  const AgentRechargeDialog({
    super.key,
    required this.agents,
    required this.onConfirm,
  });

  final List<entity.Agent> agents;
  final Function(
    dynamic entity,
    AgentTransactionType type,
    int amount,
    String? notes,
  ) onConfirm;

  @override
  State<AgentRechargeDialog> createState() => _AgentRechargeDialogState();
}

class _AgentRechargeDialogState extends State<AgentRechargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  AgentTransactionType _selectedType = AgentTransactionType.recharge;
  entity.Agent? _selectedAgent;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAgent == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner un compte agent',
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      NotificationService.showWarning(context, 'Le montant doit être supérieur à 0');
      return;
    }

    widget.onConfirm(
      _selectedAgent!,
      _selectedType,
      amount,
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: EdgeInsets.all(isKeyboardOpen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedType == AgentTransactionType.recharge 
                            ? '💵 Recharge Agent'
                            : '💸 Retrait Agent',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        if (!isKeyboardOpen) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _selectedType == AgentTransactionType.recharge
                              ? 'Attribution de liquidité SIM'
                              : 'Récupération de liquidité SIM',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? AppSpacing.md : AppSpacing.lg),
                
                // Agent selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte Agent (SIM) *',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<entity.Agent>(
                          value: _selectedAgent,
                          isExpanded: true,
                          hint: Text('Sélectionner un agent', style: theme.textTheme.bodyMedium),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          items: widget.agents.map((a) => DropdownMenuItem(
                            value: a, 
                            child: Text(
                              '${a.name} (${a.simNumber})',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedAgent = value),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Transaction type selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Type de mouvement',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            AgentTransactionType.recharge,
                            'Recharge',
                            Icons.arrow_downward_rounded,
                            isKeyboardOpen,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTypeButton(
                            AgentTransactionType.retrait,
                            'Retrait',
                            Icons.arrow_upward_rounded,
                            isKeyboardOpen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Amount field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant (FCFA) *',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 50 000',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le montant est requis';
                        }
                        final amount = int.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Notes field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes optionnelles',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _notesController,
                      maxLines: isKeyboardOpen ? 1 : 2,
                      decoration: InputDecoration(
                        hintText: 'Détails de la transaction...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? AppSpacing.md : AppSpacing.xl),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Valider'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    AgentTransactionType type,
    String label,
    IconData icon,
    bool isKeyboardOpen,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;
    final backgroundColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = isSelected ? Colors.white : theme.colorScheme.onSurface;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.2);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
