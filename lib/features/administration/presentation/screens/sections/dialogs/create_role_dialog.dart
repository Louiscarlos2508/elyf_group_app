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
  bool _isLoading = false;

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
          isSystemRole: false,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveau Rôle',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez un nouveau rôle avec des permissions',
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du rôle *',
                          hintText: 'Gestionnaire',
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
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Description du rôle',
                        ),
                        maxLines: 2,
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

                          // Parcourir tous les modules enregistrés
                          for (final moduleId in registry.registeredModules) {
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

                          // Si aucune permission n'est enregistrée, essayer de récupérer depuis les rôles existants
                          if (allPermissionsMap.isEmpty) {
                            return rolesAsync.when(
                              data: (roles) {
                                final allPermissions = <String>{};
                                for (final role in roles) {
                                  allPermissions.addAll(role.permissions);
                                }

                                if (allPermissions.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 48,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Aucune permission disponible',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Les permissions doivent être enregistrées dans PermissionRegistry',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final sortedPermissions =
                                    allPermissions.toList()..sort();

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            title: const Text(
                                              'Toutes les permissions',
                                            ),
                                            value:
                                                _selectedPermissions.length ==
                                                sortedPermissions.length,
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
                                      return CheckboxListTile(
                                        title: Text(permission),
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
                                            subtitle: Text(
                                              permission.id,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
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
                                        subtitle: Text(
                                          permission.id,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
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
                                    subtitle: Text(
                                      permissionId,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
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
}
