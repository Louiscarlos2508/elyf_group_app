import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/point_of_sale_stock_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/wholesaler.dart';
import 'collection_form/bottle_list_display.dart';
import 'collection_form/bottle_manager.dart';
import 'collection_form/bottle_quantity_input.dart';
import 'collection_form/client_selector.dart';
import 'collection_form/collection_form_header.dart';
import 'collection_form/collection_edit_handler.dart';
import 'collection_form/collection_type_selector.dart';

/// Formulaire d'édition d'une collecte existante.
class CollectionEditDialog extends ConsumerStatefulWidget {
  const CollectionEditDialog({
    super.key,
    required this.tour,
    required this.collection,
  });

  final Tour tour;
  final Collection collection;

  @override
  ConsumerState<CollectionEditDialog> createState() =>
      _CollectionEditDialogState();
}

class _CollectionEditDialogState extends ConsumerState<CollectionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late CollectionType _collectionType;
  Client? _selectedClient;
  late Map<int, int> _bottles; // poids -> quantité

  // Pour le formulaire d'ajout de bouteille
  int? _selectedWeight;
  final _quantityController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    // Initialiser avec les données de la collection existante
    _collectionType = widget.collection.type;
    _bottles = Map<int, int>.from(widget.collection.emptyBottles);
    
    // Créer le client à partir de la collection
    _selectedClient = Client(
      id: widget.collection.clientId,
      name: widget.collection.clientName,
      phone: widget.collection.clientPhone,
      address: widget.collection.clientAddress,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

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
    await CollectionEditHandler.edit(
      context: context,
      ref: ref,
      tour: widget.tour,
      collectionToEdit: widget.collection,
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
              const CollectionFormHeader(
                title: 'Modifier la collecte',
                subtitle: 'Modifiez les informations de la collecte',
              ),
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
                submitLabel: 'Enregistrer',
                submitEnabled: _bottles.isNotEmpty && _selectedClient != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    final clients = _getAvailableClients(ref);
    
    return ClientSelector(
      selectedClient: _selectedClient,
      clients: clients,
      collectionType: _collectionType,
      onClientSelected: (client) {
        setState(() {
          _selectedClient = client;
        });
      },
    );
  }
}
