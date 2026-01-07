import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tenant/tenant_provider.dart';
import '../../../../shared.dart';
import '../../domain/entities/agent.dart';

/// Dialog for creating or editing an agent.
class AgentFormDialog extends ConsumerStatefulWidget {
  const AgentFormDialog({
    super.key,
    this.agent,
    required this.onSave,
  });

  final Agent? agent;
  final Function(Agent) onSave;

  @override
  ConsumerState<AgentFormDialog> createState() => _AgentFormDialogState();
}

class _AgentFormDialogState extends ConsumerState<AgentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _simController;
  late TextEditingController _liquidityController;
  late TextEditingController _commissionRateController;
  late MobileOperator _selectedOperator;
  late AgentStatus _selectedStatus;
  String? _enterpriseId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agent?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.agent?.phoneNumber ?? '');
    _simController = TextEditingController(text: widget.agent?.simNumber ?? '');
    _liquidityController =
        TextEditingController(text: widget.agent?.liquidity.toString() ?? '0');
    _commissionRateController = TextEditingController(
        text: widget.agent?.commissionRate.toString() ?? '2.5');
    _selectedOperator = widget.agent?.operator ?? MobileOperator.orange;
    _selectedStatus = widget.agent?.status ?? AgentStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _simController.dispose();
    _liquidityController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  void _handleSave(String? enterpriseId) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (enterpriseId == null) {
      NotificationService.showInfo(context, 'Aucune entreprise sélectionnée');
      return;
    }

    final agent = Agent(
      id: widget.agent?.id ?? IdGenerator.generate(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      simNumber: _simController.text.trim(),
      operator: _selectedOperator,
      liquidity: int.tryParse(_liquidityController.text.trim()) ?? 0,
      commissionRate:
          double.tryParse(_commissionRateController.text.trim()) ?? 2.5,
      status: _selectedStatus,
      enterpriseId: enterpriseId,
      createdAt: widget.agent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(agent);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    // Récupérer l'ID de l'entreprise active
    final enterpriseId = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise?.id,
      loading: () => null,
      error: (_, __) => null,
    );

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.agent == null ? 'Nouvel agent' : 'Modifier l\'agent',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _simController,
                decoration: const InputDecoration(
                  labelText: 'Numéro SIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le numéro SIM est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MobileOperator>(
      value: _selectedOperator,
      decoration: const InputDecoration(
        labelText: 'Opérateur',
        border: OutlineInputBorder(),
      ),
      items: MobileOperator.values.map((MobileOperator op) {
                  return DropdownMenuItem(
                    value: op,
                    child: Text(op.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOperator = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _liquidityController,
                decoration: const InputDecoration(
                  labelText: 'Liquidité (FCFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La liquidité est requise';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commissionRateController,
                decoration: const InputDecoration(
                  labelText: 'Taux commission (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le taux est requis';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Taux invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AgentStatus>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
      ),
      items: AgentStatus.values.map((AgentStatus status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleSave(enterpriseId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF54900),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enregistrer'),
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

