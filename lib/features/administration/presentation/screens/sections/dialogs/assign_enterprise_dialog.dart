import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart'; // Added core.dart import
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../domain/entities/user.dart';
import '../../../../application/providers.dart';
import 'widgets/module_selection_widget.dart';
import 'widgets/multiple_module_enterprise_selection_widget.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/auth/providers.dart';

/// Dialogue pour attribuer un utilisateur à une ou plusieurs entreprises.
///
/// Règle métier : 1 rôle = 1 module.
/// Ordre de sélection : Module(s) → Rôle par module → Entreprise(s)
class AssignEnterpriseDialog extends ConsumerStatefulWidget {
  const AssignEnterpriseDialog({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AssignEnterpriseDialog> createState() =>
      _AssignEnterpriseDialogState();
}

class _AssignEnterpriseDialogState
    extends ConsumerState<AssignEnterpriseDialog> {
  /// Un rôle par module : moduleId → roleId
  final Map<String, String> _selectedRolePerModule = {};
  Set<String> _selectedModuleIds = {};
  Set<String> _selectedEnterpriseIds = {};
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingInitialData = true;

  // Pour le tracking des suppressions: snapshot de l'état initial
  // Map<ModuleId, Set<EnterpriseId>>
  final Map<String, Set<String>> _initialAssignments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingAssignments();
    });
  }

  Future<void> _loadExistingAssignments() async {
    if (!mounted) return;
    setState(() => _isLoadingInitialData = true);

    try {
      final controller = ref.read(userAssignmentControllerProvider);
      final assignments = await controller.getUserEnterpriseModuleUsers(widget.user.id);

      if (assignments.isNotEmpty) {
        final moduleIds = <String>{};
        final enterpriseIds = <String>{};
        final rolePerModule = <String, String>{};
        final initialMap = <String, Set<String>>{};

        for (final assignment in assignments) {
          moduleIds.add(assignment.moduleId);
          enterpriseIds.add(assignment.enterpriseId);
          
          // Note: Si l'utilisateur a des rôles différents pour le même module sur différentes entreprises,
          // le dernier gagne. C'est une simplification acceptable pour cette vue "globale".
          // L'utilisateur verra ce rôle et s'il sauvegarde, cela uniformisera le rôle pour ce module.
          if (assignment.roleIds.isNotEmpty) {
            rolePerModule[assignment.moduleId] = assignment.roleIds.first;
          }

          // Construire l'état initial pour la détection des suppressions
          if (!initialMap.containsKey(assignment.moduleId)) {
            initialMap[assignment.moduleId] = {};
          }
          initialMap[assignment.moduleId]!.add(assignment.enterpriseId);
        }

        setState(() {
          _selectedModuleIds = moduleIds;
          _selectedEnterpriseIds = enterpriseIds;
          _selectedRolePerModule.addAll(rolePerModule);
          _initialAssignments.addAll(initialMap);
          // Si au moins une est inactive, on met le switch à off (simplification)
          _isActive = assignments.every((a) => a.isActive); 
        });
      }
    } catch (e) {
      AppLogger.error('Error loading existing assignments', error: e);
      if (mounted) {
        NotificationService.showError(context, 'Erreur de chargement des accès existants');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
      }
    }
  }

  /// Tous les modules sélectionnés ont un rôle assigné
  bool get _allModulesHaveRole =>
      _selectedModuleIds.isNotEmpty &&
      _selectedModuleIds.every((m) => _selectedRolePerModule.containsKey(m));

  /// Collecte tous les roleIds sélectionnés (1 par module)
  List<String> get _allSelectedRoleIds =>
      _selectedRolePerModule.values.toSet().toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitialData) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des accès...'),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enterprisesAsync = ref.watch(enterprisesProvider);
    final rolesAsync = ref.watch(rolesProvider);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 100;
    final maxWidth = (screenWidth * 0.9).clamp(320.0, 700.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: availableHeight.clamp(400.0, screenHeight * 0.9),
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey[900] : Colors.white)!
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    border: Border(
                      bottom: BorderSide(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.link_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gérer les accès',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Modifiez les accès pour ${widget.user.fullName}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Étape 1 : Sélection des modules ──────────────
                        MultipleModuleSelection(
                          selectedModuleIds: _selectedModuleIds,
                          onChanged: (moduleIds) {
                            setState(() {
                              // Retirer les rôles des modules désélectionnés
                              _selectedRolePerModule.removeWhere(
                                (k, _) => !moduleIds.contains(k),
                              );
                              _selectedModuleIds = moduleIds;
                              // On ne vide plus les entreprises, l'utilisateur gère sa sélection
                            });
                          },
                        ),

                        // ── Étape 2 : Rôle par module ────────────────────
                        if (_selectedModuleIds.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildRoleSelectionHeader(theme),
                          const SizedBox(height: 16),
                          rolesAsync.when(
                            data: (allRoles) => Column(
                              children: _selectedModuleIds.map((moduleId) {
                                return _buildModuleRoleSection(
                                  theme: theme,
                                  moduleId: moduleId,
                                  allRoles: allRoles,
                                );
                              }).toList(),
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) =>
                                Text('Erreur chargement rôles: $e'),
                          ),
                        ],

                        // ── Étape 3 : Entreprises ────────────────────────
                        if (_allModulesHaveRole) ...[
                          const SizedBox(height: 32),
                          rolesAsync.when(
                            data: (allRoles) {
                              final selectedRoleObjects = allRoles
                                  .where((r) =>
                                      _allSelectedRoleIds.contains(r.id))
                                  .toList();

                              return enterprisesAsync.when(
                                data: (enterprises) =>
                                    MultipleModuleEnterpriseSelection(
                                  enterprises: enterprises,
                                  selectedEnterpriseIds: _selectedEnterpriseIds,
                                  onChanged: (ids) {
                                    setState(() => _selectedEnterpriseIds = ids);
                                  },
                                  moduleIds: _selectedModuleIds,
                                  selectedRoles: selectedRoleObjects,
                                ),
                                loading: () =>
                                    const LinearProgressIndicator(),
                                error: (e, _) =>
                                    Text('Erreur chargement entreprises: $e'),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Erreur: $e'),
                          ),
                        ],

                        // ── Accès actif ──────────────────────────────────
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(
                              'Accès actif',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Désactivez pour suspendre temporairement l\'accès',
                            ),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                            activeThumbColor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: FilledButton(
                          onPressed: (_isLoading ||
                                  !_allModulesHaveRole ||
                                  _selectedEnterpriseIds.isEmpty)
                              ? null
                              : _handleSubmit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.save_outlined,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Enregistrer',
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// En-tête de la section rôles
  Widget _buildRoleSelectionHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.security,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rôles par module',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Sélectionnez exactement 1 rôle par module',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section rôles pour un module donné
  Widget _buildModuleRoleSection({
    required ThemeData theme,
    required String moduleId,
    required List<UserRole> allRoles,
  }) {
    // Filtrer strictement les rôles de ce module uniquement
    final moduleRoles =
        allRoles.where((r) => r.moduleId == moduleId).toList();
    final selectedRoleId = _selectedRolePerModule[moduleId];
    final moduleName = _getModuleName(moduleId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedRoleId != null
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: selectedRoleId != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du module
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedRoleId != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  moduleName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selectedRoleId != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (selectedRoleId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Rôle sélectionné',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Requis',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des rôles du module
          if (moduleRoles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun rôle pour "$moduleName". Créez-en un dans l\'onglet Rôles.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moduleRoles.map<Widget>((role) {
                  final isSelected = selectedRoleId == role.id;
                  return ChoiceChip(
                    label: Text(role.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (isSelected) {
                          // Désélectionner
                          _selectedRolePerModule.remove(moduleId);
                        } else {
                          // Sélectionner ce rôle (remplace l'ancien)
                          _selectedRolePerModule[moduleId] = role.id;
                        }
                        // On ne vide PAS les entreprises ici lors du changement de rôle
                        // pour ne pas forcer l'utilisateur à resélectionner
                        // _selectedEnterpriseIds.clear(); 
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                    backgroundColor:
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _getModuleName(String moduleId) {
    const names = {
      'eau_minerale': 'Eau Minérale',
      'gaz': 'Gaz',
      'orange_money': 'Orange Money',
      'immobilier': 'Immobilier',
      'boutique': 'Boutique',
      'administration': 'Administration',
    };
    return names[moduleId] ?? moduleId;
  }

  Future<void> _handleSubmit() async {
    if (!_allModulesHaveRole || _selectedEnterpriseIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(adminControllerProvider);
      final userId = widget.user.id;
      final currentUserId = ref.read(currentUserIdProvider);

      // 1. Gérer les suppressions (Accès révoqués)
      // Pour chaque module initialement présent...
      for (final moduleId in _initialAssignments.keys) {
        final initialEnterprises = _initialAssignments[moduleId]!;
        
        // Si le module a été complètement désélectionné
        if (!_selectedModuleIds.contains(moduleId)) {
            // Supprimer tous les accès pour ce module
            for (final entId in initialEnterprises) {
               await controller.removeUserFromEnterprise(
                  userId, 
                  entId, 
                  moduleId,
                  currentUserId: currentUserId
               );
            }
        } else {
            // Le module est toujours sélectionné, vérifier les entreprises désélectionnées
            for (final entId in initialEnterprises) {
                if (!_selectedEnterpriseIds.contains(entId)) {
                   await controller.removeUserFromEnterprise(
                      userId, 
                      entId, 
                      moduleId,
                      currentUserId: currentUserId
                   );
                }
            }
        }
      }

      // 2. Gérer les ajouts et mises à jour (Upsert)
      // Convertir la map simple (moduleId -> roleId) en map pour le controller (moduleId -> [roleId])
      final roleIdsByModule = _selectedRolePerModule.map(
        (key, value) => MapEntry(key, [value]),
      );

      await controller.batchAssignUserToModulesAndEnterprises(
            userId: userId,
            moduleIds: _selectedModuleIds.toList(),
            enterpriseIds: _selectedEnterpriseIds.toList(),
            roleIdsByModule: roleIdsByModule,
            isActive: _isActive,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        NotificationService.showInfo(
          context,
          'Accès mis à jour avec succès',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
