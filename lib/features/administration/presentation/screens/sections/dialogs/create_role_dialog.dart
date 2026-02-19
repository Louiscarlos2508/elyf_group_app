import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../core/errors/app_exceptions.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart'
    show currentUserIdProvider;
import '../../../../domain/services/permission_section_mapper.dart';
import '../../../../domain/entities/module_sections_info.dart';
import '../../../../domain/entities/enterprise.dart';

/// Dialogue pour créer un nouveau rôle.
class CreateRoleDialog extends ConsumerStatefulWidget {
  const CreateRoleDialog({super.key, this.moduleId});

  final String? moduleId;

  @override
  ConsumerState<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends ConsumerState<CreateRoleDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final Set<String> _selectedPermissions = {};
  Set<EnterpriseType> _selectedEnterpriseTypes = {};
  String _enterpriseLevelMode = 'all'; // 'company', 'pos', 'all'
  String? _selectedModuleId;
  bool _showTemplates = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedModuleId = widget.moduleId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(UserRole template) {
    setState(() {
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedModuleId = template.moduleId;
      _selectedPermissions.clear();
      _selectedPermissions.addAll(template.permissions);
      _selectedEnterpriseTypes = Set.from(template.allowedEnterpriseTypes);
      
      // Déterminer le mode à partir des types d'entreprises
      if (template.allowedEnterpriseTypes.isEmpty) {
        _enterpriseLevelMode = 'all';
      } else if (template.allowedEnterpriseTypes.every((type) => 
          type == EnterpriseType.gasPointOfSale || 
          type == EnterpriseType.waterPointOfSale || 
          type == EnterpriseType.waterFactory)) {
        _enterpriseLevelMode = 'pos';
      } else {
        _enterpriseLevelMode = 'company';
      }
      
      _showTemplates = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedPermissions.isEmpty) {
      NotificationService.showInfo(
        context,
        'Sélectionnez au moins une permission',
      );
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final role = UserRole(
          id: 'role_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          permissions: _selectedPermissions,
          moduleId: _selectedModuleId ?? 'administration',
          isSystemRole: false,
          allowedEnterpriseTypes: _selectedEnterpriseTypes,
        );

        // Récupérer l'ID de l'utilisateur actuel pour l'audit trail
        final currentUserId = ref.read(currentUserIdProvider);

        if (currentUserId == null) {
          throw AuthenticationException(
            'Aucun utilisateur connecté. Veuillez vous reconnecter.',
            'USER_NOT_AUTHENTICATED',
          );
        }

        await ref
            .read(adminControllerProvider)
            .createRole(role, currentUserId: currentUserId);

        if (mounted) {
          Navigator.of(context).pop(role);
        }

        return 'Rôle créé avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(rolesProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 100;
    final maxWidth = (screenWidth * 0.9).clamp(320.0, 700.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showTemplates ? 'Choisir un modèle' : 'Nouveau Rôle',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _showTemplates 
                              ? 'Utilisez un rôle prédéfini comme point de départ' 
                              : 'Personnalisez votre nouveau rôle',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_showTemplates)
                      IconButton(
                        onPressed: () => setState(() => _showTemplates = true),
                        icon: const Icon(Icons.auto_awesome_motion_outlined),
                        tooltip: 'Changer de modèle',
                      ),
                  ],
                ),
              ),
              if (_showTemplates)
                Expanded(
                  child: _buildTemplateGallery(theme),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration(
                            theme, 
                            'Nom du rôle *', 
                            'ex: Gestionnaire', 
                            Icons.badge_outlined
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
                          controller: _descriptionController,
                          decoration: _buildInputDecoration(
                            theme, 
                            'Description *', 
                            'Une brève description des responsabilités', 
                            Icons.description_outlined
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est requise';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Sélection du module (si pas déjà fourni)
                         if (widget.moduleId == null)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedModuleId,
                            decoration: _buildInputDecoration(
                              theme, 
                              'Module *', 
                              'Sélectionnez le module du rôle', 
                              Icons.category_outlined
                            ),
                            items: PermissionRegistry.instance.registeredModules.map((id) {
                              return DropdownMenuItem(
                                value: id,
                                child: Text(_getModuleName(id)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedModuleId = value;
                                // Effacer les permissions si le module change
                                _selectedPermissions.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Le module est requis';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 24),

                      // Section Niveau d'Entreprise
                      Text(
                        '🏢 Niveau d\'Entreprise',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Définissez à quels types d\'entreprises ce rôle peut être assigné',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options de niveau
                      _buildEnterpriseLevelOption(
                        theme: theme,
                        value: 'company',
                        title: 'Société / Groupe',
                        description:
                            'Stats consolidées, gestion globale (tours, logistique)',
                        icon: Icons.business,
                        isSelected: _enterpriseLevelMode == 'company',
                        onTap: () {
                          setState(() {
                            _enterpriseLevelMode = 'company';
                            _updateEnterpriseTypesFromMode();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildEnterpriseLevelOption(
                        theme: theme,
                        value: 'pos',
                        title: 'Point de Vente / Local',
                        description:
                            'Gestion opérationnelle locale (ventes, stock, dépenses)',
                        icon: Icons.store,
                        isSelected: _enterpriseLevelMode == 'pos',
                        onTap: () {
                          setState(() {
                            _enterpriseLevelMode = 'pos';
                            _updateEnterpriseTypesFromMode();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildEnterpriseLevelOption(
                        theme: theme,
                        value: 'all',
                        title: 'Tous niveaux (flexible)',
                        description:
                            'Peut être assigné à n\'importe quel type d\'entreprise',
                        icon: Icons.all_inclusive,
                        isSelected: _enterpriseLevelMode == 'all',
                        onTap: () {
                          setState(() {
                            _enterpriseLevelMode = 'all';
                            _selectedEnterpriseTypes = {};
                          });
                        },
                      ),

                      const SizedBox(height: 24),
                      Text(
                        '🔐 Permissions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_enterpriseLevelMode != 'all')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getPermissionSuggestion(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          // Si aucun module n'est sélectionné, afficher un message d'invite
                          if (_selectedModuleId == null && widget.moduleId == null) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sélectionnez d\'abord un module pour voir les permissions disponibles',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Récupérer toutes les permissions enregistrées depuis PermissionRegistry
                          final registry = PermissionRegistry.instance;
                          final allPermissionsMap = <String, String>{};
                          final permissionsByModuleList =
                              <String, List<ModulePermission>>{};

                          // Parcourir uniquement le module sélectionné (ou tous si non encore sélectionné)
                          final modulesToIterate = _selectedModuleId != null 
                              ? [ _selectedModuleId! ] 
                              : (widget.moduleId != null ? [widget.moduleId!] : registry.registeredModules);

                          for (final moduleId in modulesToIterate) {
                            final modulePermissions = registry
                                .getModulePermissions(moduleId);
                            if (modulePermissions != null) {
                              final modulePerms = <ModulePermission>[];
                              for (final permission
                                  in modulePermissions.values) {
                                allPermissionsMap[permission.id] =
                                    permission.name;
                                modulePerms.add(permission);
                              }
                              if (modulePerms.isNotEmpty) {
                                permissionsByModuleList[moduleId] = modulePerms;
                              }
                            }
                          }

                          // Organiser les permissions par module et section
                          final organizedPermissions =
                              PermissionSectionMapper.organizeAllPermissions(
                                permissionsByModule: permissionsByModuleList,
                              );

                          // Si aucune permission n'est enregistrée pour ce module dans le registry
                          if (allPermissionsMap.isEmpty && _selectedModuleId != null) {
                            return rolesAsync.when(
                              data: (roles) {
                                // Filtrer uniquement les permissions existantes pour ce module précis
                                final modulePermissions = <String>{};
                                for (final role in roles) {
                                  if (role.moduleId == _selectedModuleId) {
                                    modulePermissions.addAll(role.permissions);
                                  }
                                }

                                if (modulePermissions.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 48,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Aucune permission trouvée pour ce module',
                                          style: theme.textTheme.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final sortedPermissions =
                                    modulePermissions.toList()..sort();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Note: Ce module n\'est pas dans le registre. Seules les permissions déjà attribuées à d\'autres rôles du même module sont affichées.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            title: const Text(
                                              'Toutes les permissions',
                                            ),
                                            value:
                                                _selectedPermissions.length ==
                                                sortedPermissions.length && _selectedPermissions.isNotEmpty,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedPermissions.addAll(
                                                    sortedPermissions,
                                                  );
                                                } else {
                                                  _selectedPermissions.clear();
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    ...sortedPermissions.map((permission) {
                                      final name = registry.getPermissionName(permission) ?? permission;
                                      return CheckboxListTile(
                                        title: Text(name),
                                        subtitle: Text(permission, style: theme.textTheme.bodySmall),
                                        value: _selectedPermissions.contains(
                                          permission,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedPermissions.add(
                                                permission,
                                              );
                                            } else {
                                              _selectedPermissions.remove(
                                                permission,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }),
                                  ],
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (error, stack) => Text('Erreur: $error'),
                            );
                          }

                          // Afficher les permissions organisées par module → section → permissions
                          final sortedPermissionIds =
                              allPermissionsMap.keys.toList()..sort();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête avec statistiques
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
                                        '${allPermissionsMap.length} permission${allPermissionsMap.length > 1 ? 's' : ''} disponible${allPermissionsMap.length > 1 ? 's' : ''} (${organizedPermissions.length} module${organizedPermissions.length > 1 ? 's' : ''})',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: CheckboxListTile(
                                      title: const Text(
                                        'Toutes les permissions',
                                      ),
                                      value:
                                          _selectedPermissions.length ==
                                              sortedPermissionIds.length &&
                                          _selectedPermissions.isNotEmpty,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedPermissions.addAll(
                                              sortedPermissionIds,
                                            );
                                          } else {
                                            _selectedPermissions.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              // Afficher les permissions organisées par module → section
                              if (organizedPermissions.length > 1)
                                ...organizedPermissions.map((moduleData) {
                                  final moduleId = moduleData.moduleId;
                                  final sections = moduleData.sections;
                                  final moduleSections =
                                      ModuleSectionsRegistry.getSectionsForModule(
                                        moduleId,
                                      );

                                  final modulePermissionIds = sections.values
                                      .expand((perms) => perms.map((p) => p.id))
                                      .toSet();
                                  final allModuleSelected = modulePermissionIds
                                      .every(
                                        (id) =>
                                            _selectedPermissions.contains(id),
                                      );

                                  return ExpansionTile(
                                    leading: Checkbox(
                                      value:
                                          allModuleSelected &&
                                          modulePermissionIds.isNotEmpty,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedPermissions.addAll(
                                              modulePermissionIds,
                                            );
                                          } else {
                                            _selectedPermissions.removeAll(
                                              modulePermissionIds,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    title: Text(
                                      _getModuleName(moduleId),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    subtitle: Text(
                                      '${sections.values.fold<int>(0, (sum, perms) => sum + perms.length)} permission${sections.values.fold<int>(0, (sum, perms) => sum + perms.length) > 1 ? 's' : ''}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    children: sections.entries.map((
                                      sectionEntry,
                                    ) {
                                      final sectionId = sectionEntry.key;
                                      final sectionPermissions =
                                          sectionEntry.value;
                                      final sectionInfo = moduleSections
                                          .firstWhere(
                                            (s) => s.id == sectionId,
                                            orElse: () => ModuleSection(
                                              id: sectionId,
                                              name: sectionId,
                                              icon: Icons.category_outlined,
                                            ),
                                          );
                                      final sectionPermissionIds =
                                          sectionPermissions
                                              .map((p) => p.id)
                                              .toSet();
                                      final allSectionSelected =
                                          sectionPermissionIds.every(
                                            (id) => _selectedPermissions
                                                .contains(id),
                                          );

                                      return ExpansionTile(
                                        leading: Checkbox(
                                          value:
                                              allSectionSelected &&
                                              sectionPermissionIds.isNotEmpty,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedPermissions.addAll(
                                                  sectionPermissionIds,
                                                );
                                              } else {
                                                _selectedPermissions.removeAll(
                                                  sectionPermissionIds,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              sectionInfo.icon,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sectionInfo.name,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          '${sectionPermissions.length} permission${sectionPermissions.length > 1 ? 's' : ''}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        children: sectionPermissions.map((
                                          permission,
                                        ) {
                                          return CheckboxListTile(
                                            title: Text(permission.name),
                                            // Subtitle removed to hide technical English IDs
                                            value: _selectedPermissions
                                                .contains(permission.id),
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedPermissions.add(
                                                    permission.id,
                                                  );
                                                } else {
                                                  _selectedPermissions.remove(
                                                    permission.id,
                                                  );
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }).toList(),
                                  );
                                })
                              else if (organizedPermissions.isNotEmpty)
                                // Un seul module : afficher directement les sections
                                ...organizedPermissions.first.sections.entries.map((
                                  sectionEntry,
                                ) {
                                  final moduleId =
                                      organizedPermissions.first.moduleId;
                                  final sectionId = sectionEntry.key;
                                  final sectionPermissions = sectionEntry.value;
                                  final moduleSections =
                                      ModuleSectionsRegistry.getSectionsForModule(
                                        moduleId,
                                      );
                                  final sectionInfo = moduleSections.firstWhere(
                                    (s) => s.id == sectionId,
                                    orElse: () => ModuleSection(
                                      id: sectionId,
                                      name: sectionId,
                                      icon: Icons.category_outlined,
                                    ),
                                  );

                                  final sectionPermissionIds =
                                      sectionPermissions
                                          .map((p) => p.id)
                                          .toSet();
                                  final allSectionSelected =
                                      sectionPermissionIds.every(
                                        (id) =>
                                            _selectedPermissions.contains(id),
                                      );

                                  return ExpansionTile(
                                    leading: Checkbox(
                                      value:
                                          allSectionSelected &&
                                          sectionPermissionIds.isNotEmpty,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedPermissions.addAll(
                                              sectionPermissionIds,
                                            );
                                          } else {
                                            _selectedPermissions.removeAll(
                                              sectionPermissionIds,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          sectionInfo.icon,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sectionInfo.name,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${sectionPermissions.length} permission${sectionPermissions.length > 1 ? 's' : ''}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    children: sectionPermissions.map((
                                      permission,
                                    ) {
                                      return CheckboxListTile(
                                        title: Text(permission.name),
                                          // Subtitle removed to hide technical English IDs
                                        value: _selectedPermissions.contains(
                                          permission.id,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedPermissions.add(
                                                permission.id,
                                              );
                                            } else {
                                              _selectedPermissions.remove(
                                                permission.id,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                })
                              else
                                // Fallback : afficher toutes les permissions en liste simple
                                ...sortedPermissionIds.map((permissionId) {
                                  final permissionName =
                                      allPermissionsMap[permissionId] ??
                                      permissionId;
                                  return CheckboxListTile(
                                    title: Text(permissionName),
                                      // Subtitle removed to hide technical English IDs
                                    value: _selectedPermissions.contains(
                                      permissionId,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedPermissions.add(
                                            permissionId,
                                          );
                                        } else {
                                          _selectedPermissions.remove(
                                            permissionId,
                                          );
                                        }
                                      });
                                    },
                                  );
                                }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildActions(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateGallery(ThemeData theme) {
    final modules = PredefinedRoles.rolesByModule;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _buildTemplateHeader(theme, 'Commencer de zéro', Icons.add_circle_outline),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.02),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            ),
            title: const Text('Rôle vide', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Configurez tout manuellement'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => setState(() => _showTemplates = false),
          ),
        ),
        const SizedBox(height: 16),
        ...modules.entries
            .where((entry) => _selectedModuleId == null || entry.key == _selectedModuleId)
            .map((entry) {
          final moduleId = entry.key;
          final roles = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTemplateHeader(
                theme, 
                _getModuleName(moduleId), 
                _getModuleIcon(moduleId),
              ),
              ...roles.map((role) => _buildTemplateCard(theme, role)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTemplateHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ThemeData theme, UserRole role) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        title: Text(
          role.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          role.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _applyTemplate(role),
      ),
    );
  }

  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'gaz': return Icons.local_gas_station;
      case 'eau_minerale': return Icons.water_drop;
      case 'boutique': return Icons.shopping_bag;
      case 'orange_money': return Icons.vibration;
      case 'administration': return Icons.admin_panel_settings;
      default: return Icons.category;
    }
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Padding(
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
          if (!_showTemplates)
            IntrinsicWidth(
              child: FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Créer'),
              ),
            ),
        ],
      ),
    );
  }

  /// Met à jour les types d'entreprises selon le mode sélectionné
  void _updateEnterpriseTypesFromMode() {
    switch (_enterpriseLevelMode) {
      case 'company':
        _selectedEnterpriseTypes = {
          EnterpriseType.gasCompany,
          EnterpriseType.waterEntity,
          EnterpriseType.shop,
          EnterpriseType.mobileMoneyAgent,
        };
        break;
      case 'pos':
        _selectedEnterpriseTypes = {
          EnterpriseType.gasPointOfSale,
          EnterpriseType.waterPointOfSale,
          EnterpriseType.waterFactory,
          EnterpriseType.shopBranch,
          EnterpriseType.mobileMoneySubAgent,
        };
        break;
      case 'all':
      default:
        _selectedEnterpriseTypes = {};
        break;
    }
  }

  /// Obtient un message de suggestion pour les permissions
  String _getPermissionSuggestion() {
    switch (_enterpriseLevelMode) {
      case 'company':
        return 'Recommandé : Tableaux de bord, Rapports, Gestion des ventes et stocks';
      case 'pos':
        return 'Recommandé : Caisse, Création de vente, Gestion du stock local';
      default:
        return 'Sélectionnez les permissions appropriées pour ce rôle';
    }
  }

  /// Construit une option de niveau d'entreprise
  Widget _buildEnterpriseLevelOption({
    required ThemeData theme,
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getModuleName(String moduleId) {
    switch (moduleId) {
      case 'eau_minerale':
        return 'Eau Minérale';
      case 'gaz':
        return 'Gaz';
      case 'orange_money':
        return 'Orange Money';
      case 'immobilier':
        return 'Immobilier';
      case 'boutique':
        return 'Boutique';
      case 'administration':
        return 'Administration';
      default:
        return moduleId;
    }
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme, 
    String label, 
    String hint, 
    IconData icon, {
    String? helper,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
