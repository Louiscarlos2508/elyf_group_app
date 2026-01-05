import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../application/providers.dart';

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
    _customPermissions = Set.from(widget.enterpriseModuleUser.customPermissions);
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(adminRepositoryProvider).updateUserPermissions(
            widget.enterpriseModuleUser.userId,
            widget.enterpriseModuleUser.enterpriseId,
            widget.enterpriseModuleUser.moduleId,
            _customPermissions,
          );

      if (mounted) {
        Navigator.of(context).pop(_customPermissions);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions mises à jour avec succès'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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
                child: rolesAsync.when(
                  data: (roles) {
                    // Récupérer toutes les permissions uniques
                    final allPermissions = <String>{};
                    for (final role in roles) {
                      allPermissions.addAll(role.permissions);
                    }

                    if (allPermissions.isEmpty) {
                      return const Text('Aucune permission disponible');
                    }

                    final sortedPermissions = allPermissions.toList()..sort();

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Toutes les permissions'),
                                value: _customPermissions.length ==
                                    sortedPermissions.length,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _customPermissions
                                          .addAll(sortedPermissions);
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
                            value: _customPermissions.contains(permission),
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
}

