import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/wholesaler.dart';
import '../../../domain/entities/cylinder_stock.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/collection.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../collection_form/bottle_list_display.dart';
import '../collection_form/bottle_manager.dart';
import '../collection_form/bottle_quantity_input.dart';
import '../collection_form/client_selector.dart';
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
  final CollectionType _collectionType = CollectionType.pointOfSale;
  Client? _selectedClient;
  final Map<int, int> _bottles = {}; // poids -> quantité

  // Pour le formulaire d'ajout de bouteille
  int? _selectedWeight;
  final _quantityController = TextEditingController(text: '0');

  // Pour le formulaire d'ajout de fuites
  final Map<int, int> _leaks = {}; // poids -> quantité de fuites
  int? _selectedLeakWeight;
  final _leakQuantityController = TextEditingController(text: '0');

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
                  final emptyStockInt = <int, int>{};
                  final fullStockInt = <int, int>{};
                  final leakStockInt = <int, int>{};

                  for (final item in stockList) {
                    if (item.status == CylinderStatus.emptyAtStore) {
                       emptyStockInt[item.weight] = (emptyStockInt[item.weight] ?? 0) + item.quantity;
                    } else if (item.status == CylinderStatus.full) {
                       fullStockInt[item.weight] = (fullStockInt[item.weight] ?? 0) + item.quantity;
                    } else if (item.status == CylinderStatus.leak) {
                       leakStockInt[item.weight] = (leakStockInt[item.weight] ?? 0) + item.quantity;
                    }
                  }

                  return Client(
                    id: pos.id,
                    name: pos.name,
                    phone: pos.phone ?? '',
                    address: pos.address,
                    emptyStock: emptyStockInt,
                    fullStock: fullStockInt,
                    leakStock: leakStockInt,
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
    _leakQuantityController.dispose();
    super.dispose();
  }

  void _addBottle() {
    BottleManager.addBottle(
      context: context,
      selectedWeight: _selectedWeight,
      quantityText: _quantityController.text,
      bottles: _bottles,
      maxQuantity: _selectedClient?.emptyStock[_selectedWeight ?? -1] ?? 0,
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

  void _addLeak() {
    BottleManager.addBottle(
      context: context,
      selectedWeight: _selectedLeakWeight,
      quantityText: _leakQuantityController.text,
      bottles: _leaks,
      maxQuantity: // Physical stock available for collection as leaks (Leak + Full + Empty)
                    (_selectedClient?.leakStock[_selectedLeakWeight ?? -1] ?? 0) +
                    (_selectedClient?.fullStock[_selectedLeakWeight ?? -1] ?? 0) + 
                    (_selectedClient?.emptyStock[_selectedLeakWeight ?? -1] ?? 0),
      onBottlesChanged: () {
        setState(() {
          _selectedLeakWeight = null;
          _leakQuantityController.text = '0';
        });
      },
    );
  }

  void _removeLeak(int weight) {
    BottleManager.removeBottle(
      weight: weight,
      bottles: _leaks,
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
        leaks: _leaks,
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
                      // Section: Client
                      _buildClientSelector(),
                      const SizedBox(height: 16),
                      
                      // Section: Collected Bottles
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Bouteilles à collecter (Vides)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_bottles.isNotEmpty) ...[
                                BottleListDisplay(
                                  bottles: _bottles,
                                  onRemove: _removeBottle,
                                ),
                                const SizedBox(height: 8),
                              ],
                      // Formulaire d'ajout
                              BottleQuantityInput(
                                availableWeights: availableWeights,
                                selectedWeight: _selectedWeight,
                                maxQuantity: _selectedClient?.emptyStock[_selectedWeight ?? -1],
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
                      
                      // Section: Leaks
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Fuites (Bouteilles défectueuses)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_leaks.isNotEmpty) ...[
                                BottleListDisplay(
                                  bottles: _leaks,
                                  onRemove: _removeLeak,
                                ),
                                const SizedBox(height: 8),
                              ],
                              BottleQuantityInput(
                                availableWeights: availableWeights,
                                selectedWeight: _selectedLeakWeight,
                                maxQuantity: (_selectedClient?.fullStock[_selectedLeakWeight ?? -1] ?? 0) + 
                                             (_selectedClient?.leakStock[_selectedLeakWeight ?? -1] ?? 0) +
                                             (_selectedClient?.emptyStock[_selectedLeakWeight ?? -1] ?? 0),
                                quantityController: _leakQuantityController,
                                onWeightSelected: (weight) {
                                  setState(() {
                                    _selectedLeakWeight = weight;
                                  });
                                },
                                onAdd: _addLeak,
                              ),
                            ],
                          ),
                        ),
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
    final theme = Theme.of(context);
    final clients = _getAvailableClients(ref);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (clients.isEmpty)
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.errorContainer),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucun point de vente trouvé.',
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
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

}
