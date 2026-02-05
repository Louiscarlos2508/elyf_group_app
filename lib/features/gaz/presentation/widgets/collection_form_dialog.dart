import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/point_of_sale_stock_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import 'collection_form/bottle_list_display.dart';
import 'collection_form/bottle_manager.dart';
import 'collection_form/bottle_quantity_input.dart';
import 'collection_form/client_selector.dart';
import 'collection_form/collection_form_header.dart';
import 'collection_form/collection_submit_handler.dart';
import 'collection_form/collection_type_selector.dart';

/// Formulaire d'ajout d'une collecte.
class CollectionFormDialog extends ConsumerStatefulWidget {
  const CollectionFormDialog({super.key, required this.tour});

  final Tour tour;

  @override
  ConsumerState<CollectionFormDialog> createState() =>
      _CollectionFormDialogState();
}

class _CollectionFormDialogState extends ConsumerState<CollectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  CollectionType _collectionType = CollectionType.wholesaler;
  Client? _selectedClient;
  final Map<int, int> _bottles = {}; // poids -> quantité

  // Pour le formulaire d'ajout de bouteille
  int? _selectedWeight;
  final _quantityController = TextEditingController(text: '0');

  // Pour le formulaire d'ajout de grossiste
  final _wholesalerNameController = TextEditingController();
  final _wholesalerPhoneController = TextEditingController();
  final _wholesalerAddressController = TextEditingController();
  bool _isAddingNewWholesaler = false;

  /// Récupère les clients disponibles depuis la base de données.
  List<Client> _getAvailableClients(WidgetRef ref) {
    if (_collectionType == CollectionType.wholesaler) {
      // Récupérer les grossistes depuis la base de données
      final wholesalersAsync = ref.watch(
        allWholesalersProvider(widget.tour.enterpriseId),
      );
      return wholesalersAsync.when(
        data: (wholesalers) {
          return wholesalers
              .map(
                (w) => Client(
                  id: w.id,
                  name: w.name,
                  phone: w.phone ?? '',
                  address: w.address,
                ),
              )
              .toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    } else {
      // Récupérer les points de vente depuis la base de données
      final pointsOfSaleAsync = ref.watch(
        pointsOfSaleProvider((
          enterpriseId: widget.tour.enterpriseId,
          moduleId: 'gaz',
        )),
      );
      return pointsOfSaleAsync.when(
        data: (pointsOfSale) {
          return pointsOfSale
              .map(
                (pos) {
                  // Récupérer le stock réel du point de vente
                  final stockAsync = ref.watch(pointOfSaleStockProvider(pos.id));
                  final stock = stockAsync.value ?? {};
                  final stockInt = <int, int>{};
                  stock.forEach((key, value) {
                    final weight = int.tryParse(key);
                    if (weight != null) {
                      stockInt[weight] = value;
                    }
                  });

                  return Client(
                    id: pos.id,
                    name: pos.name,
                    phone: pos.contact,
                    address: pos.address,
                    emptyStock: stockInt,
                  );
                },
              )
              .toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _wholesalerNameController.dispose();
    _wholesalerPhoneController.dispose();
    _wholesalerAddressController.dispose();
    super.dispose();
  }

  void _addBottle() {
    BottleManager.addBottle(
      context: context,
      selectedWeight: _selectedWeight,
      quantityText: _quantityController.text,
      bottles: _bottles,
      onBottlesChanged: () {
        setState(() {
          _selectedWeight = null;
          _quantityController.text = '0';
        });
      },
    );
  }

  void _removeBottle(int weight) {
    BottleManager.removeBottle(
      weight: weight,
      bottles: _bottles,
      onBottlesChanged: () => setState(() {}),
    );
  }

  Future<void> _submit() async {
    if (_selectedClient == null) {
      NotificationService.showInfo(
        context,
        _collectionType == CollectionType.wholesaler
            ? 'Sélectionnez un grossiste'
            : 'Sélectionnez un point de vente',
      );
      return;
    }

    final availableWeights = _getAvailableWeights(ref);
    await CollectionSubmitHandler.submit(
      context: context,
      ref: ref,
      tour: widget.tour,
      collectionType: _collectionType,
      selectedClient: _selectedClient!,
      bottles: _bottles,
      availableWeights: availableWeights,
    );
  }

  /// Récupère les poids disponibles depuis les bouteilles créées.
  List<int> _getAvailableWeights(WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    return cylindersAsync.when(
      data: (cylinders) {
        // Extraire les poids uniques des bouteilles existantes
        final weights = cylinders.map((c) => c.weight).toSet().toList();
        weights.sort();
        return weights;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWeights = _getAvailableWeights(ref);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CollectionFormHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Type de collecte
                      CollectionTypeSelector(
                        selectedType: _collectionType,
                        onTypeChanged: (type) {
                          setState(() {
                            _collectionType = type;
                            _selectedClient = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Sélection client
                      _buildClientSelector(),
                      const SizedBox(height: 16),
                      // Divider
                      Container(
                        height: 1,
                        color: const Color(0xFF000000).withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      // Types de bouteilles collectées
                      Text(
                        'Types de bouteilles collectées',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Liste des bouteilles ajoutées
                      if (_bottles.isNotEmpty) ...[
                        BottleListDisplay(
                          bottles: _bottles,
                          onRemove: _removeBottle,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Formulaire d'ajout
                      BottleQuantityInput(
                        availableWeights: availableWeights,
                        selectedWeight: _selectedWeight,
                        quantityController: _quantityController,
                        onWeightSelected: (weight) {
                          setState(() {
                            _selectedWeight = weight;
                          });
                        },
                        onAdd: _addBottle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FormDialogActions(
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: _submit,
                submitLabel: 'Ajouter',
                submitEnabled: _bottles.isNotEmpty && _selectedClient != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    // Si on est en mode ajout de grossiste, afficher le formulaire
    if (_collectionType == CollectionType.wholesaler && _isAddingNewWholesaler) {
      return _buildNewWholesalerForm();
    }

    final clients = _getAvailableClients(ref);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clients.isEmpty
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucun grossiste trouvé. Ajoutez-en un nouveau.',
                        style: TextStyle(color: Colors.orange[900], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            : ClientSelector(
                selectedClient: _selectedClient,
                clients: clients,
                collectionType: _collectionType,
                onClientSelected: (client) {
                  setState(() {
                    _selectedClient = client;
                  });
                },
              ),
        // Bouton pour ajouter un nouveau grossiste (seulement pour les grossistes)
        if (_collectionType == CollectionType.wholesaler) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isAddingNewWholesaler = true;
                _selectedClient = null;
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
      ],
    );
  }

  Widget _buildNewWholesalerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nouveau grossiste - Les informations seront enregistrées',
                  style: TextStyle(color: Colors.blue[900], fontSize: 12),
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
                    _selectedClient = null;
                  });
                },
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  final name = _wholesalerNameController.text.trim();
                  if (name.isEmpty) {
                    if (context.mounted) {
                      NotificationService.showError(
                        context,
                        'Le nom du grossiste est requis',
                      );
                    }
                    return;
                  }

                  // Générer un ID unique pour le nouveau grossiste
                  final newId = 'wholesaler_${DateTime.now().millisecondsSinceEpoch}';
                  final phone = _wholesalerPhoneController.text.trim();
                  final address = _wholesalerAddressController.text.trim();

                  // Créer le client
                  final newClient = Client(
                    id: newId,
                    name: name,
                    phone: phone,
                    address: address.isNotEmpty ? address : null,
                  );

                  // Ajouter le grossiste au tour
                  await _addWholesalerToTour(
                    widget.tour,
                    newId,
                    name,
                    phone,
                    address,
                  );

                  // Sélectionner le nouveau client
                  setState(() {
                    _selectedClient = newClient;
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                  });

                  if (context.mounted) {
                    NotificationService.showSuccess(
                      context,
                      'Grossiste "$name" ajouté avec succès',
                    );
                  }
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
      ref.invalidate(allWholesalersProvider(widget.tour.enterpriseId));
      ref.invalidate(
        toursProvider((enterpriseId: widget.tour.enterpriseId, status: null)),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'Erreur lors de l\'ajout au tour: $e',
      );
    }
  }
}
