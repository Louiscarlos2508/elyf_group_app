import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import '../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../application/providers.dart' as gaz_providers;
import '../../domain/entities/point_of_sale.dart';
import '../../../../features/administration/application/providers.dart'
    show enterprisesProvider, enterprisesByTypeProvider, enterpriseByIdProvider, adminStatsProvider;
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';

/// Dialogue pour créer ou modifier un point de vente.
class PointOfSaleFormDialog extends ConsumerStatefulWidget {
  const PointOfSaleFormDialog({
    super.key,
    this.pointOfSale,
    this.enterpriseId,
    this.moduleId,
  });

  final PointOfSale? pointOfSale;
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
      'PointOfSaleFormDialog.initState: pointOfSale=${widget.pointOfSale?.id ?? "null"}, enterpriseId=${widget.enterpriseId}, moduleId=${widget.moduleId}',
      name: 'PointOfSaleFormDialog',
    );
    
    if (widget.pointOfSale != null) {
      _nameController.text = widget.pointOfSale!.name;
      _addressController.text = widget.pointOfSale!.address;
      _contactController.text = widget.pointOfSale!.contact;
      _enterpriseId = widget.pointOfSale!.parentEnterpriseId;
      _moduleId = widget.pointOfSale!.moduleId;
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
        final currentUserId = ref.read(gaz_providers.currentUserIdProvider);

        if (widget.pointOfSale == null) {
          final parentEnterpriseId = _enterpriseId!;
          final service = ref.read(gaz_providers.pointOfSaleServiceProvider);
          await service.createPointOfSaleWithEnterprise(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            contact: _contactController.text.trim(),
            parentEnterpriseId: parentEnterpriseId,
            createdByUserId: currentUserId,
            cylinderIds: const [],
          );
        } else {
          final controller = ref.read(gaz_providers.pointOfSaleControllerProvider);
          final pointOfSale = widget.pointOfSale!.copyWith(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            contact: _contactController.text.trim(),
            updatedAt: DateTime.now(),
          );
          await controller.updatePointOfSale(pointOfSale);
        }

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          ref.invalidate(
            gaz_providers.pointsOfSaleProvider((
              enterpriseId: _enterpriseId!,
              moduleId: _moduleId!,
            )),
          );
          ref.invalidate(enterprisesProvider);
          ref.invalidate(enterprisesByTypeProvider);
          ref.invalidate(enterpriseByIdProvider);
          ref.invalidate(adminStatsProvider);
          
          if (mounted && context.mounted) {
            Navigator.of(context).pop(true);
          }
        }

        return widget.pointOfSale == null
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
                            widget.pointOfSale == null
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Flexible(
                          child: ElyfButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            variant: ElyfButtonVariant.outlined,
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElyfButton(
                            onPressed: _isLoading ? null : _savePointOfSale,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
