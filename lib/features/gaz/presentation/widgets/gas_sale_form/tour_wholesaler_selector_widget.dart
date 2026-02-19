import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/wholesaler.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';

/// Widget pour sélectionner un tour et un grossiste (pour ventes en gros).
///
/// Permet de :
/// - Sélectionner un tour
/// - Sélectionner un grossiste parmi ceux existants (tous les tours + ventes)
/// - Ajouter un nouveau grossiste
class TourWholesalerSelectorWidget extends ConsumerStatefulWidget {
  const TourWholesalerSelectorWidget({
    super.key,
    required this.selectedTour,
    required this.selectedWholesalerId,
    required this.selectedWholesalerName,
    required this.enterpriseId,
    required this.onTourChanged,
    required this.onWholesalerChanged,
  });

  final Tour? selectedTour;
  final String? selectedWholesalerId;
  final String? selectedWholesalerName;
  final String enterpriseId;
  final ValueChanged<Tour?> onTourChanged;
  final ValueChanged<({String id, String name, String tier})?> onWholesalerChanged;

  @override
  ConsumerState<TourWholesalerSelectorWidget> createState() =>
      _TourWholesalerSelectorWidgetState();
}

class _TourWholesalerSelectorWidgetState
    extends ConsumerState<TourWholesalerSelectorWidget> {
  final _wholesalerNameController = TextEditingController();
  final _wholesalerPhoneController = TextEditingController();
  final _wholesalerAddressController = TextEditingController();
  bool _isAddingNewWholesaler = false;

  @override
  void dispose() {
    _wholesalerNameController.dispose();
    _wholesalerPhoneController.dispose();
    _wholesalerAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toursAsync = ref.watch(
      toursProvider((enterpriseId: widget.enterpriseId, status: null)),
    );
    final allWholesalersAsync = ref.watch(
      allWholesalersProvider(widget.enterpriseId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection du tour
        toursAsync.when(
          data: (tours) {
            // Filtrer les tours actifs (pas clôturés)
            final activeTours = tours
                .where(
                  (t) =>
                      t.status != TourStatus.closure &&
                      t.status != TourStatus.cancelled,
                )
                .toList();

            return DropdownButtonFormField<Tour?>(
              initialValue: widget.selectedTour,
              decoration: const InputDecoration(
                labelText: 'Source de la vente *',
                prefixIcon: Icon(Icons.local_shipping),
                border: OutlineInputBorder(),
                helperText: 'Enlèvement au dépôt ou Livraison par Tournée',
              ),
              items: [
                DropdownMenuItem<Tour?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.warehouse, size: 20, color: theme.colorScheme.primary),
                      SizedBox(width: 8),
                      Text('Enlèvement au dépôt'),
                    ],
                  ),
                ),
                ...activeTours.map(
                  (tour) => DropdownMenuItem<Tour?>(
                    value: tour,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tournée: ${_formatDate(tour.tourDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${tour.collections.where((c) => c.type == CollectionType.wholesaler).length} grossiste(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                widget.onTourChanged(value);
                // Réinitialiser le grossiste sélectionné quand le tour change
                widget.onWholesalerChanged(null);
                setState(() {
                  _isAddingNewWholesaler = false;
                });
              },
              validator: (value) => null, // Optionnel (null = dépôt)
            );
          },
          loading: () => const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur de chargement des tours: $e',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sélection du grossiste (Toujours visible pour le gros)
        _buildWholesalerSelector(allWholesalersAsync),
      ],
    );
  }

  Widget _buildWholesalerSelector(
    AsyncValue<List<Wholesaler>> allWholesalersAsync,
  ) {
    final theme = Theme.of(context);
    return allWholesalersAsync.when(
      data: (allWholesalers) {
        // Si on est en mode ajout, afficher le formulaire
        if (_isAddingNewWholesaler) {
          return _buildNewWholesalerForm();
        }

        // Sinon, afficher la liste des grossistes avec option d'ajout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.selectedWholesalerId,
                    decoration: const InputDecoration(
                      labelText: 'Grossiste *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                      helperText:
                          'Sélectionnez un grossiste existant ou ajoutez-en un nouveau',
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('-- Sélectionner --'),
                      ),
                      ...allWholesalers.map((wholesaler) {
                        return DropdownMenuItem<String>(
                          value: wholesaler.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                wholesaler.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (wholesaler.phone != null)
                                Text(
                                  wholesaler.phone!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        final wholesaler = allWholesalers.firstWhere(
                          (w) => w.id == value,
                        );
                        widget.onWholesalerChanged((
                          id: wholesaler.id,
                          name: wholesaler.name,
                          tier: wholesaler.tier,
                        ));
                      } else {
                        widget.onWholesalerChanged(null);
                      }
                    },
                    validator: (value) {
                      if (!_isAddingNewWholesaler &&
                          (value == null || value.isEmpty)) {
                        return 'Veuillez sélectionner un grossiste ou en ajouter un nouveau';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNewWholesaler = true;
                  widget.onWholesalerChanged(null);
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un nouveau grossiste'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
          ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erreur de chargement des grossistes: $e',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewWholesalerForm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nouveau grossiste - Les informations seront enregistrées',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerNameController,
          decoration: const InputDecoration(
            labelText: 'Nom du grossiste *',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerAddressController,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                    widget.onWholesalerChanged(null);
                  });
                },
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final name = _wholesalerNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le nom du grossiste est requis'),
                      ),
                    );
                    return;
                  }

                  // Générer un ID unique pour le nouveau grossiste
                  final newId = 'wholesaler_${DateTime.now().millisecondsSinceEpoch}';

                  // Notifier le parent avec le nouveau grossiste
                  widget.onWholesalerChanged((
                    id: newId,
                    name: name,
                    tier: 'default',
                  ));

                  // Si un tour est sélectionné, ajouter le grossiste au tour
                  if (widget.selectedTour != null) {
                    _addWholesalerToTour(
                      widget.selectedTour!,
                      newId,
                      name,
                      _wholesalerPhoneController.text.trim(),
                      _wholesalerAddressController.text.trim(),
                    );
                  }

                  // Réinitialiser le formulaire
                  setState(() {
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Grossiste "$name" ajouté avec succès'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addWholesalerToTour(
    Tour tour,
    String wholesalerId,
    String wholesalerName,
    String phone,
    String address,
  ) async {
    final theme = Theme.of(context);
    try {
      final controller = ref.read(tourControllerProvider);

      // Créer une nouvelle collection pour ce grossiste
      final newCollection = Collection(
        id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
        type: CollectionType.wholesaler,
        clientId: wholesalerId,
        clientName: wholesalerName,
        clientPhone: phone,
        clientAddress: address.isNotEmpty ? address : null,
        emptyBottles: const {},
        unitPrice: 0.0,
      );

      // Ajouter la collection au tour
      final updatedCollections = [...tour.collections, newCollection];
      final updatedTour = tour.copyWith(collections: updatedCollections);

      // Mettre à jour le tour
      await controller.updateTour(updatedTour);

      // Invalider le provider pour rafraîchir la liste
      if (!mounted) return;
      ref.invalidate(allWholesalersProvider(widget.enterpriseId));
      ref.invalidate(
        toursProvider((enterpriseId: widget.enterpriseId, status: null)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout au tour: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
