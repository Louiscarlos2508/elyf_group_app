import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import '../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../../../features/administration/domain/entities/enterprise.dart';
import '../../../../features/administration/domain/entities/user.dart';
import '../../../../core/auth/providers.dart' show currentUserIdProvider;
import '../../../../features/administration/application/providers.dart'
    show
        enterpriseControllerProvider,
        enterprisesProvider,
        enterprisesByTypeProvider,
        enterpriseByIdProvider,
        adminStatsProvider,
        enterpriseModuleUsersProvider,
        usersProvider;

/// Dialogue pour créer ou modifier un point de vente.
class PointOfSaleFormDialog extends ConsumerStatefulWidget {
  const PointOfSaleFormDialog({
    super.key,
    this.enterprise,
    this.enterpriseId,
    this.moduleId,
  });

  final Enterprise? enterprise;
  final String? enterpriseId;
  final String? moduleId;

  @override
  ConsumerState<PointOfSaleFormDialog> createState() =>
      _PointOfSaleFormDialogState();
}

class _PointOfSaleFormDialogState extends ConsumerState<PointOfSaleFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isLoading = false;
  String? _enterpriseId;
  String? _moduleId;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(
      'PointOfSaleFormDialog.initState: enterprise=${widget.enterprise?.id ?? "null"}, enterpriseId=${widget.enterpriseId}, moduleId=${widget.moduleId}',
      name: 'PointOfSaleFormDialog',
    );
    
    if (widget.enterprise != null) {
      _nameController.text = widget.enterprise!.name;
      _addressController.text = widget.enterprise!.address ?? '';
      _contactController.text = widget.enterprise!.phone ?? '';
      _enterpriseId = widget.enterprise!.parentEnterpriseId;
      _moduleId = widget.enterprise!.moduleId;
    } else {
      _enterpriseId = widget.enterpriseId;
      _moduleId = widget.moduleId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _savePointOfSale() async {
    if (_enterpriseId == null || _moduleId == null) {
      NotificationService.showError(
        context,
        'Veuillez remplir tous les champs requis',
      );
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final controller = ref.read(enterpriseControllerProvider);
        final currentUserId = ref.read(currentUserIdProvider);

        if (widget.enterprise == null) {
          final parentEnterpriseId = _enterpriseId!;
          
          final pointOfSale = Enterprise(
            id: 'pos_${parentEnterpriseId}_${DateTime.now().millisecondsSinceEpoch}',
            name: _nameController.text.trim(),
            type: EnterpriseType.gasPointOfSale,
            parentEnterpriseId: parentEnterpriseId,
            moduleId: _moduleId,
            address: _addressController.text.trim(),
            phone: _contactController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await controller.createEnterprise(pointOfSale, currentUserId: currentUserId);
        } else {
          final pointOfSale = widget.enterprise!.copyWith(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _contactController.text.trim(),
            updatedAt: DateTime.now(),
          );
          await controller.updateEnterprise(pointOfSale, currentUserId: currentUserId);
        }

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          ref.invalidate(enterprisesProvider);
          ref.invalidate(enterprisesByTypeProvider);
          ref.invalidate(enterpriseByIdProvider);
          ref.invalidate(adminStatsProvider);
          
          if (mounted && context.mounted) {
            Navigator.of(context).pop(true);
          }
        }

        return widget.enterprise == null
            ? 'Point de vente créé avec succès'
            : 'Point de vente mis à jour';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    activeEnterpriseAsync.whenData((enterprise) {
      _moduleId ??= widget.moduleId ?? 'gaz';
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.enterprise == null
                                ? 'Nouveau Point de Vente'
                                : 'Modifier le Point de Vente',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElyfIconButton(
                          icon: Icons.close,
                          onPressed: () => Navigator.of(context).pop(),
                          iconColor: theme.colorScheme.onSurface,
                          useGlassEffect: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du point de vente *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact (Téléphone) *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        if (value.length < 8) {
                          return 'Le numéro de téléphone doit contenir au moins 8 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _savePointOfSale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(widget.enterprise == null ? 'Créer' : 'Enregistrer'),
                        ),
                      ],
                    ),
                    if (widget.enterprise != null) ...[
                      const SizedBox(height: 32),
                      _buildAssignedUsersSection(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedUsersSection(ThemeData theme) {
    final assignmentsAsync = ref.watch(enterpriseModuleUsersProvider);
    final usersAsync = ref.watch(usersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'UTILISATEURS ASSIGNÉS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        assignmentsAsync.when(
          data: (assignments) {
            final posId = widget.enterprise!.id;
            final parentId = widget.enterprise!.parentEnterpriseId;
            
            final posAssignments = assignments.where((a) {
              final isDirect = a.enterpriseId == posId;
              final isInherited = parentId != null && 
                                 (a.enterpriseId == parentId || widget.enterprise!.ancestorIds.contains(a.enterpriseId)) && 
                                 a.includesChildren;
              
              return (isDirect || isInherited) && a.isActive;
            }).toList();

            if (posAssignments.isEmpty) {
              return Text(
                'Aucun utilisateur assigné',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              );
            }

            return usersAsync.when(
              data: (users) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posAssignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final assignment = posAssignments[index];
                    final user = users.firstWhere(
                      (u) => u.id == assignment.userId,
                      orElse: () => User(
                        id: assignment.userId,
                        firstName: 'Utilisateur',
                        lastName: 'Inconnu',
                        username: 'inconnu',
                        email: '',
                        enterpriseIds: [],
                      ),
                    );

                    final isDirect = assignment.enterpriseId == posId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDirect ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isDirect ? 'Direct' : 'Hérité',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDirect ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...assignment.roleIds.map((r) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              r.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          )),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, __) => Text('Erreur users: $e', style: const TextStyle(fontSize: 10)),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, __) => Text('Erreur: $e', style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
