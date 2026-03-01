import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/agent.dart' as entity;
import '../../../domain/entities/orange_money_enterprise_extensions.dart';
import '../../../../administration/domain/entities/enterprise.dart';
import '../../../application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_field.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/orange_money/application/controllers/agents_controller.dart';

class AddAgentAccountModal extends ConsumerStatefulWidget {
  const AddAgentAccountModal({
    super.key,
    this.agentAccount,
    this.isReadOnly = false,
  });

  final entity.Agent? agentAccount;
  final bool isReadOnly;

  @override
  ConsumerState<AddAgentAccountModal> createState() => _AddAgentAccountModalState();
}

class _AddAgentAccountModalState extends ConsumerState<AddAgentAccountModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _simController;
  late TextEditingController _notesController;

  // State
  entity.MobileOperator _selectedAgentOperator = entity.MobileOperator.orange;
  entity.AgentStatus _agentStatus = entity.AgentStatus.active;
  String? _linkedAgencyId;
  List<String> _attachmentPaths = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.agentAccount != null) {
      _initAgentFields(widget.agentAccount!);
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _simController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  void _initAgentFields(entity.Agent agent) {
    _nameController = TextEditingController(text: agent.name);
    _phoneController = TextEditingController(text: agent.phoneNumber);
    _simController = TextEditingController(text: agent.simNumber);
    _notesController = TextEditingController(text: agent.notes);
    _selectedAgentOperator = agent.operator;
    _agentStatus = agent.status;
    
    // We keep the raw enterpriseId in state. 
    // The mapping to null (Independent) will be handled in the build method.
    _linkedAgencyId = agent.enterpriseId;
    
    _attachmentPaths = List<String>.from(agent.attachmentUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _simController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _attachmentPaths.addAll(result.paths.whereType<String>());
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la sélection des fichiers: $e');
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(agentsControllerProvider);
      
      final agent = entity.Agent(
        id: widget.agentAccount?.id ?? '',
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        simNumber: _simController.text.trim(),
        operator: entity.MobileOperator.orange,
        liquidity: widget.agentAccount?.liquidity ?? 0,
        commissionRate: widget.agentAccount?.commissionRate ?? 0.0,
        status: _agentStatus,
        enterpriseId: _linkedAgencyId ?? ref.read(activeEnterpriseProvider).value?.id ?? '',
        notes: _notesController.text.trim(),
        attachmentUrls: _attachmentPaths,
        updatedAt: DateTime.now(),
        createdAt: widget.agentAccount?.createdAt ?? DateTime.now(),
      );

      if (widget.agentAccount == null) {
        await controller.createAgent(agent);
        if (mounted) NotificationService.showSuccess(context, 'Compte Agent créé avec succès');
      } else {
        await controller.updateAgent(agent);
        if (mounted) NotificationService.showSuccess(context, 'Compte Agent modifié avec succès');
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
    final isEditing = widget.agentAccount != null;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isReadOnly 
            ? 'Détails Compte Agent'
            : ((isEditing ? 'Modifier Compte Agent' : 'Nouveau Compte Agent') + ' (FIXED)'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
        actions: widget.isReadOnly ? [] : [
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
            padding: EdgeInsets.all(isKeyboardOpen ? 16 : 24),
            children: [
              _buildFormFields(theme, isKeyboardOpen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme, bool isKeyboardOpen) {
    // Key format: "parentId|type|searchQuery|excludeAssigned"
    final agenciesAsync = ref.watch(agentAgenciesProvider('|||true'));

    return Column(
      children: [
        _buildSectionHeader('Identification du Compte (SIM)'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        ElyfField(
          controller: _nameController,
          label: 'Nom de l\'Agent (Titulaire)',
          hint: 'ex: Carlos Simporé',
          prefixIcon: Icons.person_outline,
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        agenciesAsync.when(
          data: (agencies) {
            final activeId = ref.watch(activeEnterpriseProvider).value?.id;
            
            // Map the selection: if it's the active enterprise, treat it as null (Independent)
            final effectiveValue = (_linkedAgencyId == activeId) ? null : _linkedAgencyId;
            
            // Safety: Ensure the value exists in the list (or is null)
            final exists = effectiveValue == null || agencies.any((a) => a.id == effectiveValue);
            final dropdownValue = exists ? effectiveValue : null;
            
            return DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: InputDecoration(
                labelText: 'Affectation à une Agence',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                prefixIcon: const Icon(Icons.link),
                contentPadding: isKeyboardOpen ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Aucune agence (Indépendant)')),
                ...agencies.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
              ],
              onChanged: widget.isReadOnly ? null : (v) => setState(() => _linkedAgencyId = v),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Erreur de chargement des agences'),
        ),
        SizedBox(height: isKeyboardOpen ? 16 : 32),
        _buildSectionHeader('Détails SIM & Opérateur'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        Row(
          children: [
            Expanded(
               child: ElyfField(
                controller: _phoneController,
                label: 'N° de Téléphone SIM',
                hint: 'ex: 60000000',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                readOnly: widget.isReadOnly,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfField(
                label: 'Opérateur',
                initialValue: 'Orange Money',
                readOnly: true,
                prefixIcon: Icons.business,
              ),
            ),
          ],
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
         ElyfField(
          controller: _simController,
          label: 'N° de Série SIM / Code Agent',
          hint: 'ex: 123456789',
          prefixIcon: Icons.sim_card_outlined,
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 16 : 32),
        _buildSectionHeader('État & Documents'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        DropdownButtonFormField<entity.AgentStatus>(
          value: _agentStatus,
          decoration: InputDecoration(
            labelText: 'Statut du compte',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: isKeyboardOpen ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
          ),
          items: entity.AgentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
          onChanged: widget.isReadOnly ? null : (v) { if (v != null) setState(() => _agentStatus = v); },
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        _buildAttachmentsSection(theme, isKeyboardOpen),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _notesController,
          label: 'Notes / Observations',
          hint: 'ex: SIM de remplacement...',
          maxLines: isKeyboardOpen ? 1 : 3,
          prefixIcon: Icons.notes,
          readOnly: widget.isReadOnly,
        ),
      ],
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

  Widget _buildAttachmentsSection(ThemeData theme, bool isKeyboardOpen) {
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
                        image: (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.png') || path.toLowerCase().endsWith('.jpeg'))
                          ? (path.startsWith('http') 
                              ? DecorationImage(image: NetworkImage(path), fit: BoxFit.cover)
                              : DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover))
                          : null,
                      ),
                      child: (path.toLowerCase().endsWith('.pdf'))
                        ? const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red))
                        : null,
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

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('Ajouter des documents'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photos des pièces d\'identité, contrats ou PDF.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
