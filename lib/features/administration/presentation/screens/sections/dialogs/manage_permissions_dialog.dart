import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../application/providers.dart';
import '../../../../domain/services/permission_section_mapper.dart';
import '../../../../domain/entities/module_sections_info.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';

/// Dialogue pour gérer les permissions personnalisées d'un utilisateur.
class ManagePermissionsDialog extends ConsumerStatefulWidget {
  const ManagePermissionsDialog({
    super.key,
    required this.enterpriseModuleUser,
  });

  final EnterpriseModuleUser enterpriseModuleUser;

  @override
  ConsumerState<ManagePermissionsDialog> createState() =>
      _ManagePermissionsDialogState();
}

class _ManagePermissionsDialogState
    extends ConsumerState<ManagePermissionsDialog> {
  late Set<String> _customPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customPermissions = Set.from(
      widget.enterpriseModuleUser.customPermissions,
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(adminControllerProvider)
          .updateUserPermissions(
            widget.enterpriseModuleUser.userId,
            widget.enterpriseModuleUser.enterpriseId,
            widget.enterpriseModuleUser.moduleId,
            _customPermissions,
          );

      if (mounted) {
        Navigator.of(context).pop(_customPermissions);
        NotificationService.showInfo(
          context,
          'Permissions mises à jour avec succès',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gérer les Permissions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permissions personnalisées (en plus du rôle)',
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
                child: Builder(
                  builder: (context) {
                    // Récupérer toutes les permissions enregistrées depuis PermissionRegistry
                    final registry = PermissionRegistry.instance;
                    final allPermissionsMap = <String, String>{};
                    final permissionsByModuleList =
                        <String, List<ModulePermission>>{};

                    // Pour les permissions personnalisées, on ne devrait montrer que les permissions
                    // liées au module de l'assignation courante
                    final targetModuleId = widget.enterpriseModuleUser.moduleId;
                    
                    // Récupérer uniquement les permissions du module concerné
                    final modulePermissions = registry.getModulePermissions(targetModuleId);
                    
                    if (modulePermissions != null) {
                      final modulePerms = <ModulePermission>[];
                      for (final permission in modulePermissions.values) {
                        allPermissionsMap[permission.id] = permission.name;
                        modulePerms.add(permission);
                      }
                      if (modulePerms.isNotEmpty) {
                        permissionsByModuleList[targetModuleId] = modulePerms;
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
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune permission disponible',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Les permissions doivent être enregistrées dans PermissionRegistry',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final sortedPermissions = allPermissions.toList()
                            ..sort();

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
                                          _customPermissions.length ==
                                          sortedPermissions.length,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _customPermissions.addAll(
                                              sortedPermissions,
                                            );
                                          } else {
                                            _customPermissions.clear();
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
                                  value: _customPermissions.contains(
                                    permission,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _customPermissions.add(permission);
                                      } else {
                                        _customPermissions.remove(permission);
                                      }
                                    });
                                  },
                                );
                              }),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                      );
                    }

                    // Afficher les permissions organisées par module → section → permissions
                    final sortedPermissionIds = allPermissionsMap.keys.toList()
                      ..sort();
                    final totalPermissions = sortedPermissionIds.length;

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
                                  '$totalPermissions permission${totalPermissions > 1 ? 's' : ''} disponible${totalPermissions > 1 ? 's' : ''} (${organizedPermissions.length} module${organizedPermissions.length > 1 ? 's' : ''})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sélectionner toutes les permissions
                        CheckboxListTile(
                          title: const Text('Toutes les permissions'),
                          value:
                              _customPermissions.length == totalPermissions &&
                              _customPermissions.isNotEmpty,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _customPermissions.addAll(sortedPermissionIds);
                              } else {
                                _customPermissions.clear();
                              }
                            });
                          },
                        ),
                        const Divider(),
                        // Afficher les permissions organisées par module → section
                        if (organizedPermissions.length > 1)
                          ...organizedPermissions.map((moduleData) {
                            return _buildModuleSection(
                              context,
                              theme,
                              moduleData,
                              organizedPermissions,
                            );
                          })
                        else if (organizedPermissions.isNotEmpty)
                          // Un seul module : afficher directement les sections
                          ...organizedPermissions.first.sections.entries.map((
                            sectionEntry,
                          ) {
                            return _buildSectionTile(
                              context,
                              theme,
                              organizedPermissions.first.moduleId,
                              sectionEntry.key,
                              sectionEntry.value,
                            );
                          })
                        else
                          // Fallback : afficher toutes les permissions en liste simple
                          ...sortedPermissionIds.map((permissionId) {
                            final permissionName =
                                allPermissionsMap[permissionId] ?? permissionId;
                            return CheckboxListTile(
                              title: Text(permissionName),
                              subtitle: Text(
                                permissionId,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: _customPermissions.contains(permissionId),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _customPermissions.add(permissionId);
                                  } else {
                                    _customPermissions.remove(permissionId);
                                  }
                                });
                              },
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  Widget _buildModuleSection(
    BuildContext context,
    ThemeData theme,
    PermissionsBySection moduleData,
    List<PermissionsBySection> allModules,
  ) {
    final moduleId = moduleData.moduleId;
    final sections = moduleData.sections;
    final modulePermissionIds = sections.values
        .expand((perms) => perms.map((p) => p.id))
        .toSet();
    final allModuleSelected = modulePermissionIds.every(
      (id) => _customPermissions.contains(id),
    );

    return ExpansionTile(
      leading: Checkbox(
        value: allModuleSelected && modulePermissionIds.isNotEmpty,
        tristate: true,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _customPermissions.addAll(modulePermissionIds);
            } else {
              _customPermissions.removeAll(modulePermissionIds);
            }
          });
        },
      ),
      title: Text(
        _getModuleName(moduleId),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${sections.values.fold<int>(0, (sum, perms) => sum + perms.length)} permission${sections.values.fold<int>(0, (sum, perms) => sum + perms.length) > 1 ? 's' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      children: sections.entries.map((sectionEntry) {
        return _buildSectionTile(
          context,
          theme,
          moduleId,
          sectionEntry.key,
          sectionEntry.value,
        );
      }).toList(),
    );
  }

  Widget _buildSectionTile(
    BuildContext context,
    ThemeData theme,
    String moduleId,
    String sectionId,
    List<ModulePermission> sectionPermissions,
  ) {
    final moduleSections = ModuleSectionsRegistry.getSectionsForModule(
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
    final sectionPermissionIds = sectionPermissions.map((p) => p.id).toSet();
    final allSectionSelected = sectionPermissionIds.every(
      (id) => _customPermissions.contains(id),
    );

    return ExpansionTile(
      leading: Checkbox(
        value: allSectionSelected && sectionPermissionIds.isNotEmpty,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _customPermissions.addAll(sectionPermissionIds);
            } else {
              _customPermissions.removeAll(sectionPermissionIds);
            }
          });
        },
      ),
      title: Row(
        children: [
          Icon(sectionInfo.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sectionInfo.name,
              style: theme.textTheme.bodyLarge?.copyWith(
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
      children: sectionPermissions.map((permission) {
        return CheckboxListTile(
          title: Text(permission.name),
          subtitle: Text(
            permission.id,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: _customPermissions.contains(permission.id),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _customPermissions.add(permission.id);
              } else {
                _customPermissions.remove(permission.id);
              }
            });
          },
        );
      }).toList(),
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
