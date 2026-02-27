import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_enterprise_extensions.dart';

/// Type de transaction pour la recharge/retrait d'un agent.
enum AgentTransactionType { recharge, retrait }

/// Dialog for recharging or withdrawing from an agent's liquidity.
class AgentRechargeDialog extends StatefulWidget {
  const AgentRechargeDialog({
    super.key,
    required this.agents,
    required this.agencies,
    required this.onConfirm,
  });

  final List<entity.Agent> agents;
  final List<Enterprise> agencies;
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
  bool _isAgencyRecharge = false; // False = Agent (SIM), True = Agence (Cash)
  dynamic _selectedEntity;

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

    if (_selectedEntity == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner une entité',
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      NotificationService.showWarning(context, 'Le montant doit être supérieur à 0');
      return;
    }

    widget.onConfirm(
      _selectedEntity!,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: EdgeInsets.all(isKeyboardOpen ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                // Header with close button
                Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedType == AgentTransactionType.recharge 
                            ? '💵 Recharge entité'
                            : '💸 Retrait entité',
                          style: TextStyle(
                            fontSize: isKeyboardOpen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                        if (!isKeyboardOpen) ...[
                          const SizedBox(height: 8),
                          Text(
                            _selectedType == AgentTransactionType.recharge
                              ? 'Attribution de liquidité Mobile Money au point de vente'
                              : 'Récupération de liquidité Mobile Money depuis le point de vente',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? 12 : 24),
                // Entity Type Selector
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Agent (SIM)'), icon: Icon(Icons.person_outline)),
                    ButtonSegment(value: true, label: Text('Agence (Cash)'), icon: Icon(Icons.business_outlined)),
                  ],
                  selected: {_isAgencyRecharge},
                  onSelectionChanged: (val) => setState(() {
                    _isAgencyRecharge = val.first;
                    _selectedEntity = null;
                  }),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: isKeyboardOpen ? VisualDensity.compact : VisualDensity.standard,
                  ),
                ),
                SizedBox(height: isKeyboardOpen ? 12 : 16),
                // Entity selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAgencyRecharge ? 'Sélectionner l\'Agence *' : 'Sélectionner le Compte Agent *',
                      style: TextStyle(fontSize: isKeyboardOpen ? 13 : 14, color: const Color(0xFF0A0A0A)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: isKeyboardOpen ? 40 : 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          value: _selectedEntity,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                          items: _isAgencyRecharge 
                            ? widget.agencies.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList()
                            : widget.agents.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                          onChanged: (value) => setState(() => _selectedEntity = value),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? 12 : 16),
                // Transaction type selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Type de mouvement',
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
                          child: _buildTypeButton(
                            AgentTransactionType.recharge,
                            'Recharge',
                            Icons.arrow_downward,
                            isKeyboardOpen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeButton(
                            AgentTransactionType.retrait,
                            'Retrait',
                            Icons.arrow_upward,
                            isKeyboardOpen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? 12 : 16),
                // Amount field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant (FCFA) *',
                      style: TextStyle(
                        fontSize: isKeyboardOpen ? 13 : 14,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 50000',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF717182),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isKeyboardOpen ? 8 : 10,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
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
                SizedBox(height: isKeyboardOpen ? 12 : 16),
                // Notes field
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
                    TextField(
                      controller: _notesController,
                      maxLines: isKeyboardOpen ? 1 : 2,
                      decoration: InputDecoration(
                        hintText: 'Informations complémentaires...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isKeyboardOpen ? 16 : 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                            width: 1.219,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: isKeyboardOpen ? 8 : 12,
                          ),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A63E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isKeyboardOpen ? 8 : 12,
                          ),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Valider',
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
      ),
    );
  }

  Widget _buildTypeButton(
    AgentTransactionType type,
    String label,
    IconData icon,
    bool isKeyboardOpen,
  ) {
    final isSelected = _selectedType == type;
    final backgroundColor = isSelected ? const Color(0xFF030213) : Colors.white;
    final textColor = isSelected ? Colors.white : const Color(0xFF0A0A0A);
    final borderColor = isSelected
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.1);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isKeyboardOpen ? 32 : 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.219),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isKeyboardOpen ? 14 : 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isKeyboardOpen ? 12 : 14,
                fontWeight: FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
