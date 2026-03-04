import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/services/liquidity_checkpoint_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Dialog pour créer ou modifier un pointage de liquidité.
class LiquidityCheckpointDialog extends StatefulWidget {
  const LiquidityCheckpointDialog({
    super.key,
    this.checkpoint,
    this.enterpriseId,
    required this.period,
  });

  final LiquidityCheckpoint? checkpoint;
  final String? enterpriseId;
  final LiquidityCheckpointType period;

  @override
  State<LiquidityCheckpointDialog> createState() =>
      _LiquidityCheckpointDialogState();
}

class _LiquidityCheckpointDialogState extends State<LiquidityCheckpointDialog> {
  LiquidityCheckpointType _selectedPeriod = LiquidityCheckpointType.morning;
  DateTime _selectedDate = DateTime.now();
  final _cashController = TextEditingController();
  final _simController = TextEditingController();
  final _notesController = TextEditingController();
  final _modificationReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
    if (widget.checkpoint != null) {
      _selectedDate = widget.checkpoint!.date;
      // Charger les valeurs selon la période demandée
      if (widget.period == LiquidityCheckpointType.morning) {
        _cashController.text =
            widget.checkpoint!.morningCashAmount?.toString() ?? '';
        _simController.text =
            widget.checkpoint!.morningSimAmount?.toString() ?? '';
      } else if (widget.period == LiquidityCheckpointType.evening) {
        _cashController.text =
            widget.checkpoint!.eveningCashAmount?.toString() ?? '';
        _simController.text =
            widget.checkpoint!.eveningSimAmount?.toString() ?? '';
      } else {
        // Fallback pour compatibilité
        _cashController.text = widget.checkpoint!.cashAmount?.toString() ?? '';
        _simController.text = widget.checkpoint!.simAmount?.toString() ?? '';
      }
      _notesController.text = widget.checkpoint!.notes ?? '';
      _modificationReasonController.text = widget.checkpoint!.modificationReason ?? '';
    }
    // Écouter les changements pour mettre à jour le total
    _cashController.addListener(() => setState(() {}));
    _simController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cashController.dispose();
    _simController.dispose();
    _notesController.dispose();
    _modificationReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cashAmount = int.tryParse(_cashController.text.trim()) ?? 0;
    final simAmount = int.tryParse(_simController.text.trim()) ?? 0;

    // Validation via le service
    final validationError = LiquidityCheckpointService.validateAtLeastOneAmount(
      cashAmount,
      simAmount,
    );
    if (validationError != null) {
      NotificationService.showWarning(context, validationError);
      return;
    }

    // Création du checkpoint via le service
    final checkpoint = LiquidityCheckpointService.createCheckpointFromInput(
      existingId: widget.checkpoint?.id,
      enterpriseId:
          widget.enterpriseId ?? widget.checkpoint?.enterpriseId ?? '',
      date: _selectedDate,
      period: _selectedPeriod,
      cashAmount: cashAmount,
      simAmount: simAmount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      modificationReason: _modificationReasonController.text.trim().isEmpty
          ? null
          : _modificationReasonController.text.trim(),
      existingCheckpoint: widget.checkpoint,
    );

    Navigator.of(context).pop(checkpoint);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormDialogHeader(
              title: 'Pointage de liquidité',
              subtitle: 'Enregistrez les montants en cash et sur la SIM',
              icon: Icons.account_balance_wallet_rounded,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.sectionPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Période et Date selectors
                      Row(
                        children: [
                          Expanded(child: _buildPeriodSelector(theme)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _buildDateField(theme)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Cash disponible
                      ElyfField(
                        label: '💵 Cash disponible (FCFA) *',
                        controller: _cashController,
                        hint: 'Argent liquide en caisse',
                        keyboardType: TextInputType.number,
                        validator: LiquidityCheckpointService.validateAmount,
                        prefixIcon: Icons.payments_rounded,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Montant total des espèces physiques',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Solde sur la SIM
                      ElyfField(
                        label: '📱 Solde sur la SIM (FCFA) *',
                        controller: _simController,
                        hint: 'Solde Orange Money',
                        keyboardType: TextInputType.number,
                        validator: LiquidityCheckpointService.validateAmount,
                        prefixIcon: Icons.sim_card_rounded,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Vérifiez votre solde : *144#',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Notes
                      ElyfField(
                        label: 'Notes (optionnel)',
                        controller: _notesController,
                        hint: 'Observations ou remarques...',
                        maxLines: 2,
                        prefixIcon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Audit Trail (Modification Reason) - Only if editing
                      if (widget.checkpoint != null) ...[
                        ElyfField(
                          label: 'Motif de la modification *',
                          controller: _modificationReasonController,
                          hint: 'Pourquoi modifiez-vous ce pointage ?',
                          maxLines: 2,
                          prefixIcon: Icons.history_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le motif est obligatoire pour toute modification';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Obligatoire pour l\'audit trail',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Liquidité totale visualization
                      _buildTotalLiquiditySection(theme),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: AppSpacing.dialogPadding,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildPeriodSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période *',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPeriodButton(
                  theme: theme,
                  label: 'Matin',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: _selectedPeriod == LiquidityCheckpointType.morning,
                  onTap: () => setState(() => _selectedPeriod = LiquidityCheckpointType.morning),
                ),
              ),
              Expanded(
                child: _buildPeriodButton(
                  theme: theme,
                  label: 'Soir',
                  icon: Icons.nights_stay_rounded,
                  isSelected: _selectedPeriod == LiquidityCheckpointType.evening,
                  onTap: () => setState(() => _selectedPeriod = LiquidityCheckpointType.evening),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, 
                  size: 16, 
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalLiquiditySection(ThemeData theme) {
    final cashAmount = int.tryParse(_cashController.text.trim()) ?? 0;
    final simAmount = int.tryParse(_simController.text.trim()) ?? 0;
    final total = cashAmount + simAmount;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, 
                size: 20, 
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'LIQUIDITÉ TOTALE',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.formatFCFA(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCompactStat('💵 Cash', cashAmount, theme)),
              const SizedBox(width: 24),
              Expanded(child: _buildCompactStat('📱 SIM', simAmount, theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, int amount, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatShort(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}
