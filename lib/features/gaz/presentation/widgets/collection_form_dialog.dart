import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
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
  const CollectionFormDialog({
    super.key,
    required this.tour,
  });

  final Tour tour;

  @override
  ConsumerState<CollectionFormDialog> createState() =>
      _CollectionFormDialogState();
}

class _CollectionFormDialogState
    extends ConsumerState<CollectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  CollectionType _collectionType = CollectionType.wholesaler;
  Client? _selectedClient;
  final Map<int, int> _bottles = {}; // poids -> quantité
  
  // Pour le formulaire d'ajout de bouteille
  int? _selectedWeight;
  final _quantityController = TextEditingController(text: '0');

  // Clients mockés - TODO: Remplacer par un provider
  List<Client> get _availableClients {
    if (_collectionType == CollectionType.wholesaler) {
      return const [
        Client(
          id: 'wholesaler_1',
          name: 'Grossiste 1',
          phone: '+226 70 12 34 56',
          address: '123 Rue du Commerce',
        ),
        Client(
          id: 'wholesaler_2',
          name: 'Grossiste 2',
          phone: '+226 70 12 34 57',
          address: '456 Avenue de la Paix',
        ),
      ];
    } else {
      return const [
        Client(
          id: 'pos_1',
          name: 'Point de vente 1',
          phone: '+226 70 12 34 58',
          address: '123 Rue de la Gaz',
          emptyStock: {12: 15}, // 15 bouteilles de 12kg disponibles
        ),
        Client(
          id: 'pos_2',
          name: 'Point de vente 2',
          phone: '+226 70 12 34 59',
          address: '789 Boulevard Central',
          emptyStock: {}, // Aucune bouteille vide
        ),
      ];
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
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
      NotificationService.showInfo(context, 
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
                      ClientSelector(
                        selectedClient: _selectedClient,
                        clients: _availableClients,
                        collectionType: _collectionType,
                        onClientSelected: (client) {
                          setState(() {
                            _selectedClient = client;
                          });
                        },
                      ),
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
}
