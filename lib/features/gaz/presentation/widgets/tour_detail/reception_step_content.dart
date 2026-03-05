import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/core/utils/local_id_generator.dart';

/// Contenu de l'étape Réception du tour.
///
/// Permet de saisir les bouteilles pleines reçues du fournisseur
/// et le coût d'achat du gaz.
class ReceptionStepContent extends ConsumerStatefulWidget {
  const ReceptionStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
    this.onSaved,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ReceptionStepContent> createState() =>
      _ReceptionStepContentState();
}

class _ReceptionStepContentState extends ConsumerState<ReceptionStepContent> {
  final Map<int, TextEditingController> _receivedControllers = {}; // Qté Pleines
  final Map<int, TextEditingController> _returnedControllers = {}; // Qté Vides ramenés
  final Map<int, TextEditingController> _purchasePriceControllers = {}; // Prix achat Unitaire
  final Map<int, TextEditingController> _exchangeFeeControllers = {}; // Frais échange
  
  // Wholesaler Distribution state
  final List<WholesaleDistribution> _wholesaleDistributions = [];
  final Map<String, Map<int, TextEditingController>> _wholesalerQtyControllers = {};
  final Map<String, TextEditingController> _wholesalerAmountControllers = {};

  // POS Distribution state
  final List<PosDistribution> _posDistributions = [];
  final Map<String, Map<int, TextEditingController>> _posQtyControllers = {};

