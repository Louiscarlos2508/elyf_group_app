import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import 'collection_form/bottle_list_display.dart';
import 'collection_form/bottle_quantity_input.dart';
import 'collection_form/client_selector.dart';
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
  final List<int> _availableWeights = [3, 6, 10, 12];
  
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
    if (_selectedWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un type de bouteille')),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être supérieure à 0')),
      );
      return;
    }

    setState(() {
      _bottles[_selectedWeight!] = (_bottles[_selectedWeight!] ?? 0) + qty;
      _selectedWeight = null;
      _quantityController.text = '0';
    });
  }

  void _removeBottle(int weight) {
    setState(() {
      _bottles.remove(weight);
    });
  }

  Future<void> _submit() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _collectionType == CollectionType.wholesaler
                ? 'Sélectionnez un grossiste'
                : 'Sélectionnez un point de vente',
          ),
        ),
      );
      return;
    }

    await CollectionSubmitHandler.submit(
      context: context,
      ref: ref,
      tour: widget.tour,
      collectionType: _collectionType,
      selectedClient: _selectedClient!,
      bottles: _bottles,
      availableWeights: _availableWeights,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textGray = const Color(0xFF717182);

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
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter une collecte',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enregistrez les bouteilles vides collectées',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                    color: const Color(0xFF0A0A0A).withValues(alpha: 0.7),
                  ),
                ],
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
                        availableWeights: _availableWeights,
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
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: GazButtonStyles.outlined,
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _bottles.isEmpty || _selectedClient == null
                          ? null
                          : _submit,
                      style: GazButtonStyles.filledPrimary,
                      child: const Text(
                        'Ajouter',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
