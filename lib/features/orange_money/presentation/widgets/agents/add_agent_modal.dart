import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/agent.dart' as entity;
import '../../../domain/entities/orange_money_enterprise_extensions.dart';
import '../../../../administration/domain/entities/enterprise.dart';
import '../../../application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_field.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/orange_money/application/controllers/agents_controller.dart';

enum CreationType { agent, agency }

class AddAgentModal extends ConsumerStatefulWidget {
  const AddAgentModal({super.key, this.agency, this.agentAccount});

  final Enterprise? agency;
  final entity.Agent? agentAccount;

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
  CreationType _creationType = CreationType.agent;
  String _selectedOperatorName = 'Orange Money';
  EnterpriseType _selectedAgencyType = EnterpriseType.mobileMoneySubAgent;
  entity.MobileOperator _selectedAgentOperator = entity.MobileOperator.orange;
  entity.AgentStatus _agentStatus = entity.AgentStatus.active;
  bool _isActiveAgency = true;
  String? _linkedAgencyId;
  List<String> _attachmentPaths = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.agency != null) {
      _creationType = CreationType.agency;
      _initAgencyFields(widget.agency!);
    } else if (widget.agentAccount != null) {
      _creationType = CreationType.agent;
      _initAgentFields(widget.agentAccount!);
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _simController = TextEditingController();
      _liquidityController = TextEditingController(text: '0');
      _commissionController = TextEditingController(text: '0.0');
      _notesController = TextEditingController();
    }
  }

  void _initAgencyFields(Enterprise agency) {
    _nameController = TextEditingController(text: agency.name);
    _phoneController = TextEditingController(text: agency.phone);
    _simController = TextEditingController(); // Not relevant for agency anymore
    _liquidityController = TextEditingController(text: agency.floatBalance?.toString() ?? '0');
    _commissionController = TextEditingController();
    _notesController = TextEditingController(text: agency.description);
    _selectedAgencyType = agency.type;
    _isActiveAgency = agency.isActive;
  }

  void _initAgentFields(entity.Agent agent) {
    _nameController = TextEditingController(text: agent.name);
    _phoneController = TextEditingController(text: agent.phoneNumber);
    _simController = TextEditingController(text: agent.simNumber);
    _liquidityController = TextEditingController(text: agent.liquidity.toString());
    _commissionController = TextEditingController(text: agent.commissionRate.toString());
    _notesController = TextEditingController(text: agent.notes);
    _selectedAgentOperator = agent.operator;
    _agentStatus = agent.status;
    _linkedAgencyId = agent.enterpriseId;
    _attachmentPaths = List<String>.from(agent.attachmentUrls);
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
      final controller = ref.read(agentsControllerProvider);
      
      if (_creationType == CreationType.agency) {
        await _saveAgency(controller);
      } else {
        await _saveAgentAccount(controller);
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

  Future<void> _saveAgency(AgentsController controller) async {
    final agency = (widget.agency ?? Enterprise(
      id: '',
      name: _nameController.text.trim(),
      type: _selectedAgencyType,
      moduleId: 'orange_money',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).copyWith(
      name: _nameController.text.trim(),
      type: _selectedAgencyType,
      phone: _phoneController.text.trim(),
      description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isActive: _isActiveAgency,
      updatedAt: DateTime.now(),
    ).copyWithOrangeMoneyMetadata(
      floatBalance: int.tryParse(_liquidityController.text.trim()) ?? 0,
    );

    if (widget.agency == null) {
      await controller.createAgency(agency);
      if (mounted) NotificationService.showSuccess(context, 'Agence créée avec succès');
    } else {
      await controller.updateAgency(agency);
      if (mounted) NotificationService.showSuccess(context, 'Agence modifiée avec succès');
    }
  }

  Future<void> _saveAgentAccount(AgentsController controller) async {
    final agent = entity.Agent(
      id: widget.agentAccount?.id ?? '',
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      simNumber: _simController.text.trim(),
      operator: _selectedAgentOperator,
      liquidity: int.tryParse(_liquidityController.text.trim()) ?? 0,
      commissionRate: double.tryParse(_commissionController.text.trim()) ?? 0.0,
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
          isEditing ? 'Modifier l\'entité' : 'Nouvelle entité',
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
            padding: EdgeInsets.all(isKeyboardOpen ? 16 : 24),
            children: [
              if (!isEditing) _buildTypeSelector(theme),
              SizedBox(height: isKeyboardOpen ? 12 : 24),
              _buildFormFields(theme, isKeyboardOpen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return SegmentedButton<CreationType>(
      segments: const [
        ButtonSegment(
          value: CreationType.agent,
          label: Text('Agent (Compte/SIM)'),
          icon: Icon(Icons.person_pin_outlined),
        ),
        ButtonSegment(
          value: CreationType.agency,
          label: Text('Agence (Kiosque/PDV)'),
          icon: Icon(Icons.business_outlined),
        ),
      ],
      selected: {_creationType},
      onSelectionChanged: (Set<CreationType> newSelection) {
        setState(() {
          _creationType = newSelection.first;
        });
      },
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: theme.colorScheme.primary,
        selectedForegroundColor: theme.colorScheme.onPrimary,
        visualDensity: isKeyboardOpen ? VisualDensity.compact : VisualDensity.standard,
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme, bool isKeyboardOpen) {
    if (_creationType == CreationType.agency) {
      return _buildAgencyForm(theme, isKeyboardOpen);
    } else {
      return _buildAgentForm(theme, isKeyboardOpen);
    }
  }

  Widget _buildAgencyForm(ThemeData theme, bool isKeyboardOpen) {
    return Column(
      children: [
        _buildSectionHeader('Informations Génerales Agence'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        DropdownButtonFormField<EnterpriseType>(
          value: _selectedAgencyType,
          decoration: InputDecoration(
            labelText: 'Type d\'agence',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            prefixIcon: const Icon(Icons.business),
            contentPadding: isKeyboardOpen ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
          ),
          items: [
            EnterpriseType.mobileMoneySubAgent,
            EnterpriseType.mobileMoneyKiosk,
            EnterpriseType.mobileMoneyDistributor,
          ].map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedAgencyType = v);
          },
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _nameController,
          label: 'Nom de l\'agence / Boutique',
          hint: 'ex: Agence Centre-Ville',
          prefixIcon: Icons.store_mall_directory_outlined,
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _phoneController,
          label: 'Téléphone agence',
          hint: 'ex: 70000000',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _liquidityController,
          label: 'Solde Cash Initial',
          hint: '0',
          prefixIcon: Icons.money_outlined,
          keyboardType: TextInputType.number,
          suffixText: 'FCFA',
        ),
        SizedBox(height: isKeyboardOpen ? 16 : 32),
        _buildSectionHeader('État & Notes'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        SwitchListTile(
          title: const Text('Agence Active'),
          value: _isActiveAgency,
          onChanged: (v) => setState(() => _isActiveAgency = v)
        ),
        ElyfField(
          controller: _notesController,
          label: 'Notes / Adresse',
          hint: 'ex: Situé près du grand marché...',
          maxLines: isKeyboardOpen ? 1 : 3,
          prefixIcon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildAgentForm(ThemeData theme, bool isKeyboardOpen) {
    final agenciesAsync = ref.watch(agentAgenciesProvider(''));

    return Column(
      children: [
        _buildSectionHeader('Identification du Compte Agent'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        ElyfField(
          controller: _nameController,
          label: 'Nom de l\'Agent (Employé)',
          hint: 'ex: Jean Dupont',
          prefixIcon: Icons.person_outline,
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        agenciesAsync.when(
          data: (agencies) => DropdownButtonFormField<String>(
            value: _linkedAgencyId,
            decoration: InputDecoration(
              labelText: 'Agence d\'affectation',
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
            onChanged: (v) => setState(() => _linkedAgencyId = v),
          ),
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<entity.MobileOperator>(
                value: _selectedAgentOperator,
                decoration: InputDecoration(
                  labelText: 'Opérateur',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  contentPadding: isKeyboardOpen ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                ),
                items: entity.MobileOperator.values.map((op) {
                  return DropdownMenuItem(value: op, child: Text(op.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedAgentOperator = v);
                },
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
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: ElyfField(
                controller: _liquidityController,
                label: 'Solde SIM Initial',
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
                label: 'Taux Commission',
                hint: '2.5',
                prefixIcon: Icons.percent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: '%',
              ),
            ),
          ],
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
          onChanged: (v) { if (v != null) setState(() => _agentStatus = v); },
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        _buildAttachmentsSection(theme, isKeyboardOpen),
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
                        image: path.startsWith('http') 
                          ? DecorationImage(image: NetworkImage(path), fit: BoxFit.cover)
                          : DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
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