  final Set<int> _expandedWeights = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }



  void _initializeControllers(GazSettings? settings) {
    if (_isInitialized) return;

    final weights = widget.tour.emptyBottlesLoaded.keys.toSet()
      ..addAll(widget.tour.fullBottlesReceived.keys)
      ..addAll(widget.tour.emptyBottlesReturned.keys);

    // Initialize Reception fields
    for (final weight in weights) {
      final received = widget.tour.fullBottlesReceived[weight] ?? 0;
      final returned = widget.tour.emptyBottlesReturned[weight] ?? 0;

      _receivedControllers[weight] = TextEditingController(text: received.toString());
      _returnedControllers[weight] = TextEditingController(text: returned.toString());
      
      final defaultPurchase = settings?.purchasePrices[weight] ?? 0.0;
      _purchasePriceControllers[weight] = TextEditingController(
        text: (widget.tour.purchasePricesUsed[weight] ?? defaultPurchase).toStringAsFixed(0),
      );

      final defaultExchange = settings?.supplierExchangeFees[weight] ?? 0.0;
      _exchangeFeeControllers[weight] = TextEditingController(
        text: (widget.tour.exchangeFees[weight] ?? defaultExchange).toStringAsFixed(0),
      );
    }

    // Initialize Wholesaler Distributions
    if (widget.tour.wholesaleDistributions.isNotEmpty) {
      _wholesaleDistributions.addAll(widget.tour.wholesaleDistributions);
    } else {
      // Pre-fill from loading sources if it's the first time
      for (final source in widget.tour.loadingSources) {
        if (!source.isPos) {
          _wholesaleDistributions.add(WholesaleDistribution(
            wholesalerId: source.sourceId,
            wholesalerName: source.sourceName,
            quantities: Map.from(source.quantities),
            totalAmount: 0,
            paymentMethod: PaymentMethod.cash,
          ));
        }
      }
    }

    // Initialize POS Distributions
    if (widget.tour.posDistributions.isNotEmpty) {
      _posDistributions.addAll(widget.tour.posDistributions);
    } else {
      for (final source in widget.tour.loadingSources) {
        if (source.isPos) {
          _posDistributions.add(PosDistribution(
            posId: source.sourceId,
            posName: source.sourceName,
            quantities: Map.from(source.quantities),
          ));
        }
      }
    }

    // Setup controllers for distributions
    _setupDistributionControllers(settings);

    if (_expandedWeights.isEmpty && weights.isNotEmpty) {
      _expandedWeights.add(weights.first);
    }
    
    _isInitialized = true;
  }

  void _setupDistributionControllers(GazSettings? settings) {
    for (final dist in _wholesaleDistributions) {
      final qControllers = <int, TextEditingController>{};
      double total = 0;
      for (final weight in dist.quantities.keys) {
        final qty = dist.quantities[weight] ?? 0;
        qControllers[weight] = TextEditingController(text: qty.toString());
        
        final price = settings?.wholesalePrices[weight] ?? 0.0;
        total += qty * price;
      }
      _wholesalerQtyControllers[dist.wholesalerId] = qControllers;
      
      final currentAmount = dist.totalAmount > 0 ? dist.totalAmount : total;
      _wholesalerAmountControllers[dist.wholesalerId] = TextEditingController(
        text: currentAmount.toStringAsFixed(0),
      );
    }

    for (final dist in _posDistributions) {
      final qControllers = <int, TextEditingController>{};
      for (final weight in dist.quantities.keys) {
        qControllers[weight] = TextEditingController(text: (dist.quantities[weight] ?? 0).toString());
      }
      _posQtyControllers[dist.posId] = qControllers;
    }
  }

  Future<void> _loadSettings(List<int> weights) async {
    final settingsAsync = await ref.read(gazSettingsControllerProvider(widget.enterpriseId)).getSettings(
          enterpriseId: widget.enterpriseId,
          moduleId: 'gaz',
        );
    if (settingsAsync != null && mounted) {
      setState(() {
        for (final weight in weights) {
          final purchasePrice = settingsAsync.getPurchasePrice(weight);
          final fee = purchasePrice ?? settingsAsync.getSupplierExchangeFee(weight);
          if (fee != null && fee > 0) {
            final controller = _exchangeFeeControllers[weight];
            if (controller != null && (controller.text == '0' || controller.text == '0.0')) {
              controller.text = fee.toStringAsFixed(0);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _receivedControllers.values) {
      c.dispose();
    }
    for (final c in _returnedControllers.values) {
      c.dispose();
    }
    for (final c in _purchasePriceControllers.values) {
      c.dispose();
    }
    for (final c in _exchangeFeeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cylindersAsync = ref.watch(cylindersProvider);
    final allStocksAsync = ref.watch(cylinderStocksProvider((
      enterpriseId: widget.enterpriseId,
      status: null,
      siteId: null,
    )));
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: widget.enterpriseId,
      moduleId: 'gaz',
    )));

    return settingsAsync.when(
      data: (settings) {
        _initializeControllers(settings);
        final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
        final isPos = activeEnterprise?.id == widget.enterpriseId && (activeEnterprise?.isPointOfSale ?? false);
        return cylindersAsync.when(
          data: (cylinders) => _buildContent(
            context,
            theme,
            isDark,
            cylinders,
            allStocksAsync.value ?? [],
            settings,
            isPos,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur Cylindres: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur Settings: $e')),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    ThemeData theme, 
    bool isDark, 
    List<Cylinder> cylinders, 
    List<CylinderStock> allStocks,
    GazSettings? settings,
    bool isPos,
  ) {
    final weights = widget.tour.emptyBottlesLoaded.keys.toSet().toList()..sort();
    
    if (weights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text('Aucune bouteille chargée dans ce tour.'),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Réception fournisseur (Existing)
          _buildReceptionSection(theme, isDark, cylinders, allStocks),
          
          const SizedBox(height: 24),
          
          // 2. Encaissement Grossistes
          _buildWholesaleSection(theme, isDark, settings),
          
          const SizedBox(height: 24),
          
          // 3. Distribution Points de Vente
          _buildPosSection(theme, isDark),
          
          const SizedBox(height: 32),
          
          FilledButton.icon(
            onPressed: () => _saveReception(weights),
            icon: const Icon(Icons.check_circle_outlined, size: 20),
            label: const Text('Valider le retour & les encaissements'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReceptionSection(ThemeData theme, bool isDark, List<Cylinder> cylinders, List<CylinderStock> allStocks) {
    final weights = widget.tour.emptyBottlesLoaded.keys.toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Réconciliation Fournisseur',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...weights.map((weight) => _buildWeightItem(weight, theme, isDark, cylinders, allStocks)),
      ],
    );
  }

  Widget _buildWeightItem(int weight, ThemeData theme, bool isDark, List<Cylinder> cylinders, List<CylinderStock> allStocks) {
    final loaded = widget.tour.emptyBottlesLoaded[weight] ?? 0;
    final totalLoaded = loaded;
    final isExpanded = _expandedWeights.contains(weight);
    final received = int.tryParse(_receivedControllers[weight]?.text ?? '0') ?? 0;
    final returned = int.tryParse(_returnedControllers[weight]?.text ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withOpacity(0.5)
              : (isDark ? theme.colorScheme.outline.withOpacity(0.1) : theme.colorScheme.outlineVariant),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedWeights.add(weight);
              } else {
                _expandedWeights.remove(weight);
              }
            });
          },
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$weight kg',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            'Chargé: $loaded vides',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Reçu: $received | Ramenés: $returned',
            style: theme.textTheme.labelSmall?.copyWith(
              color: (received + returned) == totalLoaded 
                  ? (isDark ? Colors.greenAccent : Colors.green)
                  : (received + returned > totalLoaded ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
              fontWeight: (received + returned) == totalLoaded ? FontWeight.bold : null,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _receivedControllers[weight],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Reçu Plein',
                            suffixText: 'btl',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            final r = int.tryParse(val) ?? 0;
                            final suggeredReturn = (totalLoaded - r).clamp(0, 1000).toInt();
                            _returnedControllers[weight]?.text = suggeredReturn.toString();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _returnedControllers[weight],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Vide Ramené',
                            suffixText: 'btl',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceControllers[weight],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prix Achat Unitaire',
                            suffixText: 'F',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Sous-total: ${CurrencyFormatter.formatDouble(received * (double.tryParse(_purchasePriceControllers[weight]?.text ?? '0') ?? 0))} F',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWholesaleSection(ThemeData theme, bool isDark, GazSettings? settings) {
    if (_wholesaleDistributions.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.payments_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Encaissements Grossistes',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._wholesaleDistributions.map((dist) => _buildWholesalerCard(dist, theme, isDark, settings)),
      ],
    );
  }

  Widget _buildWholesalerCard(WholesaleDistribution dist, ThemeData theme, bool isDark, GazSettings? settings) {
    final controllers = _wholesalerQtyControllers[dist.wholesalerId] ?? {};
    final amountController = _wholesalerAmountControllers[dist.wholesalerId];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person_outline, size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  dist.wholesalerName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quantities
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dist.quantities.keys.map((weight) {
                return SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: controllers[weight],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$weight kg',
                      suffixText: 'btl',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) {
                      final qty = int.tryParse(val) ?? 0;
                      _updateWholesaleAmount(dist.wholesalerId, settings);
                      setState(() {});
                    },
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Méthode de Paiement', style: theme.textTheme.labelSmall),
                      DropdownButton<PaymentMethod>(
                        value: dist.paymentMethod,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: PaymentMethod.values.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              final index = _wholesaleDistributions.indexOf(dist);
                              _wholesaleDistributions[index] = WholesaleDistribution(
                                wholesalerId: dist.wholesalerId,
                                wholesalerName: dist.wholesalerName,
                                quantities: dist.quantities,
                                totalAmount: dist.totalAmount,
                                paymentMethod: val,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      labelText: 'Montant Reçu',
                      suffixText: 'F',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.primary.withOpacity(0.05),
                    ),
                    onChanged: (val) {
                       final amount = double.tryParse(val) ?? 0;
                       final index = _wholesaleDistributions.indexOf(dist);
                       _wholesaleDistributions[index] = WholesaleDistribution(
                          wholesalerId: dist.wholesalerId,
                          wholesalerName: dist.wholesalerName,
                          quantities: dist.quantities,
                          totalAmount: amount,
                          paymentMethod: dist.paymentMethod,
                        );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateWholesaleAmount(String wholesalerId, GazSettings? settings) {
    final controllers = _wholesalerQtyControllers[wholesalerId] ?? {};
    final amountController = _wholesalerAmountControllers[wholesalerId];
    if (amountController == null) return;

    double total = 0;
    controllers.forEach((weight, controller) {
      final qty = int.tryParse(controller.text) ?? 0;
      final price = settings?.wholesalePrices[weight] ?? 0.0;
      total += qty * price;
    });

    amountController.text = total.toStringAsFixed(0);
    
    // Update the record in the list as well
    final index = _wholesaleDistributions.indexWhere((d) => d.wholesalerId == wholesalerId);
    if (index != -1) {
      final dist = _wholesaleDistributions[index];
      _wholesaleDistributions[index] = WholesaleDistribution(
        wholesalerId: dist.wholesalerId,
        wholesalerName: dist.wholesalerName,
        quantities: controllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0)),
        totalAmount: total,
        paymentMethod: dist.paymentMethod,
      );
    }
  }

  Widget _buildPosSection(ThemeData theme, bool isDark) {
    if (_posDistributions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.storefront_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Distribution Points de Vente',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._posDistributions.map((dist) => _buildPosCard(dist, theme, isDark)),
      ],
    );
  }

  Widget _buildPosCard(PosDistribution dist, ThemeData theme, bool isDark) {
    final controllers = _posQtyControllers[dist.posId] ?? {};

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dist.posName,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dist.quantities.keys.map((weight) {
                return SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: controllers[weight],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$weight kg',
                      suffixText: 'btl',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) {
                      setState(() {
                         final index = _posDistributions.indexOf(dist);
                         _posDistributions[index] = PosDistribution(
                           posId: dist.posId,
                           posName: dist.posName,
                           quantities: controllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0)),
                           receivedDate: dist.receivedDate,
                         );
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _saveReception(List<int> weights) async {
    final fullBottles = <int, int>{};
    final returnedEmpties = <int, int>{};
    final purchasePrices = <int, double>{};
    final exchangeFees = <int, double>{};

    for (final weight in weights) {
      final received = int.tryParse(_receivedControllers[weight]?.text ?? '') ?? 0;
      if (received >= 0) fullBottles[weight] = received;
      
      final returned = int.tryParse(_returnedControllers[weight]?.text ?? '') ?? 0;
      if (returned >= 0) returnedEmpties[weight] = returned;

      final price = double.tryParse(_purchasePriceControllers[weight]?.text ?? '') ?? 0.0;
      if (price >= 0) purchasePrices[weight] = price;

      final fee = double.tryParse(_exchangeFeeControllers[weight]?.text ?? '') ?? 0.0;
      if (fee >= 0) exchangeFees[weight] = fee;
      

    }

    try {
      final controller = ref.read(tourControllerProvider);
      
      final updatedTour = widget.tour.copyWith(
        fullBottlesReceived: fullBottles,
        emptyBottlesReturned: returnedEmpties,
        purchasePricesUsed: purchasePrices,
        wholesaleDistributions: _wholesaleDistributions,
        posDistributions: _posDistributions,
        receptionCompletedDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await controller.updateTour(updatedTour);



      if (mounted) {
        NotificationService.showSuccess(context, 'Réception enregistrée');
        ref.invalidate(tourProvider(widget.tour.id));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
