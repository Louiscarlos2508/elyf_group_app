import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../domain/entities/user.dart';
import 'package:elyf_groupe_app/core.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/admin_module.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import '../../../../domain/entities/enterprise.dart';
import 'widgets/enterprise_selection_widget.dart';

/// Dialogue pour attribuer un utilisateur à une ou plusieurs entreprises avec un module et un rôle.
///
/// Nouvelle version avec support pour attribution multiple d'entreprises.
/// Ordre de sélection : Module → Rôle → Entreprise(s)
class AssignEnterpriseDialog extends ConsumerStatefulWidget {
  const AssignEnterpriseDialog({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AssignEnterpriseDialog> createState() =>
      _AssignEnterpriseDialogState();
}

class _AssignEnterpriseDialogState
    extends ConsumerState<AssignEnterpriseDialog> {
  String? _selectedModuleId;
  String? _selectedRoleId;
  String? _selectedEnterpriseId;
  Set<String> _selectedEnterpriseIds = {};
  bool _isActive = true;
  bool _isLoading = false;
  bool _multipleEnterprisesMode = false;
  bool _includesChildren = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);
    final rolesAsync = ref.watch(rolesProvider);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 100;
    final maxWidth = (screenWidth * 0.9).clamp(320.0, 600.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attribuer une Entreprise',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attribuez ${widget.user.fullName} à une ou plusieurs entreprises',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Sélection du Module
                    DropdownButtonFormField<String>(
                      initialValue: _selectedModuleId,
                      decoration: const InputDecoration(
                        labelText: 'Module *',
                        helperText: 'Sélectionnez d\'abord le module',
                      ),
                      items: AdminModules.all.map((module) {
                        return DropdownMenuItem(
                          value: module.id,
                          child: Text(module.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedModuleId = value;
                          _selectedRoleId = null;
                          _selectedEnterpriseId = null;
                          _selectedEnterpriseIds.clear();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Sélectionnez un module';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sélection du Rôle (si module sélectionné)
                    if (_selectedModuleId != null)
                      rolesAsync.when(
                        data: (allRoles) {
                          // Filtrer les rôles pour ne garder que ceux avec permissions du module
                          final filteredRoles = _filterRolesForModule(
                            allRoles,
                            _selectedModuleId!,
                          );

                          if (filteredRoles.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Aucun rôle disponible pour ce module',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // Trier les rôles par nom
                          filteredRoles.sort(
                            (a, b) => a.name.compareTo(b.name),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${filteredRoles.length} rôle${filteredRoles.length > 1 ? 's' : ''} disponible${filteredRoles.length > 1 ? 's' : ''} pour ce module',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedRoleId,
                                decoration: const InputDecoration(
                                  labelText: 'Rôle *',
                                  helperText:
                                      'Seuls les rôles avec permissions pour ce module sont affichés',
                                ),
                                items: filteredRoles.map((role) {
                                  return DropdownMenuItem(
                                    value: role.id,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(role.name),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${role.permissions.length} permission${role.permissions.length > 1 ? 's' : ''}',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  if (role
                                                      .allowedEnterpriseTypes
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .colorScheme
                                                            .primaryContainer,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        role.getAllowedTypesLabel(),
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                              fontSize: 10,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRoleId = value;
                                    _selectedEnterpriseId = null;
                                    _selectedEnterpriseIds.clear();
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Sélectionnez un rôle';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                      ),
                    const SizedBox(height: 16),

                    // Option mode multiple (si module et rôle sélectionnés)
                    if (_selectedModuleId != null && _selectedRoleId != null)
                      enterprisesAsync.when(
                        data: (enterprises) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'Attribuer à plusieurs entreprises',
                                ),
                                subtitle: const Text(
                                  'Permet de sélectionner plusieurs entreprises en une fois',
                                ),
                                value: _multipleEnterprisesMode,
                                onChanged: (value) {
                                  setState(() {
                                    _multipleEnterprisesMode = value;
                                    _selectedEnterpriseId = null;
                                    _selectedEnterpriseIds.clear();
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Sélection d'entreprise(s)
                              if (_multipleEnterprisesMode)
                                MultipleEnterpriseSelection(
                                  enterprises: enterprises,
                                  selectedEnterpriseIds: _selectedEnterpriseIds,
                                  onChanged: (ids) {
                                    setState(() {
                                      _selectedEnterpriseIds = ids;
                                    });
                                  },
                                  moduleId: _selectedModuleId!,
                                )
                              else
                                SingleEnterpriseSelection(
                                  enterprises: enterprises,
                                  selectedEnterpriseId: _selectedEnterpriseId,
                                  onChanged: (id) {
                                    setState(() {
                                      _selectedEnterpriseId = id;
                                    });
                                  },
                                  moduleId: _selectedModuleId!,
                                ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                      ),

                    // Checkbox pour inclure les enfants (si entreprise sélectionnée en mode simple)
                    if (!_multipleEnterprisesMode &&
                        _selectedEnterpriseId != null)
                      enterprisesAsync.when(
                        data: (enterprises) {
                          final selectedEnterprise = enterprises.firstWhere(
                            (e) => e.id == _selectedEnterpriseId,
                            orElse: () => enterprises.first,
                          );

                          // Compter les enfants
                          final childCount = enterprises
                              .where(
                                (e) =>
                                    e.parentEnterpriseId ==
                                    selectedEnterprise.id,
                              )
                              .length;

                          if (childCount == 0) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text(
                                  'Inclure les sites rattachés',
                                ),
                                subtitle: Text(
                                  '$childCount site${childCount > 1 ? 's' : ''} rattaché${childCount > 1 ? 's' : ''} à cette entreprise',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: _includesChildren,
                                onChanged: (value) {
                                  setState(
                                    () => _includesChildren = value ?? false,
                                  );
                                },
                                secondary: Icon(
                                  Icons.account_tree,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Accès actif'),
                      subtitle: const Text(
                        'Désactivez pour retirer temporairement l\'accès',
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  IntrinsicWidth(
                    child: FilledButton(
                      onPressed:
                          (_isLoading ||
                              _selectedModuleId == null ||
                              _selectedRoleId == null ||
                              (_multipleEnterprisesMode
                                  ? _selectedEnterpriseIds.isEmpty
                                  : _selectedEnterpriseId == null))
                          ? null
                          : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _multipleEnterprisesMode
                                  ? 'Attribuer (${_selectedEnterpriseIds.length})'
                                  : 'Attribuer',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedModuleId == null ||
        _selectedRoleId == null ||
        (_multipleEnterprisesMode
            ? _selectedEnterpriseIds.isEmpty
            : _selectedEnterpriseId == null)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_multipleEnterprisesMode) {
        // Mode batch : attribuer à plusieurs entreprises
        await ref
            .read(adminControllerProvider)
            .batchAssignUserToEnterprises(
              userId: widget.user.id,
              enterpriseIds: _selectedEnterpriseIds.toList(),
              moduleId: _selectedModuleId!,
              roleIds: [_selectedRoleId!],
              isActive: _isActive,
            );

        if (mounted) {
          Navigator.of(context).pop(true);
          NotificationService.showInfo(
            context,
            'Utilisateur attribué à ${_selectedEnterpriseIds.length} entreprise(s) avec succès',
          );
        }
      } else {
        // Mode classique : attribuer à une seule entreprise
        final enterpriseModuleUser = EnterpriseModuleUser(
          userId: widget.user.id,
          enterpriseId: _selectedEnterpriseId!,
          moduleId: _selectedModuleId!,
          roleIds: [_selectedRoleId!],
          isActive: _isActive,
          includesChildren: _includesChildren,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref
            .read(adminControllerProvider)
            .assignUserToEnterprise(enterpriseModuleUser);

        if (mounted) {
          Navigator.of(context).pop(enterpriseModuleUser);
          NotificationService.showInfo(
            context,
            'Utilisateur attribué avec succès',
          );
        }
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

  /// Filtre les rôles pour ne garder que ceux qui ont des permissions
  /// pour le module spécifié ET qui sont compatibles avec le type d'entreprise.
  List<UserRole> _filterRolesForModule(
    List<UserRole> allRoles,
    String moduleId,
  ) {
    final registry = PermissionRegistry.instance;
    final modulePermissions = registry.getModulePermissions(moduleId);

    // Récupérer l'entreprise sélectionnée pour filtrer par type
    final enterprisesAsync = ref.read(enterprisesProvider);
    Enterprise? selectedEnterprise;

    if (_selectedEnterpriseId != null) {
      selectedEnterprise = enterprisesAsync.maybeWhen(
        data: (enterprises) => enterprises.firstWhere(
          (e) => e.id == _selectedEnterpriseId,
          orElse: () => enterprises.first,
        ),
        orElse: () => null,
      );
    }

    if (modulePermissions == null || modulePermissions.isEmpty) {
      // Si aucune permission enregistrée pour ce module, filtrer uniquement par type d'entreprise
      if (selectedEnterprise != null) {
        return allRoles
            .where((role) => role.canBeAssignedTo(selectedEnterprise!.type))
            .toList();
      }
      return allRoles;
    }

    final modulePermissionIds = modulePermissions.keys.toSet();

    return allRoles.where((role) {
      // Vérifier que le rôle a au moins une permission du module
      final hasModulePermission = role.permissions.any(
        (permissionId) => modulePermissionIds.contains(permissionId),
      );

      if (!hasModulePermission) return false;

      // Si une entreprise est sélectionnée, vérifier la compatibilité du type
      if (selectedEnterprise != null) {
        return role.canBeAssignedTo(selectedEnterprise.type);
      }

      return true;
    }).toList();
  }
}
