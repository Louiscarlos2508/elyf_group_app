import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/services/liquidity_checkpoint_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'form_field_with_label.dart';

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
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      existingCheckpoint: widget.checkpoint,
    );

    Navigator.of(context).pop(checkpoint);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 509,
        padding: EdgeInsets.all(isKeyboardOpen ? 16 : 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pointage de liquidité',
                          style: TextStyle(
                            fontSize: isKeyboardOpen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                        if (!isKeyboardOpen) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Enregistrez les montants disponibles en cash et sur la SIM',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: isKeyboardOpen ? 12 : 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Période et Date
                      Row(
                        children: [
                          Expanded(child: _buildPeriodSelector(isKeyboardOpen)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDateField(isKeyboardOpen)),
                        ],
                      ),
                      SizedBox(height: isKeyboardOpen ? 12 : 16),
                      // Cash disponible
                      FormFieldWithLabel(
                        label: '💵 Cash disponible (FCFA) *',
                        controller: _cashController,
                        hintText: 'Argent liquide comptabilisé',
                        keyboardType: TextInputType.number,
                        validator: LiquidityCheckpointService.validateAmount,
                      ),
                      if (!isKeyboardOpen) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Montant en espèces physiques que vous avez',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4A5565)),
                        ),
                      ],
                      SizedBox(height: isKeyboardOpen ? 12 : 16),
                      // Solde sur la SIM
                      FormFieldWithLabel(
                        label: '📱 Solde sur la SIM (FCFA) *',
                        controller: _simController,
                        hintText: 'Solde Orange Money / MTN / Moov',
                        keyboardType: TextInputType.number,
                        validator: LiquidityCheckpointService.validateAmount,
                      ),
                      if (!isKeyboardOpen) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Vérifiez votre solde : *144# (Orange), *126# (MTN)',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4A5565)),
                        ),
                      ],
                      SizedBox(height: isKeyboardOpen ? 12 : 16),
                      // Notes
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes (optionnel)',
                            style: TextStyle(
                              fontSize: isKeyboardOpen ? 13 : 14,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: isKeyboardOpen ? 1 : 2,
                            decoration: InputDecoration(
                              hintText: 'Informations complémentaires...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF717182),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF3F3F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isKeyboardOpen ? 12 : 16),
                      // Liquidité totale
                      _buildTotalLiquiditySection(isKeyboardOpen),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isKeyboardOpen ? 16 : 24),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE5E5E5),
                          width: 1.219,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: isKeyboardOpen ? 8 : 12),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: isKeyboardOpen ? 13 : 14,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155DFC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: isKeyboardOpen ? 8 : 12),
                      ),
                      child: Text(
                        'Enregistrer',
                        style: TextStyle(fontSize: isKeyboardOpen ? 13 : 14),
                      ),
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

  Widget _buildPeriodSelector(bool isKeyboardOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période *',
          style: TextStyle(
            fontSize: isKeyboardOpen ? 13 : 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPeriodButton(
                label: 'Matin',
                icon: Icons.wb_sunny,
                isSelected: _selectedPeriod == LiquidityCheckpointType.morning,
                onTap: () {
                  setState(() {
                    _selectedPeriod = LiquidityCheckpointType.morning;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPeriodButton(
                label: 'Soir',
                icon: Icons.nightlight_round,
                isSelected: _selectedPeriod == LiquidityCheckpointType.evening,
                onTap: () {
                  setState(() {
                    _selectedPeriod = LiquidityCheckpointType.evening;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF54900) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF54900)
                : const Color(0xFFE5E5E5),
            width: 1.219,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(bool isKeyboardOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: TextStyle(
            fontSize: isKeyboardOpen ? 13 : 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 1.219),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF717182),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalLiquiditySection(bool isKeyboardOpen) {
    final cashAmount = int.tryParse(_cashController.text.trim()) ?? 0;
    final simAmount = int.tryParse(_simController.text.trim()) ?? 0;
    final total = cashAmount + simAmount;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9F8CF), width: 1.219),
      ),
      padding: EdgeInsets.all(isKeyboardOpen ? 10 : 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Liquidité totale',
            style: TextStyle(fontSize: isKeyboardOpen ? 12 : 14, color: const Color(0xFF0D542B)),
          ),
          SizedBox(height: isKeyboardOpen ? 0 : 4),
          Text(
            CurrencyFormatter.formatShort(total),
            style: TextStyle(
              fontSize: isKeyboardOpen ? 20 : 24,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF008236),
            ),
          ),
          if (!isKeyboardOpen) ...[
            const SizedBox(height: 4),
            Text(
              'Cash: ${CurrencyFormatter.formatShort(cashAmount)} + SIM: ${CurrencyFormatter.formatShort(simAmount)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF00A63E)),
            ),
          ],
        ],
      ),
    );
  }
}
