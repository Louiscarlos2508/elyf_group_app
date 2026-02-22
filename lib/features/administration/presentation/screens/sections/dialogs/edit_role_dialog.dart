import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart'
    show currentUserIdProvider;
import '../../../../domain/services/permission_section_mapper.dart';
import '../../../../domain/entities/module_sections_info.dart';

/// Dialogue pour modifier un rôle existant.
class EditRoleDialog extends ConsumerStatefulWidget {
  const EditRoleDialog({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<EditRoleDialog>
    with FormHelperMixin {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late String _selectedModuleId;
  late Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.role.name);
    _descriptionController = TextEditingController(
      text: widget.role.description,
    );
    _selectedModuleId = widget.role.moduleId;
    // Normaliser les permissions pour s'assurer qu'elles correspondent aux IDs du PermissionRegistry
    _selectedPermissions = _normalizePermissions(widget.role.permissions);
  }

  /// Normalise les IDs de permissions pour qu'ils correspondent au format du PermissionRegistry.
  ///
  /// Seules les permissions du module de ce rôle sont considérées si le module est enregistré.
  Set<String> _normalizePermissions(Set<String> permissions) {
    final normalized = <String>{};
    final registry = PermissionRegistry.instance;

    // Récupérer les permissions enregistrées pour ce module
    final modulePermissions = registry.getModulePermissions(_selectedModuleId);
    final modulePermissionIds = modulePermissions?.keys.toSet() ?? {};

    // Si le module n'est pas enregistré, on garde les permissions actuelles telles quelles
    // pour éviter toute perte de données accidentelle lors de l'ouverture du dialogue.
    if (modulePermissionIds.isEmpty) {
      return Set.from(permissions);
    }

    for (final permissionId in permissions) {
      // Si la permission contient un point (format module.permission), extraire juste l'ID
      final permissionIdOnly = permissionId.contains('.') 
          ? permissionId.split('.').last 
          : permissionId;

      if (modulePermissionIds.contains(permissionIdOnly)) {
        normalized.add(permissionIdOnly);
      }
      // Note: on ignore les permissions qui ne sont pas dans le PermissionRegistry pour ce module
      // seulement SI le module a des permissions enregistrées.
    }

    return normalized;
  }


  @override
  void didUpdateWidget(EditRoleDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour les permissions si le rôle a changé
    if (oldWidget.role.id != widget.role.id ||
        oldWidget.role.permissions != widget.role.permissions ||
        oldWidget.role.moduleId != widget.role.moduleId) {
      _selectedModuleId = widget.role.moduleId;
      _selectedPermissions = _normalizePermissions(widget.role.permissions);
      _nameController.text = widget.role.name;
      _descriptionController.text = widget.role.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedPermissions.isEmpty) {
      NotificationService.showInfo(
        context,
        'Sélectionnez au moins une permission',
      );
      return;
    }

    if (widget.role.isSystemRole) {
      NotificationService.showInfo(
        context,
        'Les rôles système ne peuvent pas être modifiés',
      );
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final updatedRole = widget.role.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          moduleId: _selectedModuleId,
          permissions: _selectedPermissions,
        );

        // Récupérer l'ID de l'utilisateur actuel pour l'audit trail
        final currentUserId = ref.read(currentUserIdProvider);

        await ref
            .read(adminControllerProvider)
            .updateRole(
              updatedRole,
              currentUserId: currentUserId,
              oldRole: widget.role,
            );

        if (mounted) {
          Navigator.of(context).pop(updatedRole);
        }

        return 'Rôle modifié avec succès';
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier le Rôle',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.role.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.role.isSystemRole)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Chip(
                          label: const Text('Rôle système'),
                          backgroundColor: theme.colorScheme.primaryContainer,
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
                      // Sélecteur de Module
                      if (!widget.role.isSystemRole) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedModuleId,
                          decoration: _buildInputDecoration(
                            theme,
                            'Module associé *',
                            'Sélectionnez le module',
                            Icons.view_module_outlined,
                          ),
                          items: () {
                            final modules = Set<String>.from(PermissionRegistry.instance.registeredModules);
                            modules.add(_selectedModuleId);
                            
                            return modules.map((moduleId) {
                              return DropdownMenuItem(
                                value: moduleId,
                                child: Text(_getModuleName(moduleId)),
                              );
                            }).toList();
                          }(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedModuleId = value;
                                // Réinitialiser les permissions seulement si le module change réellement
                                if (value != widget.role.moduleId) {
                                  _selectedPermissions.clear();
                                } else {
                                  _selectedPermissions = _normalizePermissions(widget.role.permissions);
                                }
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le module est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          theme, 
                          'Nom du rôle *', 
                          'ex: Gestionnaire', 
                          Icons.badge_outlined
                        ),
                        enabled: !widget.role.isSystemRole,
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
                        enabled: !widget.role.isSystemRole,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La description est requise';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Permissions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          // Récupérer toutes les permissions enregistrées depuis PermissionRegistry
                          final registry = PermissionRegistry.instance;
                          final allPermissionsMap = <String, String>{};
                          final permissionsByModuleList =
                              <String, List<ModulePermission>>{};

                          // Parcourir uniquement le module sélectionné
                          for (final moduleId in [_selectedModuleId]) {
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
                          if (allPermissionsMap.isEmpty) {
                            // On affiche uniquement les permissions déjà présentes dans le rôle
                            // pour éviter de "polluer" avec les permissions d'autres rôles
                            if (_selectedPermissions.isEmpty) {
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
                                      'Aucune permission enregistrée pour ce module',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            final sortedPermissions = _selectedPermissions.toList()..sort();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Note: Ce module n\'est pas configuré dans le registre. Seules les permissions existantes sont affichées.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                ...sortedPermissions.map((permissionId) {
                                  // Essayer d'obtenir un nom lisible même si le module est différent
                                  final name = registry.getPermissionName(permissionId) ?? permissionId;
                                  return CheckboxListTile(
                                    title: Text(name),
                                    subtitle: Text(permissionId, style: theme.textTheme.bodySmall),
                                    value: true, // Ces permissions sont forcément sélectionnées puisqu'on les tire de _selectedPermissions
                                    enabled: !widget.role.isSystemRole,
                                    onChanged: widget.role.isSystemRole
                                        ? null
                                        : (value) {
                                            if (value == false) {
                                              setState(() {
                                                _selectedPermissions.remove(permissionId);
                                              });
                                            }
                                          },
                                  );
                                }),
                              ],
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
                              if (!widget.role.isSystemRole)
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
                              // Afficher les permissions sélectionnées qui ne sont pas dans le registre (orphelines)
                              if (_selectedPermissions.any((p) => !allPermissionsMap.containsKey(p)))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'Permissions additionnelles (hors registre)',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ..._selectedPermissions.where((p) => !allPermissionsMap.containsKey(p)).map((permissionId) {
                                      final name = registry.getPermissionName(permissionId) ?? permissionId;
                                      return CheckboxListTile(
                                        title: Text(name),
                                        subtitle: Text(permissionId, style: theme.textTheme.bodySmall),
                                        value: true,
                                        enabled: !widget.role.isSystemRole,
                                        onChanged: (value) {
                                          if (value == false) {
                                            setState(() {
                                              _selectedPermissions.remove(permissionId);
                                            });
                                          }
                                        },
                                      );
                                    }),
                                    const Divider(),
                                  ],
                                ),
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
                                      onChanged: widget.role.isSystemRole
                                          ? null
                                          : (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedPermissions.addAll(
                                                    modulePermissionIds,
                                                  );
                                                } else {
                                                  _selectedPermissions
                                                      .removeAll(
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
                                          onChanged: widget.role.isSystemRole
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedPermissions
                                                          .addAll(
                                                            sectionPermissionIds,
                                                          );
                                                    } else {
                                                      _selectedPermissions
                                                          .removeAll(
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
                                            enabled: !widget.role.isSystemRole,
                                            onChanged: widget.role.isSystemRole
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedPermissions
                                                            .add(permission.id);
                                                      } else {
                                                        _selectedPermissions
                                                            .remove(
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
                                      onChanged: widget.role.isSystemRole
                                          ? null
                                          : (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedPermissions.addAll(
                                                    sectionPermissionIds,
                                                  );
                                                } else {
                                                  _selectedPermissions
                                                      .removeAll(
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
                                        enabled: !widget.role.isSystemRole,
                                        onChanged: widget.role.isSystemRole
                                            ? null
                                            : (value) {
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
                                    enabled: !widget.role.isSystemRole,
                                    onChanged: widget.role.isSystemRole
                                        ? null
                                        : (value) {
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
                        onPressed: (_isLoading || widget.role.isSystemRole)
                            ? null
                            : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
