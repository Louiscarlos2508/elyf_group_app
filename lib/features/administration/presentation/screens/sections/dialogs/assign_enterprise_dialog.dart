import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../shared.dart';
import '../../../../domain/entities/user.dart';
import '../../../../../core.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/admin_module.dart';
import '../../../../../shared.dart';

/// Dialogue pour attribuer un utilisateur à une entreprise et un module.
class AssignEnterpriseDialog extends ConsumerStatefulWidget {
  const AssignEnterpriseDialog({
    super.key,
    required this.user,
  });

  final User user;

  @override
  ConsumerState<AssignEnterpriseDialog> createState() =>
      _AssignEnterpriseDialogState();
}

class _AssignEnterpriseDialogState
    extends ConsumerState<AssignEnterpriseDialog> {
  String? _selectedEnterpriseId;
  String? _selectedModuleId;
  String? _selectedRoleId;
  bool _isActive = true;
  bool _isLoading = false;

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
                    'Attribuez ${widget.user.fullName} à une entreprise et un module',
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
                    enterprisesAsync.when(
                      data: (enterprises) {
                        final activeEnterprises =
                            enterprises.where((e) => e.isActive).toList();
                        if (activeEnterprises.isEmpty) {
                          return const Text('Aucune entreprise active');
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedEnterpriseId,
                          decoration: const InputDecoration(
                            labelText: 'Entreprise *',
                          ),
                          items: activeEnterprises.map((enterprise) {
                            return DropdownMenuItem(
                              value: enterprise.id,
                              child: Text(enterprise.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEnterpriseId = value;
                              _selectedModuleId = null; // Reset module
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Sélectionnez une entreprise';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stack) => Text('Erreur: $error'),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedEnterpriseId != null)
                      Builder(
                        builder: (context) {
                          final enterprises = enterprisesAsync.value ?? [];
                          final enterprise = enterprises.firstWhere(
                            (e) => e.id == _selectedEnterpriseId,
                          );

                          // Déterminer le module basé sur le type d'entreprise
                          String? moduleId;
                          if (enterprise.type == 'eau_minerale') {
                            moduleId = 'eau_minerale';
                          } else {
                            moduleId = enterprise.type;
                          }

                          // Trouver les modules disponibles pour ce type
                          final availableModules = AdminModules.all
                              .where((module) => module.id == moduleId)
                              .toList();

                          if (availableModules.isEmpty) {
                            return const Text('Aucun module disponible');
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: _selectedModuleId ?? moduleId,
                            decoration: const InputDecoration(
                              labelText: 'Module *',
                            ),
                            items: availableModules.map((module) {
                              return DropdownMenuItem(
                                value: module.id,
                                child: Text(module.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedModuleId = value;
                                _selectedRoleId = null; // Reset role
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Sélectionnez un module';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    if (_selectedModuleId != null)
                      rolesAsync.when(
                        data: (roles) {
                          if (roles.isEmpty) {
                            return const Text('Aucun rôle disponible');
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: _selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Rôle *',
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem(
                                value: role.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(role.name),
                                    Text(
                                      role.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedRoleId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Sélectionnez un rôle';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
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
                        onPressed: (_isLoading ||
                                _selectedEnterpriseId == null ||
                                _selectedModuleId == null ||
                                _selectedRoleId == null)
                            ? null
                            : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Attribuer'),
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
    if (_selectedEnterpriseId == null ||
        _selectedModuleId == null ||
        _selectedRoleId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final enterpriseModuleUser = EnterpriseModuleUser(
        userId: widget.user.id,
        enterpriseId: _selectedEnterpriseId!,
        moduleId: _selectedModuleId!,
        roleId: _selectedRoleId!,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(adminRepositoryProvider)
          .assignUserToEnterprise(enterpriseModuleUser);

      if (mounted) {
        Navigator.of(context).pop(enterpriseModuleUser);
        NotificationService.showInfo(context, 'Utilisateur attribué avec succès');
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

