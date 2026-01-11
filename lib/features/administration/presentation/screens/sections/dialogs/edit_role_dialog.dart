import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' show currentUserIdProvider;

/// Dialogue pour modifier un rôle existant.
class EditRoleDialog extends ConsumerStatefulWidget {
  const EditRoleDialog({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  ConsumerState<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<EditRoleDialog>
    with FormHelperMixin {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.role.name);
    _descriptionController =
        TextEditingController(text: widget.role.description);
    _selectedPermissions = Set.from(widget.role.permissions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedPermissions.isEmpty) {
      NotificationService.showInfo(context, 'Sélectionnez au moins une permission');
      return;
    }

    if (widget.role.isSystemRole) {
      NotificationService.showInfo(context, 'Les rôles système ne peuvent pas être modifiés');
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
          permissions: _selectedPermissions,
        );

        // Récupérer l'ID de l'utilisateur actuel pour l'audit trail
        final currentUserId = ref.read(currentUserIdProvider);

        await ref.read(adminControllerProvider).updateRole(
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du rôle *',
                          hintText: 'Gestionnaire',
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
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Description du rôle',
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
                          
                          // Parcourir tous les modules enregistrés
                          for (final moduleId in registry.registeredModules) {
                            final modulePermissions = registry.getModulePermissions(moduleId);
                            if (modulePermissions != null) {
                              for (final permission in modulePermissions.values) {
                                allPermissionsMap[permission.id] = permission.name;
                              }
                            }
                          }

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

                                final sortedPermissions = allPermissions.toList()..sort();

                                return Column(
                                  children: [
                                    if (!widget.role.isSystemRole)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CheckboxListTile(
                                              title: const Text('Toutes les permissions'),
                                              value: _selectedPermissions.length ==
                                                  sortedPermissions.length,
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedPermissions
                                                        .addAll(sortedPermissions);
                                                  } else {
                                                    _selectedPermissions.clear();
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!widget.role.isSystemRole) const Divider(),
                                    ...sortedPermissions.map((permission) {
                                      return CheckboxListTile(
                                        title: Text(permission),
                                        value: _selectedPermissions.contains(permission),
                                        enabled: !widget.role.isSystemRole,
                                        onChanged: widget.role.isSystemRole
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedPermissions.add(permission);
                                                  } else {
                                                    _selectedPermissions.remove(permission);
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

                          // Afficher les permissions organisées par module
                          final sortedPermissionIds = allPermissionsMap.keys.toList()..sort();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!widget.role.isSystemRole)
                                Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        title: const Text('Toutes les permissions'),
                                        value: _selectedPermissions.length ==
                                                sortedPermissionIds.length &&
                                            _selectedPermissions.isNotEmpty,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedPermissions
                                                  .addAll(sortedPermissionIds);
                                            } else {
                                              _selectedPermissions.clear();
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              if (!widget.role.isSystemRole) const Divider(),
                              ...sortedPermissionIds.map((permissionId) {
                                final permissionName = allPermissionsMap[permissionId] ?? permissionId;
                                return CheckboxListTile(
                                  title: Text(permissionName),
                                  subtitle: Text(
                                    permissionId,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  value: _selectedPermissions.contains(permissionId),
                                  enabled: !widget.role.isSystemRole,
                                  onChanged: widget.role.isSystemRole
                                      ? null
                                      : (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedPermissions.add(permissionId);
                                            } else {
                                              _selectedPermissions.remove(permissionId);
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
      ),
    );
  }
}

