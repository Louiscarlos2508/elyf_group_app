import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/point_of_sale.dart';

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

class _PointOfSaleFormDialogState
    extends ConsumerState<PointOfSaleFormDialog> with FormHelperMixin {
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
    // Utiliser les mêmes valeurs par défaut que dans les paramètres pour la cohérence
    _enterpriseId = widget.enterpriseId ?? 'gaz_1';
    _moduleId = widget.moduleId ?? 'gaz';

    if (widget.pointOfSale != null) {
      _nameController.text = widget.pointOfSale!.name;
      _addressController.text = widget.pointOfSale!.address;
      _contactController.text = widget.pointOfSale!.contact;
      _enterpriseId = widget.pointOfSale!.enterpriseId;
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
      NotificationService.showError(context, 'Veuillez remplir tous les champs requis');
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final controller = ref.read(pointOfSaleControllerProvider);
        final pointOfSale = PointOfSale(
          id: widget.pointOfSale?.id ??
              'pos-${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          contact: _contactController.text.trim(),
          enterpriseId: _enterpriseId!,
          moduleId: _moduleId!,
          isActive: widget.pointOfSale?.isActive ?? true,
          createdAt: widget.pointOfSale?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.pointOfSale == null) {
          await controller.addPointOfSale(pointOfSale);
        } else {
          await controller.updatePointOfSale(pointOfSale);
        }

        if (mounted) {
          // Invalider le provider pour rafraîchir la liste
          ref.invalidate(
            pointsOfSaleProvider(
              (enterpriseId: _enterpriseId!, moduleId: _moduleId!),
            ),
          );
          Navigator.of(context).pop(true);
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
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
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du point de vente *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  // Adresse
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  // Contact
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact (Téléphone) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: GazButtonStyles.outlined,
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _savePointOfSale,
                          style: GazButtonStyles.filledPrimary,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.pointOfSale == null
                                      ? 'Créer'
                                      : 'Enregistrer',
                                ),
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
    );
  }
}

