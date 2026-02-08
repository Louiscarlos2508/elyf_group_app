import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../domain/entities/user.dart';
import '../../../../application/providers.dart';
import 'widgets/module_selection_widget.dart';
import 'widgets/multiple_module_enterprise_selection_widget.dart';

/// Dialogue pour attribuer un utilisateur à une ou plusieurs entreprises avec un ou plusieurs modules et un rôle.
///
/// Ordre de sélection : Module(s) → Rôle(s) → Entreprise(s)
class AssignEnterpriseDialog extends ConsumerStatefulWidget {
  const AssignEnterpriseDialog({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AssignEnterpriseDialog> createState() =>
      _AssignEnterpriseDialogState();
}

class _AssignEnterpriseDialogState
    extends ConsumerState<AssignEnterpriseDialog> {
  final Set<String> _selectedRoleIds = {};
  Set<String> _selectedModuleIds = {};
  Set<String> _selectedEnterpriseIds = {};
  bool _isActive = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
            color: (isDark ? Colors.grey[900] : Colors.white)!.withValues(alpha: 0.95),
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
                     color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                     border: Border(
                       bottom: BorderSide(
                         color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
                               color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                               'Attribuer des accès',
                               style: theme.textTheme.titleLarge?.copyWith(
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               'Gérez les accès pour ${widget.user.fullName}',
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
                           backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                         ),
                       ),
                     ],
                   ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 1. Sélection multiple des Modules
                        MultipleModuleSelection(
                          selectedModuleIds: _selectedModuleIds,
                          onChanged: (moduleIds) {
                            setState(() {
                              _selectedModuleIds = moduleIds;
                              _selectedRoleIds.clear();
                              _selectedEnterpriseIds.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        // 2. Sélection multiple des Rôles (si modules sélectionnés)
                        if (_selectedModuleIds.isNotEmpty)
                          rolesAsync.when(
                            data: (roles) {
                              // Filtrer les rôles par les modules sélectionnés
                              final availableRoles = roles.where((role) => 
                                _selectedModuleIds.contains(role.moduleId) || 
                                role.moduleId == 'administration'
                              ).toList();

                              if (availableRoles.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: theme.colorScheme.error),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Aucun rôle disponible pour les modules sélectionnés',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                      Text(
                                        'Rôles',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 12,
                                    children: availableRoles.map((role) {
                                      final isSelected = _selectedRoleIds.contains(role.id);
                                      return FilterChip(
                                        label: Text(role.name),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedRoleIds.add(role.id);
                                            } else {
                                              _selectedRoleIds.remove(role.id);
                                            }
                                            _selectedEnterpriseIds.clear();
                                          });
                                        },
                                        selectedColor: theme.colorScheme.primaryContainer,
                                        checkmarkColor: theme.colorScheme.primary,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        labelStyle: TextStyle(
                                          color: isSelected 
                                            ? theme.colorScheme.primary 
                                            : theme.colorScheme.onSurface,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          side: BorderSide(
                                            color: isSelected 
                                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                              : Colors.transparent,
                                          ),
                                        ),
                                        avatar: isSelected ? null : CircleAvatar(
                                          radius: 8,
                                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                          child: Icon(Icons.check, size: 10, color: theme.colorScheme.onSurface),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                            error: (error, stack) => Text('Erreur: $error'),
                          ),
                        const SizedBox(height: 32),

                        // 3. Sélection d'entreprise(s) (si modules et rôles sélectionnés)
                        if (_selectedModuleIds.isNotEmpty &&
                            _selectedRoleIds.isNotEmpty)
                          rolesAsync.when(
                            data: (allRoles) {
                              final selectedRoleObjects = allRoles
                                  .where((r) => _selectedRoleIds.contains(r.id))
                                  .toList();

                              return enterprisesAsync.when(
                                data: (enterprises) {
                                  return MultipleModuleEnterpriseSelection(
                                    enterprises: enterprises,
                                    selectedEnterpriseIds:
                                        _selectedEnterpriseIds,
                                    onChanged: (ids) {
                                      setState(() {
                                        _selectedEnterpriseIds = ids;
                                      });
                                    },
                                    moduleIds: _selectedModuleIds,
                                    selectedRoles: selectedRoleObjects,
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (error, stack) => Text('Erreur: $error'),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stack) => Text('Erreur: $error'),
                          ),

                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              'Accès actif',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Désactivez pour retirer temporairement l\'accès',
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
                                  _selectedRoleIds.isEmpty ||
                                  _selectedModuleIds.isEmpty ||
                                  _selectedEnterpriseIds.isEmpty)
                              ? null
                              : _handleSubmit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Attribuer (${_selectedModuleIds.length} mods / ${_selectedEnterpriseIds.length} ent)',
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

  Future<void> _handleSubmit() async {
    if (_selectedRoleIds.isEmpty ||
        _selectedModuleIds.isEmpty ||
        _selectedEnterpriseIds.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(adminControllerProvider)
          .batchAssignUserToModulesAndEnterprises(
            userId: widget.user.id,
            moduleIds: _selectedModuleIds.toList(),
            enterpriseIds: _selectedEnterpriseIds.toList(),
            roleIds: _selectedRoleIds.toList(),
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
