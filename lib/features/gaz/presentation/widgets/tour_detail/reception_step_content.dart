import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Contenu de l'étape Réception du tour.
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
  final Map<int, TextEditingController> _receivedControllers = {};
  final Map<int, TextEditingController> _returnedControllers = {};
  final Map<int, TextEditingController> _purchasePriceControllers = {};
  final Map<int, TextEditingController> _exchangeFeeControllers = {};
  
  final List<WholesaleDistribution> _wholesaleDistributions = [];
  final Map<String, Map<int, TextEditingController>> _wholesalerQtyControllers = {};
  final Map<String, TextEditingController> _wholesalerAmountControllers = {};

  final List<PosDistribution> _posDistributions = [];
  final Map<String, Map<int, TextEditingController>> _posQtyControllers = {};

  bool _isInitialized = false;

  @override
  void dispose() {
    for (final c in _receivedControllers.values) c.dispose();
    for (final c in _returnedControllers.values) c.dispose();
    for (final c in _purchasePriceControllers.values) c.dispose();
    for (final c in _exchangeFeeControllers.values) c.dispose();
    for (final m in _wholesalerQtyControllers.values) {
      for (final c in m.values) c.dispose();
    }
    for (final c in _wholesalerAmountControllers.values) c.dispose();
    for (final m in _posQtyControllers.values) {
      for (final c in m.values) c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ReceptionStepContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tour.wholesaleDistributions != oldWidget.tour.wholesaleDistributions || 
        widget.tour.posDistributions != oldWidget.tour.posDistributions) {
      _syncDistributionsWithTour();
    }
  }

  void _syncDistributionsWithTour() {
    // Wholesalers
    for (final tourDist in widget.tour.wholesaleDistributions) {
      final index = _wholesaleDistributions.indexWhere((d) => d.wholesalerId == tourDist.wholesalerId);
      if (index != -1) {
        setState(() {
          _wholesaleDistributions[index] = tourDist;
          _wholesalerAmountControllers[tourDist.wholesalerId]?.text = tourDist.totalAmount.toStringAsFixed(0);
          for (final weight in tourDist.quantities.keys) {
            _wholesalerQtyControllers[tourDist.wholesalerId]?[weight]?.text = tourDist.quantities[weight].toString();
          }
        });
      }
    }
    // POS
    for (final tourDist in widget.tour.posDistributions) {
      final index = _posDistributions.indexWhere((d) => d.posId == tourDist.posId);
      if (index != -1) {
        setState(() {
          _posDistributions[index] = tourDist;
          for (final weight in tourDist.quantities.keys) {
            _posQtyControllers[tourDist.posId]?[weight]?.text = tourDist.quantities[weight].toString();
          }
        });
      }
    }
  }

  void _initializeControllers(GazSettings? settings) {
    if (_isInitialized) return;

    final weights = widget.tour.emptyBottlesLoaded.keys.toSet()
      ..addAll(widget.tour.fullBottlesReceived.keys)
      ..addAll(widget.tour.emptyBottlesReturned.keys);

    for (final weight in weights) {
      _receivedControllers[weight] = TextEditingController(text: (widget.tour.fullBottlesReceived[weight] ?? 0).toString());
      _returnedControllers[weight] = TextEditingController(text: (widget.tour.emptyBottlesReturned[weight] ?? 0).toString());
      
      final defaultPurchase = settings?.purchasePrices[weight] ?? 0.0;
      _purchasePriceControllers[weight] = TextEditingController(
        text: (widget.tour.purchasePricesUsed[weight] ?? defaultPurchase).toStringAsFixed(0),
      );

      final defaultExchange = settings?.supplierExchangeFees[weight] ?? 0.0;
      _exchangeFeeControllers[weight] = TextEditingController(
        text: (widget.tour.exchangeFees[weight] ?? defaultExchange).toStringAsFixed(0),
      );
    }

    if (widget.tour.wholesaleDistributions.isNotEmpty) {
      _wholesaleDistributions.addAll(widget.tour.wholesaleDistributions);
    } else {
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

    _setupDistributionControllers(settings);
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

  Map<int, String> _getWeightToCylinderId(List<Cylinder> cylinders) {
    final map = <int, String>{};
    for (final weight in widget.tour.emptyBottlesLoaded.keys) {
      final cylinder = cylinders.where((c) => c.weight == weight).firstOrNull ?? 
                      cylinders.first;
      map[weight] = cylinder.id;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cylindersAsync = ref.watch(cylindersProvider);
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: widget.enterpriseId,
      moduleId: 'gaz',
    )));

    return settingsAsync.when(
      data: (settings) {
        _initializeControllers(settings);
        return cylindersAsync.when(
          data: (cylinders) => _buildContent(context, theme, isDark, cylinders, settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur Settings: $e')),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark, List<Cylinder> cylinders, GazSettings? settings) {
    final weights = widget.tour.emptyBottlesLoaded.keys.toList()..sort();
    if (weights.isEmpty) return const Center(child: Text('Aucune bouteille chargée.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStockSummary(theme, isDark),
        const SizedBox(height: 16),
        _buildWholesaleSection(theme, isDark, settings, cylinders),
        const SizedBox(height: 16),
        _buildPosSection(theme, isDark),
        const SizedBox(height: 24),
        _buildFinalActionButton(theme, isDark),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStockSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé du Tour', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Saisissez les retours et validez les encaissements collectés.', 
                     style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalActionButton(ThemeData theme, bool isDark) {
    return FilledButton.icon(
      onPressed: () => _saveReception(),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('FINALISER LE RETOUR DU TOUR'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    );
  }

  Widget _buildWholesaleSection(ThemeData theme, bool isDark, GazSettings? settings, List<Cylinder> cylinders) {
    if (_wholesaleDistributions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business_center, color: theme.colorScheme.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Encaissements Grossistes', 
                 style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ..._wholesaleDistributions.map((dist) => _buildWholesalerCard(dist, theme, isDark, settings, cylinders)),
      ],
    );
  }

  Widget _buildWholesalerCard(WholesaleDistribution dist, ThemeData theme, bool isDark, GazSettings? settings, List<Cylinder> cylinders) {
    final controllers = _wholesalerQtyControllers[dist.wholesalerId] ?? {};
    final amountController = _wholesalerAmountControllers[dist.wholesalerId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [theme.colorScheme.surface, theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)]
              : [theme.colorScheme.surface, theme.colorScheme.surfaceContainerLowest],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dist.wholesalerName, 
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                  if (dist.isProcessed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text('Encaissé', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Compact Read-Only summary for Wholesaler
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: dist.quantities.entries.where((e) => e.value > 0).map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.propane_tank_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('${e.key}kg:', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 4),
                      Text('${e.value} btl', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),
              const Divider(height: 16),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: dist.paymentMethod,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
                          items: PaymentMethod.values.map((m) => DropdownMenuItem(
                            value: m, 
                            child: Row(
                              children: [
                                Icon(_getPaymentIcon(m), size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(m.label, style: theme.textTheme.bodySmall),
                              ],
                            )
                          )).toList(),
                          onChanged: dist.isProcessed ? null : (val) {
                            if (val != null) _updateWholesaleDistributionState(dist.wholesalerId, paymentMethod: val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      enabled: !dist.isProcessed,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      decoration: InputDecoration(
                        labelText: 'Montant',
                        suffixText: 'F',
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                      ),
                      onChanged: (val) => _updateWholesaleDistributionState(dist.wholesalerId, totalAmount: double.tryParse(val) ?? 0),
                    ),
                  ),
                ],
              ),
              if (!dist.isProcessed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _saveIndividualWholesaler(dist.wholesalerId, cylinders),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: Text('VALIDER L\'ENCAISSEMENT'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.mobileMoney: return Icons.smartphone;
      case PaymentMethod.both: return Icons.payments;
      case PaymentMethod.credit: return Icons.timer_outlined;
    }
  }

  void _updateWholesaleDistributionState(String wholesalerId, {double? totalAmount, PaymentMethod? paymentMethod, Map<int, int>? quantities}) {
    final index = _wholesaleDistributions.indexWhere((d) => d.wholesalerId == wholesalerId);
    if (index != -1) {
      setState(() {
        _wholesaleDistributions[index] = _wholesaleDistributions[index].copyWith(
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
          quantities: quantities,
        );
      });
    }
  }

  void _updateWholesaleAmount(String wholesalerId, GazSettings? settings) {
    final controllers = _wholesalerQtyControllers[wholesalerId] ?? {};
    final amountController = _wholesalerAmountControllers[wholesalerId];
    if (amountController == null) return;

    double total = 0;
    controllers.forEach((weight, controller) {
      final qty = int.tryParse(controller.text) ?? 0;
      total += qty * (settings?.wholesalePrices[weight] ?? 0.0);
    });
    amountController.text = total.toStringAsFixed(0);
    _updateWholesaleDistributionState(wholesalerId, totalAmount: total, quantities: controllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0)));
  }

  Future<void> _saveIndividualWholesaler(String wholesalerId, List<Cylinder> cylinders) async {
    try {
      final controller = ref.read(tourControllerProvider);
      final userId = ref.read(currentUserIdProvider);
      
      final updatedTour = widget.tour.copyWith(wholesaleDistributions: _wholesaleDistributions, updatedAt: DateTime.now());
      await controller.updateTour(updatedTour);
      
      await controller.executeWholesaleCollection(
        tourId: widget.tour.id,
        wholesalerId: wholesalerId,
        userId: userId ?? '',
        weightToCylinderId: _getWeightToCylinderId(cylinders),
      );
      
      if (mounted) {
        NotificationService.showSuccess(context, 'Encaissement enregistré');
        ref.invalidate(tourProvider(widget.tour.id));
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }

  Widget _buildPosSection(ThemeData theme, bool isDark) {
    if (_posDistributions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.storefront, color: theme.colorScheme.onSecondaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Distribution Points de Vente', 
                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ..._posDistributions.map((dist) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(dist.posName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                // Optimized Wrap for POS Quantities (Better height adaptation)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 16) / 3;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dist.quantities.keys.map((weight) {
                        final controller = _posQtyControllers[dist.posId]?[weight];
                        return SizedBox(
                          width: itemWidth,
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: '$weight kg',
                              suffixText: 'btl',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8), 
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                final idx = _posDistributions.indexOf(dist);
                                final qty = int.tryParse(val) ?? 0;
                                final newQuantities = Map<int, int>.from(dist.quantities);
                                newQuantities[weight] = qty;
                                _posDistributions[idx] = dist.copyWith(quantities: newQuantities);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _saveReception() async {
    try {
      final controller = ref.read(tourControllerProvider);
      final updatedTour = widget.tour.copyWith(
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
