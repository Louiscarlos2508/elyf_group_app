import '../../../../../shared/utils/notification_service.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/agent.dart';

/// Type de transaction pour la recharge/retrait d'un agent.
enum AgentTransactionType {
  recharge,
  retrait,
}

/// Dialog for recharging or withdrawing from an agent's liquidity.
class AgentRechargeDialog extends StatefulWidget {
  const AgentRechargeDialog({
    super.key,
    required this.agents,
    required this.onConfirm,
  });

  final List<Agent> agents;
  final Function(Agent agent, AgentTransactionType type, int amount, String? notes) onConfirm;

  @override
  State<AgentRechargeDialog> createState() => _AgentRechargeDialogState();
}

class _AgentRechargeDialogState extends State<AgentRechargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  AgentTransactionType _selectedType = AgentTransactionType.recharge;
  Agent? _selectedAgent;

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
      NotificationService.showWarning(context, 'Veuillez sélectionner un agent');
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
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
                      const Text(
                        '💵 Recharge agent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'L\'agent vient recharger sa liquidité chez vous',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                        ),
                      ),
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
              const SizedBox(height: 24),
              // Transaction type selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type de transaction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          AgentTransactionType.retrait,
                          'Retrait',
                          Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Agent selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agent *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13.219, vertical: 1.219),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.transparent, width: 1.219),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Agent?>(
                        value: _selectedAgent,
                        hint: const Text(
                          'Sélectionner un agent',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF717182),
                          ),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                        items: widget.agents.map((agent) {
                          return DropdownMenuItem(
                            value: agent,
                            child: Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAgent = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amount field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant (FCFA) *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
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
              const SizedBox(height: 16),
              // Notes field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes (optionnel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
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
              const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A0A0A),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Valider',
                        style: TextStyle(
                          fontSize: 14,
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
    );
  }

  Widget _buildTypeButton(
    AgentTransactionType type,
    String label,
    IconData icon,
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
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: 1.219,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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

