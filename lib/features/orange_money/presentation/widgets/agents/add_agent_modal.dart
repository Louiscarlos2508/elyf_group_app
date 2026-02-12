import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_field.dart';

class AddAgentModal extends ConsumerStatefulWidget {
  const AddAgentModal({super.key, this.agent});

  final Agent? agent;

  @override
  ConsumerState<AddAgentModal> createState() => _AddAgentModalState();
}

class _AddAgentModalState extends ConsumerState<AddAgentModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _simController;
  late TextEditingController _liquidityController;
  late TextEditingController _commissionController;
  late TextEditingController _notesController;

  // State
  MobileOperator _selectedOperator = MobileOperator.orange;
  AgentStatus _selectedStatus = AgentStatus.active;
  AgentType _selectedType = AgentType.internal;
  List<String> _attachmentPaths = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final agent = widget.agent;
    _nameController = TextEditingController(text: agent?.name);
    _phoneController = TextEditingController(text: agent?.phoneNumber);
    _simController = TextEditingController(text: agent?.simNumber);
    _liquidityController = TextEditingController(text: agent?.liquidity.toString() ?? '0');
    _commissionController = TextEditingController(text: agent?.commissionRate.toString() ?? '0.0');
    _notesController = TextEditingController(text: agent?.notes);
    
    if (agent != null) {
      _selectedOperator = agent.operator;
      _selectedStatus = agent.status;
      _selectedType = agent.type;
      _attachmentPaths = List.from(agent.attachmentUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _simController.dispose();
    _liquidityController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachmentPaths.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la sélection de l\'image: $e');
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final agent = Agent(
        id: widget.agent?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        simNumber: _simController.text.trim(),
        operator: _selectedOperator,
        type: _selectedType,
        liquidity: int.tryParse(_liquidityController.text.trim()) ?? 0,
        commissionRate: double.tryParse(_commissionController.text.trim()) ?? 0.0,
        status: _selectedStatus,
        enterpriseId: widget.agent?.enterpriseId ?? '', // Will be handled by controller if empty
        attachmentUrls: _attachmentPaths,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.agent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(agentsControllerProvider);
      
      if (widget.agent == null) {
        await controller.createAgent(agent);
        if (mounted) NotificationService.showSuccess(context, 'Agent créé avec succès');
      } else {
        await controller.updateAgent(agent);
         if (mounted) NotificationService.showSuccess(context, 'Agent modifié avec succès');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.agent != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Modifier Point de Vente' : 'Nouveau Point de Vente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: Text(
              'ENREGISTRER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isLoading ? Colors.grey : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader('Informations Personnelles'),
              const SizedBox(height: 16),
              DropdownButtonFormField<AgentType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type de Point de Vente',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  prefixIcon: const Icon(Icons.business),
                ),
                items: AgentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 16),
              ElyfField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'ex: Ouédraogo Jean',
                prefixIcon: Icons.person_outline,
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              ElyfField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: 'ex: 70000000',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Configuration Orange Money'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElyfField(
                      controller: _simController,
                      label: 'Numéro SIM',
                      hint: 'ex: 60000000',
                      prefixIcon: Icons.sim_card_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<MobileOperator>(
                      initialValue: _selectedOperator,
                      decoration: InputDecoration(
                        labelText: 'Nom du Point de Vente',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                      ),
                      items: MobileOperator.values.map((op) {
                        return DropdownMenuItem(
                          value: op,
                          child: Text(op.label),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedOperator = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElyfField(
                      controller: _liquidityController,
                      label: 'Liquidité Initiale',
                      hint: '0',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                      suffixText: 'FCFA',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfField(
                      controller: _commissionController,
                      label: 'Taux Com.',
                      hint: '2.5',
                      prefixIcon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: '%',
                    ),
                  ),
                ],
              ),

               const SizedBox(height: 32),
              _buildSectionHeader('État & Notes'),
              const SizedBox(height: 16),

              DropdownButtonFormField<AgentStatus>(
                initialValue: _selectedStatus,
                 decoration: InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
                items: AgentStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(
                          s == AgentStatus.active ? Icons.check_circle : 
                          s == AgentStatus.suspended ? Icons.block : Icons.pause_circle,
                          color: s == AgentStatus.active ? AppColors.success : 
                                 s == AgentStatus.suspended ? AppColors.danger : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedStatus = v);
                },
              ),
              const SizedBox(height: 16),
               ElyfField(
                controller: _notesController,
                label: 'Notes / Commentaires',
                hint: 'Informations supplémentaires...',
                maxLines: 3,
                prefixIcon: Icons.note_alt_outlined,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Pièces Jointes (CNIB, Contrat)'),
              const SizedBox(height: 16),

              _buildAttachmentsSection(theme),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachmentPaths.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachmentPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final path = _attachmentPaths[index];
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        image: DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachmentPaths.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Prendre Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                 style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez des photos de la pièce d\'identité et du contrat.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
