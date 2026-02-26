import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import 'transport/loading_unloading_fees_section.dart';

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
  
  late final TextEditingController _supplierController;
  late final TextEditingController _gasPurchaseCostController;
  late final TextEditingController _additionalFeesController;
  final Set<int> _expandedWeights = {};
  Map<int, int> _nominalStocks = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _supplierController = TextEditingController(
      text: widget.tour.supplierName ?? '',
    );
    _gasPurchaseCostController = TextEditingController(
      text: widget.tour.gasPurchaseCost?.toStringAsFixed(0) ?? '0',
    );
    _additionalFeesController = TextEditingController(
      text: widget.tour.additionalInvoiceFees.toStringAsFixed(0),
    );
    // Refresh UI on changes
    _gasPurchaseCostController.addListener(() => setState(() {}));
    _additionalFeesController.addListener(() => setState(() {}));
    _supplierController.addListener(() => setState(() {}));
  }

  void _initializeControllers(GazSettings? settings) {
    if (_isInitialized) return;

    final weights = widget.tour.emptyBottlesLoaded.keys.toSet()
      ..addAll(widget.tour.fullBottlesReceived.keys)
      ..addAll(widget.tour.emptyBottlesReturned.keys);

    for (final weight in weights) {
      final loaded = widget.tour.emptyBottlesLoaded[weight] ?? 0;
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
    
    if (settings != null) {
      _nominalStocks = settings.nominalStocks;
    }

    if (_expandedWeights.isEmpty && weights.isNotEmpty) {
      _expandedWeights.add(weights.first);
    }
    
    _isInitialized = true;
  }

  Future<void> _loadSettings(List<int> weights) async {
    final settingsAsync = await ref.read(gazSettingsControllerProvider).getSettings(
          enterpriseId: widget.enterpriseId,
          moduleId: 'gaz',
        );
    if (settingsAsync != null && mounted) {
      setState(() {
        _nominalStocks = settingsAsync.nominalStocks;
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
    for (final c in _receivedControllers.values) c.dispose();
    for (final c in _returnedControllers.values) c.dispose();
    for (final c in _purchasePriceControllers.values) c.dispose();
    for (final c in _exchangeFeeControllers.values) c.dispose();
    _supplierController.dispose();
    _gasPurchaseCostController.dispose();
    _additionalFeesController.dispose();
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
          data: (cylinders) => _buildContent(context, theme, isDark, cylinders, allStocksAsync.value ?? [], settings, isPos),
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

    double totalGasCost = 0;
    for (final weight in weights) {
      final received = int.tryParse(_receivedControllers[weight]?.text ?? '0') ?? 0;
      final price = double.tryParse(_purchasePriceControllers[weight]?.text ?? '0') ?? 0;
      totalGasCost += received * price;
    }
    final additionalFees = double.tryParse(_additionalFeesController.text) ?? 0;
    final theoreticalTotal = totalGasCost + additionalFees;
    final invoiceAmount = double.tryParse(_gasPurchaseCostController.text) ?? 0;
    final gap = theoreticalTotal - invoiceAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            // Supplier & Gas Info Section
            Row(
              children: [
                Icon(Icons.business_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Informations Fournisseur & Facturation',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _supplierController,
                    decoration: InputDecoration(
                      labelText: 'Nom du Fournisseur',
                      hintText: 'Ex: SODIGAZ, Shell...',
                      prefixIcon: const Icon(Icons.business, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _gasPurchaseCostController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Facture',
                      suffixText: 'F',
                      prefixIcon: const Icon(Icons.receipt_long, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _additionalFeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Frais Supp.',
                      hintText: 'TVA, péage...',
                      suffixText: 'F',
                      prefixIcon: const Icon(Icons.add_shopping_cart, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
           const SizedBox(height: 16),
            
            // Financial Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculé (Détails + Frais)', style: theme.textTheme.labelSmall),
                          Text(
                            '${CurrencyFormatter.formatDouble(theoreticalTotal)} F',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(color: theme.colorScheme.primary.withOpacity(0.2)),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Montant Facture', style: theme.textTheme.labelSmall),
                          Text(
                            '${CurrencyFormatter.formatDouble(invoiceAmount)} F',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(color: theme.colorScheme.primary.withOpacity(0.2)),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ÉCART', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${gap == 0 ? "OK" : CurrencyFormatter.formatDouble(gap)} ${gap == 0 ? "" : "F"}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: gap == 0 ? Colors.green : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                 ],
                ),
              ),
            ),
            const SizedBox(height: 24),
           
            // Quantities and Fees Title
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Réconciliation & Acquisition',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Compact table/list
            ...weights.map((weight) {
              final loaded = widget.tour.emptyBottlesLoaded[weight] ?? 0;
              final leakingLoaded = widget.tour.leakingBottlesLoaded[weight] ?? 0;
              final totalLoaded = loaded + leakingLoaded;
              final nominal = _nominalStocks[weight] ?? 0;
              final cylinderId = cylinders.any((c) => c.weight == weight) 
                  ? cylinders.firstWhere((c) => c.weight == weight).id 
                  : '';
              
              final currentFull = allStocks
                  .where((CylinderStock s) => s.cylinderId == cylinderId && s.status == CylinderStatus.full)
                  .fold<int>(0, (int sum, CylinderStock s) => sum + s.quantity);
              
              final currentEmpty = allStocks
                  .where((CylinderStock s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyAtStore)
                  .fold<int>(0, (int sum, CylinderStock s) => sum + s.quantity);

              final received = int.tryParse(_receivedControllers[weight]?.text ?? '0') ?? 0;
              final returned = int.tryParse(_returnedControllers[weight]?.text ?? '0') ?? 0;
              final totalWithReception = currentFull + currentEmpty + received + returned;
              final isExpanded = _expandedWeights.contains(weight);

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
                      'Chargé: $loaded vides + $leakingLoaded fuites',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Local Subtotal
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
                           if (nominal > 0 && !isPos) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Capacité Cible : $nominal btl',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    Text(
                                      'Réel (Audit) : $totalWithReception/$nominal',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: (totalWithReception > nominal + 2) // small tolerance
                                            ? theme.colorScheme.error 
                                            : (totalWithReception >= nominal - 2 ? theme.colorScheme.primary : theme.colorScheme.secondary),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
                
            const SizedBox(height: 24),
            
            FilledButton.icon(
              onPressed: () => _saveReception(weights),
              icon: const Icon(Icons.check_circle_outlined, size: 18),
              label: const Text('Valider la réception'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
        supplierName: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
        gasPurchaseCost: double.tryParse(_gasPurchaseCostController.text) ?? 0,
        additionalInvoiceFees: double.tryParse(_additionalFeesController.text) ?? 0,
        fullBottlesReceived: fullBottles,
        emptyBottlesReturned: returnedEmpties,
        purchasePricesUsed: purchasePrices,
        updatedAt: DateTime.now(),
     );
      
      await controller.updateTour(updatedTour);

      if (mounted) {
        NotificationService.showSuccess(context, 'Réception et Réconciliation enregistrées');
        ref.invalidate(tourProvider(widget.tour.id));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
