import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../domain/entities/enterprise.dart';
import '../../../../application/providers.dart';

/// Un wizard multi-étapes pour créer une entreprise avec respect des contraintes hiérarchiques.
class CreateEnterpriseWizard extends ConsumerStatefulWidget {
  const CreateEnterpriseWizard({super.key});

  @override
  ConsumerState<CreateEnterpriseWizard> createState() => _CreateEnterpriseWizardState();
}

class _CreateEnterpriseWizardState extends ConsumerState<CreateEnterpriseWizard> with FormHelperMixin {
  final _pageController = PageController();
  int _currentStep = 0;

  // Form keys
  final _formKeyDetails = GlobalKey<FormState>();

  // State
  EnterpriseModule? _selectedModule;
  EnterpriseType? _selectedType;
  Enterprise? _selectedParent;
  bool _isActive = true;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _handleSubmit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKeyDetails.currentState!.validate()) return;

    await handleFormSubmit(
      context: context,
      formKey: _formKeyDetails,
      onLoadingChanged: (loading) => setState(() => _isLoading = loading),
      onSubmit: () async {
        if (_selectedType == null) return 'Veuillez sélectionner un type';

        final enterprise = Enterprise(
          id: '${_selectedType!.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          type: _selectedType!,
          parentEnterpriseId: _selectedParent?.id,
          hierarchyLevel: _selectedParent != null ? _selectedParent!.hierarchyLevel + 1 : 1,
          moduleId: _selectedModule?.id,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty 
              ? null 
              : (PhoneUtils.normalizeBurkina(_phoneController.text.trim()) ?? _phoneController.text.trim()),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          isActive: _isActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          Navigator.of(context).pop(enterprise);
        }
        return 'Entreprise créée avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                _buildHeader(theme, isMobile),
                _buildStepperProgress(theme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildModuleSelectionStep(theme),
                      _buildHierarchyStep(theme),
                      _buildDetailsStep(theme),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildFooter(theme, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_business, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Nouvelle Entreprise',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperProgress(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Module'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Type'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Détails'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int index, String label) {
    final theme = Theme.of(context);
    final isActive = _currentStep >= index;
    final isSelected = _currentStep == index;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (isActive ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHighest),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int index) {
    final theme = Theme.of(context);
    final isActive = _currentStep > index;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildModuleSelectionStep(ThemeData theme) {
    // Exclure le module "group" car ce n'est pas un module métier
    final modules = EnterpriseModule.values
        .where((m) => m != EnterpriseModule.group)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sélectionnez le module concerné', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final isSelected = _selectedModule == module;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedModule = module;
                    _selectedType = null;
                    _selectedParent = null;
                    // Auto-select type if only one option or is main
                    final mainType = EnterpriseType.values.firstWhere(
                      (t) => t.module == module && t.isMain,
                      orElse: () => EnterpriseType.values.firstWhere((t) => t.module == module),
                    );
                    _selectedType = mainType;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getModuleIcon(module),
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        module.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyStep(ThemeData theme) {
    if (_selectedModule == null) return const Center(child: Text('Sélectionnez d\'abord un module'));

    final supportsHierarchy = _selectedModule!.supportsHierarchy;
    final types = EnterpriseType.values.where((t) => t.module == _selectedModule).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nature de l\'entité', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (supportsHierarchy) ...[
            _buildTypeOption(
              theme,
              title: 'Entité Principale',
              subtitle: 'Structure mère qui peut avoir des sous-entités',
              isSelected: _selectedType?.isMain ?? false,
              onTap: () {
                setState(() {
                  _selectedType = types.firstWhere((t) => t.isMain);
                  _selectedParent = null;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTypeOption(
              theme,
              title: 'Sous-entité / Point de vente',
              subtitle: 'Entité rattachée à une société mère',
              isSelected: !(_selectedType?.isMain ?? true),
              onTap: () {
                setState(() {
                  _selectedType = types.firstWhere((t) => !t.isMain, orElse: () => types.first);
                });
              },
            ),
            if (!(_selectedType?.isMain ?? true)) ...[
              const SizedBox(height: 24),
              Text('Rattachement', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildParentSelection(theme),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ce module utilise une structure simplifiée. L\'entreprise sera créée directement sous le groupe.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParentSelection(ThemeData theme) {
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return enterprisesAsync.when(
      data: (enterprises) {
        // Filtrer les entreprises qui peuvent être parents :
        // - Même module que celui sélectionné
        // - Supportent la hiérarchie (isMain et module supporte hiérarchie)
        final possibleParents = enterprises.where((e) {
          return e.type.module == _selectedModule && e.supportsHierarchy;
        }).toList();

        if (possibleParents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Aucune société mère disponible pour ce module. Créez-en une d\'abord.'),
          );
        }

        return DropdownButtonFormField<Enterprise>(
          initialValue: _selectedParent,
          decoration: const InputDecoration(labelText: 'Société mère *', border: OutlineInputBorder()),
          items: possibleParents.map((e) {
            return DropdownMenuItem(value: e, child: Text(e.name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedParent = val),
          validator: (val) => val == null ? 'Le parent est requis' : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Erreur de chargement des parents'),
    );
  }

  Widget _buildDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyDetails,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de l\'entité *', prefixIcon: Icon(Icons.business_center)),
              validator: (v) => v?.isEmpty ?? true ? 'Le nom est requis' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone), hintText: '+226 70 00 00 00'),
              keyboardType: TextInputType.phone,
              validator: (v) => v != null && v.isNotEmpty ? Validators.phoneBurkina(v) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Actif'),
              subtitle: const Text('L\'entité sera immédiatement opérationnelle'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(ThemeData theme, {required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _isLoading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
            ),
          const Spacer(),
          if (_currentStep == 0)
            FilledButton(
              onPressed: _selectedModule == null ? null : _nextStep,
              child: const Text('Continuer'),
            )
          else if (_currentStep == 1)
            FilledButton(
              onPressed: (_selectedType == null || (!(_selectedType?.isMain ?? true) && _selectedParent == null)) ? null : _nextStep,
              child: const Text('Suivant'),
            )
          else
            FilledButton.icon(
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
              label: const Text('Créer l\'entreprise'),
            ),
        ],
      ),
    );
  }

  IconData _getModuleIcon(EnterpriseModule module) {
    switch (module) {
      case EnterpriseModule.group: return Icons.corporate_fare;
      case EnterpriseModule.gaz: return Icons.local_fire_department;
      case EnterpriseModule.eau: return Icons.water_drop;
      case EnterpriseModule.immobilier: return Icons.home_work;
      case EnterpriseModule.boutique: return Icons.storefront;
      case EnterpriseModule.mobileMoney: return Icons.account_balance_wallet;
    }
  }
}
