import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../../../../../core/tenant/tenant_provider.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/gas_sale_form/tour_wholesaler_selector_widget.dart';
import '../../../widgets/gas_sale_form/price_stock_manager.dart';
import '../../../widgets/gas_sale_form/gas_sale_submit_handler.dart';
import '../../../../domain/entities/gaz_settings.dart';
import 'wholesale_kpi_section.dart';

/// Onglet nouvelle vente pour la vente en gros.
/// Utilise un formulaire de type "Vente en Gros" avec une liste de bouteilles.
class WholesaleNewSaleTab extends ConsumerStatefulWidget {
  const WholesaleNewSaleTab({
    super.key,
    required this.onCylinderTap, // Gardé pour compatibilité si besoin
  });

  final ValueChanged<Cylinder> onCylinderTap;

  @override
  ConsumerState<WholesaleNewSaleTab> createState() => _WholesaleNewSaleTabState();
}

class _WholesaleNewSaleTabState extends ConsumerState<WholesaleNewSaleTab> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // State for Wholesaler
  String? _selectedWholesalerId;
  String? _selectedWholesalerName;
  String _selectedTier = 'default';

  // Map pour stocker les quantités saisies par cylindre ID
  final Map<String, int> _quantities = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitSale(Cylinder cylinder, int quantity) async {
    final enterpriseId = ref.read(activeEnterpriseIdProvider).value;
    if (enterpriseId == null) return;

    // Récupérer le prix unitaire
    final unitPrice = await PriceStockManager.updateUnitPrice(
      ref: ref,
      cylinder: cylinder,
      enterpriseId: enterpriseId,
      isWholesale: true,
    );

    // Récupérer le stock
    final availableStock = await PriceStockManager.updateAvailableStock(
      ref: ref,
      cylinder: cylinder,
      enterpriseId: enterpriseId,
    );

    if (quantity > availableStock) {
      if (mounted) {
        NotificationService.showError(context, 'Stock insuffisant pour ${cylinder.label} ($availableStock disponible)');
      }
      return;
    }

    final totalAmount = GazCalculationService.calculateTotalAmount(
      cylinder: cylinder,
      unitPrice: unitPrice,
      quantity: quantity,
    );

    await GasSaleSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedCylinder: cylinder,
      quantity: quantity,
      availableStock: availableStock,
      enterpriseId: enterpriseId,
      saleType: SaleType.wholesale,
      customerName: _selectedWholesalerName,
      customerPhone: null, // Ideally retrieved from wholesaler
      notes: _notesController.text.trim(),
      totalAmount: totalAmount,
      unitPrice: unitPrice,
      onLoadingChanged: () => setState(() => _isLoading = !_isLoading),
    );
  }

  Future<void> _submitAllSales(List<Cylinder> availableCylinders) async {
    if (!_formKey.currentState!.validate()) return;
    
    final entries = _quantities.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      NotificationService.showError(context, 'Veuillez saisir au moins une quantité');
      return;
    }

    setState(() => _isLoading = true);
    int successCount = 0;

    try {
      for (final entry in entries) {
        final cylinder = availableCylinders.firstWhere((c) => c.id == entry.key);
        await _submitSale(cylinder, entry.value);
        successCount++;
      }
      
      if (mounted && successCount > 0) {
        NotificationService.showSuccess(context, '$successCount vente(s) enregistrée(s)');
        // Réinitialiser les quantités
        setState(() {
          _quantities.clear();
          _notesController.clear();
        });
        _formKey.currentState?.reset();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  int _calculateTotalBottles() {
    return _quantities.values.fold(0, (sum, q) => sum + q);
  }

  int _calculateTotalWeight(List<Cylinder> cylinders) {
    int total = 0;
    for (final cylinder in cylinders) {
      final qty = _quantities[cylinder.id] ?? 0;
      total += cylinder.weight * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
    final enterpriseId = activeEnterpriseIdAsync.value ?? 'default_enterprise';
    final settings = ref.watch(gazSettingsProvider((
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    ))).value;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
        const WholesaleKpiSection(),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.dividerColor.withAlpha(50)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'IDENTIFICATION CLIENT',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TourWholesalerSelectorWidget(
                            selectedWholesalerId: _selectedWholesalerId,
                            selectedWholesalerName: _selectedWholesalerName,
                            enterpriseId: enterpriseId,
                            onWholesalerChanged: (w) {
                              setState(() {
                                if (w != null) {
                                  _selectedWholesalerId = w.id;
                                  _selectedWholesalerName = w.name;
                                  _selectedTier = w.tier;
                                } else {
                                  _selectedWholesalerId = null;
                                  _selectedWholesalerName = null;
                                  _selectedTier = 'default';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes additionnelles',
                              prefixIcon: Icon(Icons.note_alt_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ARTICLES DE LA VENTE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),

        cylindersAsync.when(
          data: (cylinders) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cylinder = cylinders[index];
                return _WholesaleOrderRow(
                  key: ValueKey('${cylinder.id}_${_quantities.isEmpty}'), // Force recreation on clear
                  cylinder: cylinder,
                  enterpriseId: enterpriseId,
                  onQuantityChanged: (q) => _quantities[cylinder.id] = q,
                );
              },
              childCount: cylinders.length,
            ),
          ),
          loading: () => SliverToBoxAdapter(child: AppShimmers.list(context)),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Erreur: $e'))),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
        cylindersAsync.when(
          data: (cylinders) => _buildStickyFooter(cylinders, theme, settings),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(List<Cylinder> cylinders, ThemeData theme, GazSettings? settings) {
    int totalBottles = 0;
    int totalWeight = 0;
    double totalAmount = 0;

    for (final cylinder in cylinders) {
      final qty = _quantities[cylinder.id] ?? 0;
      if (qty > 0) {
        totalBottles += qty;
        totalWeight += cylinder.weight * qty;
        
        final unitPrice = GazCalculationService.determineWholesalePrice(
          cylinder: cylinder,
          settings: settings,
        );
        totalAmount += unitPrice * qty;
      }
    }

    if (totalBottles == 0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(230),
          border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(50))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalBottles bouteilles • $totalWeight kg',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.formatDouble(totalAmount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : () => _submitAllSales(cylinders),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Icon(Icons.shopping_cart_checkout),
                  label: const Text('ENREGISTRER LA VENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WholesaleOrderRow extends ConsumerStatefulWidget {
  const _WholesaleOrderRow({
    super.key,
    required this.cylinder,
    required this.enterpriseId,
    required this.onQuantityChanged,
  });

  final Cylinder cylinder;
  final String enterpriseId;
  final ValueChanged<int> onQuantityChanged;

  @override
  ConsumerState<_WholesaleOrderRow> createState() => _WholesaleOrderRowState();
}

class _WholesaleOrderRowState extends ConsumerState<_WholesaleOrderRow> {
  int _currentQuantity = 0;

  void _updateQuantity(int delta, int availableStock) {
    setState(() {
      final newValue = _currentQuantity + delta;
      if (newValue >= 0 && newValue <= availableStock) {
        _currentQuantity = newValue;
        widget.onQuantityChanged(_currentQuantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockAsync = ref.watch(cylinderStocksProvider((
      enterpriseId: widget.enterpriseId,
      status: CylinderStatus.full,
      siteId: null,
    )));

    return stockAsync.when(
      data: (stocks) {
        final stock = stocks
            .where((s) => s.weight == widget.cylinder.weight)
            .fold<int>(0, (sum, s) => sum + s.quantity);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor.withAlpha(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon or Asset
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.gas_meter_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${widget.cylinder.weight}kg',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (stock < 5 ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer).withAlpha(100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$stock en stock',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: stock < 5 ? theme.colorScheme.error : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.cylinder.label == '${widget.cylinder.weight}kg' ? 'Bouteille Standard' : (widget.cylinder.label),
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                
                // Modern Quantity Selector [ - ] Qty [ + ]
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _QtyIconButton(
                        icon: Icons.remove,
                        onPressed: _currentQuantity > 0 ? () => _updateQuantity(-1, stock) : null,
                      ),
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text(
                          '$_currentQuantity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _currentQuantity > 0 ? theme.colorScheme.primary : theme.disabledColor,
                          ),
                        ),
                      ),
                      _QtyIconButton(
                        icon: Icons.add,
                        onPressed: _currentQuantity < stock ? () => _updateQuantity(1, stock) : null,
                        isPrimary: _currentQuantity < stock,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _WholesaleRowShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: onPressed != null 
                ? (isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}

class _WholesaleRowShimmer extends StatelessWidget {
  const _WholesaleRowShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withAlpha(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 100,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
