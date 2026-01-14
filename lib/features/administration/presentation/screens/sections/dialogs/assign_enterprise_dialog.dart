import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../domain/entities/user.dart';
import 'package:elyf_groupe_app/core.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import 'widgets/module_selection_widget.dart';
import 'widgets/multiple_module_enterprise_selection_widget.dart';

/// Dialogue pour attribuer un utilisateur à une ou plusieurs entreprises avec un ou plusieurs modules et un rôle.
///
/// Ordre de sélection : Rôle → Module(s) → Entreprise(s)
/// Plus logique car les rôles sont globaux et peuvent avoir des permissions pour plusieurs modules.
class AssignEnterpriseDialog extends ConsumerStatefulWidget {
  const AssignEnterpriseDialog({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AssignEnterpriseDialog> createState() =>
      _AssignEnterpriseDialogState();
}

class _AssignEnterpriseDialogState
    extends ConsumerState<AssignEnterpriseDialog> {
  String? _selectedRoleId;
  Set<String> _selectedModuleIds = {};
  Set<String> _selectedEnterpriseIds = {};
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
                    // Sélection du Rôle (en premier)
                    rolesAsync.when(
                      data: (roles) {
                        final uniqueRoles = <String, UserRole>{};
                        for (final role in roles) {
                          if (!uniqueRoles.containsKey(role.id)) {
                            uniqueRoles[role.id] = role;
                          }
                        }
                        final deduplicatedRoles = uniqueRoles.values.toList();

                        if (deduplicatedRoles.isEmpty) {
                          return const Text('Aucun rôle disponible');
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedRoleId,
                          decoration: const InputDecoration(
                            labelText: 'Rôle *',
                            helperText: 'Sélectionnez d\'abord le rôle',
                          ),
                          items: deduplicatedRoles.map((role) {
                            return DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleId = value;
                              _selectedModuleIds.clear();
                              _selectedEnterpriseIds.clear();
                            });
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

                    // Sélection multiple des Modules (si rôle sélectionné)
                    if (_selectedRoleId != null)
                      MultipleModuleSelection(
                        selectedModuleIds: _selectedModuleIds,
                        onChanged: (moduleIds) {
                          setState(() {
                            _selectedModuleIds = moduleIds;
                            _selectedEnterpriseIds.clear();
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Sélection d'entreprise(s) (si rôle et modules sélectionnés)
                    if (_selectedRoleId != null &&
                        _selectedModuleIds.isNotEmpty)
                      enterprisesAsync.when(
                        data: (enterprises) {
                          return MultipleModuleEnterpriseSelection(
                            enterprises: enterprises,
                            selectedEnterpriseIds: _selectedEnterpriseIds,
                            onChanged: (ids) {
                              setState(() {
                                _selectedEnterpriseIds = ids;
                              });
                            },
                            moduleIds: _selectedModuleIds,
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
                  Flexible(
                    child: FilledButton(
                      onPressed:
                          (_isLoading ||
                              _selectedRoleId == null ||
                              _selectedModuleIds.isEmpty ||
                              _selectedEnterpriseIds.isEmpty)
                          ? null
                          : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Attribuer (${_selectedModuleIds.length}/${_selectedEnterpriseIds.length})',
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
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedRoleId == null ||
        _selectedModuleIds.isEmpty ||
        _selectedEnterpriseIds.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser la méthode batch pour plusieurs modules et entreprises
      await ref
          .read(adminControllerProvider)
          .batchAssignUserToModulesAndEnterprises(
            userId: widget.user.id,
            moduleIds: _selectedModuleIds.toList(),
            enterpriseIds: _selectedEnterpriseIds.toList(),
            roleId: _selectedRoleId!,
            isActive: _isActive,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        NotificationService.showInfo(
          context,
          'Utilisateur attribué à ${_selectedModuleIds.length} module(s) et ${_selectedEnterpriseIds.length} entreprise(s) avec succès',
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
