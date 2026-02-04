import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:developer' as developer;

import 'package:elyf_groupe_app/shared.dart';
import '../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../application/providers.dart' as gaz_providers;
import '../../domain/entities/point_of_sale.dart';
import '../../../../features/administration/application/providers.dart'
    show enterprisesProvider, enterprisesByTypeProvider, enterpriseByIdProvider, adminStatsProvider;

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
    developer.log(
      'PointOfSaleFormDialog.initState: pointOfSale=${widget.pointOfSale?.id ?? "null"}, enterpriseId=${widget.enterpriseId}, moduleId=${widget.moduleId}',
      name: 'PointOfSaleFormDialog',
    );
    
    // Les valeurs seront initialisées dans build() avec activeEnterpriseProvider
    // pour éviter les valeurs codées en dur

    if (widget.pointOfSale != null) {
      _nameController.text = widget.pointOfSale!.name;
      _addressController.text = widget.pointOfSale!.address;
      _contactController.text = widget.pointOfSale!.contact;
      _enterpriseId = widget.pointOfSale!.parentEnterpriseId;
      _moduleId = widget.pointOfSale!.moduleId;
      developer.log(
        'PointOfSaleFormDialog.initState: Mode édition, parentEnterpriseId=$_enterpriseId',
        name: 'PointOfSaleFormDialog',
      );
    } else {
      developer.log(
        'PointOfSaleFormDialog.initState: Mode création',
        name: 'PointOfSaleFormDialog',
      );
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
        // Utiliser le provider depuis gaz/application/providers.dart
        // qui gère déjà le fallback pour les utilisateurs non connectés
        // Utiliser le provider depuis gaz/application/providers.dart
        // qui gère déjà le fallback pour les utilisateurs non connectés
        final currentUserId = ref.read(gaz_providers.currentUserIdProvider);

        if (widget.pointOfSale == null) {
          // Création : utiliser le service pour créer avec Enterprise automatique
          // ⚠️ IMPORTANT: _enterpriseId doit être l'entreprise mère (gaz_1), pas un point de vente
          // Si _enterpriseId commence par 'pos_', c'est un point de vente, pas l'entreprise mère
          final parentEnterpriseId = _enterpriseId!;
          
          developer.log(
            'Création d\'un point de vente avec parentEnterpriseId=$parentEnterpriseId',
            name: 'PointOfSaleFormDialog._savePointOfSale',
          );
          
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
          // Mise à jour : utiliser le controller existant
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
          developer.log(
            'Point de vente créé, invalidation des providers...',
            name: 'PointOfSaleFormDialog._savePointOfSale',
          );
          
          // Attendre un peu pour que la base de données soit à jour
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Invalider les providers pour forcer le rafraîchissement
          // 1. Invalider les points de vente
          ref.invalidate(
            gaz_providers.pointsOfSaleProvider((
              enterpriseId: _enterpriseId!,
              moduleId: _moduleId!,
            )),
          );
          
          // 2. Invalider et forcer le refresh des entreprises pour que le nouveau point de vente
          // apparaisse dans la liste d'administration
          developer.log(
            'Invalidation de enterprisesProvider...',
            name: 'PointOfSaleFormDialog._savePointOfSale',
          );
          ref.invalidate(enterprisesProvider);
          
          // Forcer un refresh immédiat pour s'assurer que l'entreprise est visible
          try {
            await ref.read(enterprisesProvider.future);
            developer.log(
              'Refresh de enterprisesProvider effectué',
              name: 'PointOfSaleFormDialog._savePointOfSale',
            );
          } catch (e) {
            developer.log(
              'Erreur lors du refresh de enterprisesProvider: $e',
              name: 'PointOfSaleFormDialog._savePointOfSale',
              error: e,
            );
          }
          
          // 3. Invalider aussi les providers dépendants
          ref.invalidate(enterprisesByTypeProvider);
          ref.invalidate(enterpriseByIdProvider);
          ref.invalidate(adminStatsProvider);
          
          // Attendre encore un peu pour que les invalidations soient prises en compte
          await Future.delayed(const Duration(milliseconds: 200));
          
          developer.log(
            'Providers invalidés, fermeture du dialog...',
            name: 'PointOfSaleFormDialog._savePointOfSale',
          );
          
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
    developer.log(
      'PointOfSaleFormDialog.build: appelé',
      name: 'PointOfSaleFormDialog',
    );
    
    final theme = Theme.of(context);
    
    // Récupérer l'entreprise active depuis le tenant provider
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    // Initialiser enterpriseId et moduleId depuis l'entreprise active si pas déjà défini
    activeEnterpriseAsync.whenData((enterprise) {
      if (_enterpriseId == null && enterprise != null) {
        _enterpriseId = widget.enterpriseId ?? enterprise.id;
        _moduleId = widget.moduleId ?? 'gaz';
        developer.log(
          'PointOfSaleFormDialog.build: _enterpriseId initialisé depuis activeEnterprise=${enterprise.id}, final=$_enterpriseId',
          name: 'PointOfSaleFormDialog',
        );
      } else if (_enterpriseId == null) {
        // Fallback uniquement si aucune entreprise active n'est disponible
        _enterpriseId = widget.enterpriseId;
        _moduleId = widget.moduleId ?? 'gaz';
        developer.log(
          'PointOfSaleFormDialog.build: _enterpriseId initialisé depuis widget.enterpriseId=$_enterpriseId',
          name: 'PointOfSaleFormDialog',
        );
      }
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
              color: Colors.black.withOpacity(0.05),
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
                  // Adresse
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
                  // Contact
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
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: GazButtonStyles.outlined(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _savePointOfSale,
                          style: GazButtonStyles.filledPrimary(context),
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
