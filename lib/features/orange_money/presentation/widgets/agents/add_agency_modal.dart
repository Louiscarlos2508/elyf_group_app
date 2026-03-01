import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/orange_money_enterprise_extensions.dart';
import '../../../../administration/domain/entities/enterprise.dart';
import '../../../../administration/domain/entities/user.dart';
import '../../../application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_field.dart';
import 'package:elyf_groupe_app/features/orange_money/application/controllers/agents_controller.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class AddAgencyModal extends ConsumerStatefulWidget {
  const AddAgencyModal({
    super.key,
    this.agency,
    this.isReadOnly = false,
  });

  final Enterprise? agency;
  final bool isReadOnly;

  @override
  ConsumerState<AddAgencyModal> createState() => _AddAgencyModalState();
}

class _AddAgencyModalState extends ConsumerState<AddAgencyModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _liquidityController;
  late TextEditingController _notesController;
  late TextEditingController _managerController;

  // State
  EnterpriseType _selectedAgencyType = EnterpriseType.mobileMoneySubAgent;
  bool _isActiveAgency = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.agency != null) {
      _initAgencyFields(widget.agency!);
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _liquidityController = TextEditingController(text: '0');
      _notesController = TextEditingController();
      _managerController = TextEditingController();
    }
  }

  void _initAgencyFields(Enterprise agency) {
    _nameController = TextEditingController(text: agency.name);
    _phoneController = TextEditingController(text: agency.phone);
    _liquidityController = TextEditingController(text: agency.floatBalance?.toString() ?? '0');
    _notesController = TextEditingController(text: agency.description);
    _managerController = TextEditingController(text: agency.manager);
    _selectedAgencyType = agency.type;
    _isActiveAgency = agency.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _liquidityController.dispose();
    _notesController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(agentsControllerProvider);
      final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
      
      final agency = (widget.agency ?? Enterprise(
        id: '',
        name: _nameController.text.trim(),
        type: _selectedAgencyType,
        moduleId: 'orange_money',
        parentEnterpriseId: activeEnterpriseId, // Set parent ID
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
        manager: _managerController.text.trim().isEmpty ? null : _managerController.text.trim(),
      );

      if (widget.agency == null) {
        await controller.createAgency(agency);
        if (mounted) NotificationService.showSuccess(context, 'Agence créée avec succès');
      } else {
        await controller.updateAgency(agency);
        if (mounted) NotificationService.showSuccess(context, 'Agence modifiée avec succès');
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
    final isEditing = widget.agency != null;
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
            ? 'Détails Agence / PDV'
            : (isEditing ? 'Modifier Agence / PDV' : 'Nouvelle Agence / PDV'),
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
              _buildAgencyForm(theme, isKeyboardOpen),
              if (widget.isReadOnly && widget.agency != null) ...[
                const SizedBox(height: 32),
                _buildAssignedUsersSection(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyForm(ThemeData theme, bool isKeyboardOpen) {
    return Column(
      children: [
        _buildSectionHeader('Informations Génerales Agence'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        ElyfField(
          label: 'Type d\'agence',
          initialValue: 'Sous Agence',
          readOnly: true,
          prefixIcon: Icons.business,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _nameController,
          label: 'Nom de l\'agence / Boutique',
          hint: 'ex: Agence Centre-Ville',
          prefixIcon: Icons.store_mall_directory_outlined,
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _phoneController,
          label: 'Téléphone agence',
          hint: 'ex: 70000000',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _managerController,
          label: 'Nom du Gérant / Responsable',
          hint: 'ex: Carlos Simporé',
          prefixIcon: Icons.person_outline,
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        ElyfField(
          controller: _liquidityController,
          label: 'Solde Cash Initial',
          hint: '0',
          prefixIcon: Icons.money_outlined,
          keyboardType: TextInputType.number,
          suffixText: 'FCFA',
          readOnly: widget.isReadOnly,
        ),
        SizedBox(height: isKeyboardOpen ? 16 : 32),
        _buildSectionHeader('État & Localisation'),
        SizedBox(height: isKeyboardOpen ? 8 : 16),
        SwitchListTile(
          title: const Text('Agence Active'),
          subtitle: const Text('Désactivez pour masquer des opérations'),
          value: _isActiveAgency,
          onChanged: widget.isReadOnly ? null : (v) => setState(() => _isActiveAgency = v)
        ),
        ElyfField(
          controller: _notesController,
          label: 'Adresse / Localisation',
          hint: 'ex: Situé près du grand marché...',
          maxLines: isKeyboardOpen ? 1 : 3,
          prefixIcon: Icons.location_on_outlined,
          readOnly: widget.isReadOnly,
        ),
      ],
    );
  }

  Widget _buildAssignedUsersSection(ThemeData theme) {
    final assignmentsAsync = ref.watch(enterpriseModuleUsersProvider);
    final usersAsync = ref.watch(usersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Utilisateurs Assignés'),
        const SizedBox(height: 16),
        assignmentsAsync.when(
          data: (assignments) {
            final agencyAssignments = assignments.where((a) {
              final isDirect = a.enterpriseId == widget.agency!.id;
              // Some systems use different prefixes (e.g. agence_orange_money_xxx vs xxx)
              final isFuzzyMatch = a.enterpriseId.contains(widget.agency!.id) || 
                                 widget.agency!.id.contains(a.enterpriseId);
              final isInherited = widget.agency!.ancestorIds.contains(a.enterpriseId) && a.includesChildren;
              
              // We keep it broad to see what's happening
              return (isDirect || isFuzzyMatch || isInherited) && a.isActive;
            }).toList();
            if (agencyAssignments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucun utilisateur assigné à cette agence'),
              );
            }

            return usersAsync.when(
              data: (users) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: agencyAssignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final assignment = agencyAssignments[index];
                    final user = users.firstWhere((u) => u.id == assignment.userId, 
                                               orElse: () => User(id: assignment.userId, firstName: 'Utilisateur', lastName: 'Inconnu', username: 'inconnu', email: '', enterpriseIds: []));
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.roleIds.map((r) => r.replaceAll('_', ' ').split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ')).join(', '),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (assignment.moduleId != 'orange_money')
                            Text(
                              'Module: ${assignment.moduleId}',
                              style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: assignment.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          assignment.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: assignment.isActive ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Erreur chargement utilisateurs: $e'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Text('Erreur chargement assignations: $e'),
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
}
