import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../domain/entities/cylinder_stock.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/wholesaler.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../collection_form/bottle_list_display.dart';
import '../collection_form/bottle_manager.dart';
import '../collection_form/bottle_quantity_input.dart';
import '../collection_form/client_selector.dart';
import '../collection_form/collection_type_selector.dart';
import '../../../../../../core/auth/providers.dart';

/// Formulaire d'ajout d'une collecte indépendante (Wholesale/POS).
class IndependentCollectionDialog extends ConsumerStatefulWidget {
  const IndependentCollectionDialog({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  ConsumerState<IndependentCollectionDialog> createState() =>
      _IndependentCollectionDialogState();
}

class _IndependentCollectionDialogState extends ConsumerState<IndependentCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  CollectionType _collectionType = CollectionType.pointOfSale;
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
  bool _isSubmitting = false;

  /// Récupère les clients disponibles depuis la base de données.
  List<Client> _getAvailableClients(WidgetRef ref) {
    if (_collectionType == CollectionType.wholesaler) {
      // Récupérer les grossistes depuis la base de données
      final wholesalersAsync = ref.watch(
        allWholesalersProvider(widget.enterpriseId),
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
        enterprisesByParentAndTypeProvider((
          parentId: widget.enterpriseId,
          type: EnterpriseType.gasPointOfSale,
        )),
      );
      return pointsOfSaleAsync.when(
        data: (pointsOfSale) {
          return pointsOfSale
              .map(
                (pos) {
                  // Récupérer le stock réel du point de vente
                  final stockAsync = ref.watch(cylinderStocksProvider((
                    enterpriseId: widget.enterpriseId,
                    status: null,
                    siteId: pos.id,
                  )));
                  final stockList = stockAsync.value ?? [];
                  final stockInt = <int, int>{};
                  for (final item in stockList) {
                    if ((item.status == CylinderStatus.emptyAtStore || item.status == CylinderStatus.emptyInTransit) && item.weight != null) {
                       stockInt[item.weight!] = (stockInt[item.weight!] ?? 0) + item.quantity;
                    }
                  }

                  return Client(
                    id: pos.id,
                    name: pos.name,
                    phone: pos.phone ?? '',
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

    if (_bottles.isEmpty) {
      NotificationService.showInfo(
        context,
        'Ajoutez au moins une bouteille',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authController = ref.read(authControllerProvider);
      final userId = authController.currentUser?.id ?? 'system';

      // Créer l'objet collection
      final collection = Collection(
        id: 'indep_col_${DateTime.now().millisecondsSinceEpoch}',
        type: _collectionType,
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        clientPhone: _selectedClient!.phone,
        clientAddress: _selectedClient!.address,
        emptyBottles: _bottles,
        unitPrice: 0, // Géré par transaction
        amountPaid: 0, // Pour l'instant, on suppose paiement manuel ou séparé.
        // TODO: Ajouter un champ "Montant Payé" si nécessaire dans le futur
        paymentDate: DateTime.now(),
      );

      final transactionService = ref.read(transactionServiceProvider);
      await transactionService.executeIndependentCollectionTransaction(
        collection: collection,
        enterpriseId: widget.enterpriseId,
        userId: userId,
      );

      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        'Collecte enregistrée avec succès',
      );

      // Invalider les providers
      ref.invalidate(gasSalesProvider);
      ref.invalidate(cylinderStocksProvider((
          enterpriseId: widget.enterpriseId,
          status: null,
          siteId: null,
      )));

      Navigator.of(context).pop();

    } catch (e, stackTrace) {
      if (!mounted) return;
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.error(
          'Erreur lors de l\'enregistrement de la collecte: ${appException.message}',
          name: 'gaz.independent_collection',
          error: e,
          stackTrace: stackTrace,
        );
        NotificationService.showError(
          context,
          ErrorHandler.instance.getUserMessage(appException),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              Text(
                'Nouvelle Collecte',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Type de collecte (Masqué ou simplifié car seulement POS maintenant)
                      /* 
                      CollectionTypeSelector(
                        selectedType: _collectionType,
                        onTypeChanged: (type) {
                          setState(() {
                            _collectionType = type;
                            _selectedClient = null;
                          });
                        },
                      ),
                      */
                      Text(
                        'Source de collecte : Point de Vente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
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
                        'Bouteilles à collecter (Vides)',
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
                submitEnabled: !_isSubmitting && _bottles.isNotEmpty && _selectedClient != null,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    final clients = _getAvailableClients(ref);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (clients.isEmpty)
            Container(
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
                        'Aucun point de vente trouvé.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ClientSelector(
                selectedClient: _selectedClient,
                clients: clients,
                collectionType: _collectionType,
                onClientSelected: (client) {
                  setState(() {
                    _selectedClient = client;
                  });
                },
              ),
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
                  'Nouveau grossiste - Sera enregistré dans la base de données',
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
              child: ElyfButton(
                onPressed: () {
                  setState(() {
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                    _selectedClient = null;
                  });
                },
                variant: ElyfButtonVariant.outlined,
                width: double.infinity,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElyfButton(
                onPressed: () async {
                  final name = _wholesalerNameController.text.trim();
                  if (name.isEmpty) {
                    if (mounted) {
                      NotificationService.showError(
                        context,
                        'Le nom du grossiste est requis',
                      );
                    }
                    return;
                  }

                  // Générer un ID unique temporaire (le repo le gérera mieux normalement mais ici on en a besoin pour l'UI)
                  final newId = 'wholesaler_${DateTime.now().millisecondsSinceEpoch}';
                  final phone = _wholesalerPhoneController.text.trim();
                  final address = _wholesalerAddressController.text.trim();

                  final newWholesaler = Wholesaler(
                    id: newId,
                    enterpriseId: widget.enterpriseId,
                    name: name,
                    phone: phone,
                    address: address.isNotEmpty ? address : null,
                    tier: 'default',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  // Appeler le repository pour créer le grossiste
                  try {
                    final repo = ref.read(wholesalerRepositoryProvider);
                    await repo.createWholesaler(newWholesaler);
                    
                    // Invalider le provider pour rafraîchir la liste
                    ref.invalidate(allWholesalersProvider(widget.enterpriseId));
                  } catch (e) {
                     if (mounted) {
                      NotificationService.showError(
                        context,
                        'Erreur lors de la création du grossiste: $e',
                      );
                    }
                    return;
                  }

                  // Sélectionner le nouveau client
                  final newClient = Client(
                    id: newId,
                    name: name,
                    phone: phone,
                    address: address.isNotEmpty ? address : null,
                  );

                  setState(() {
                    _selectedClient = newClient;
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                  });

                  if (mounted) {
                    NotificationService.showSuccess(
                      context,
                      'Grossiste "$name" ajouté avec succès',
                    );
                  }
                },
                width: double.infinity,
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
