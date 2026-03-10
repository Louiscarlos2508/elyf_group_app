import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../widgets/finished_products_card.dart';
import '../../widgets/raw_materials_card.dart';
import '../../widgets/stock_movement_table.dart';
import '../../widgets/stock_movement_filters.dart';
import '../../widgets/stock_adjustment_form.dart';
import '../../widgets/stock_integrity_check_dialog.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});


  void _showStockAdjustment(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ElyfCard(
              padding: EdgeInsets.zero,
              borderRadius: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header personnalisé
                   Padding(
                     padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: Theme.of(context).colorScheme.primary.withAlpha(20),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Icon(Icons.auto_fix_high_rounded, color: Theme.of(context).colorScheme.primary),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Text(
                             'Ajustement Stock',
                             style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                           ),
                         ),
                         IconButton.filledTonal(
                           icon: const Icon(Icons.close, size: 20),
                           onPressed: () => Navigator.of(dialogContext).pop(),
                         ),
                       ],
                     ),
                   ),
                   Flexible(
                     child: SingleChildScrollView(
                       padding: const EdgeInsets.symmetric(horizontal: 24),
                       child: StockAdjustmentForm(
                         showSubmitButton: true,
                         onSuccess: () => Navigator.of(dialogContext).pop(),
                       ),
                     ),
                   ),
                   const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockStateProvider);
    return state.when(
      data: (data) => _StockContentWithFilters(
          state: data,
          onStockAdjustment: () => _showStockAdjustment(context, ref),
        ),
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Stocks indisponibles',
        message: 'Impossible de récupérer les inventaires.',
        onRetry: () => ref.refresh(stockStateProvider),
      ),
    );
  }
}

class _StockContentWithFilters extends ConsumerStatefulWidget {
  const _StockContentWithFilters({
    required this.state,
    required this.onStockAdjustment,
  });

  final StockState state;
  final VoidCallback onStockAdjustment;

  @override
  ConsumerState<_StockContentWithFilters> createState() =>
      _StockContentWithFiltersState();
}

class _StockContentWithFiltersState
    extends ConsumerState<_StockContentWithFilters> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _inventoryDate;
  StockMovementType? _selectedType;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _inventoryDate = null;
    _selectedType = null;
    _selectedProduct = null;
  }

  void _showStockReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockReportScreen(
          moduleName: 'Eau Minérale',
          stockItems: widget.state.items,
          availableMachineMaterials: widget.state.availableMachineMaterials,
        ),
      ),
    );
  }


  void _onFiltersChanged({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? inventoryDate,
    StockMovementType? type,
    String? productName,
  }) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _inventoryDate = inventoryDate;
      _selectedType = type;
      _selectedProduct = productName;
    });
  }

  List<StockMovement> _filterMovements(List<StockMovement> movements) {
    var filtered = movements;

    if (_selectedType != null) {
      filtered = filtered.where((m) => m.type == _selectedType).toList();
    }

    if (_selectedProduct != null && _selectedProduct!.isNotEmpty) {
      filtered = filtered
          .where(
            (m) => m.productName.toLowerCase().contains(
              _selectedProduct!.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final filterParams = StockMovementFiltersParams(
          startDate: _startDate,
          endDate: _endDate,
          type: _selectedType,
          productName: _selectedProduct,
        );
        final movementsAsync = ref.watch(
          stockMovementsProvider((filterParams)),
        );

        // État historique si une date d'inventaire est sélectionnée
        final historicalStateAsync = _inventoryDate != null
            ? ref.watch(historicalStockStateProvider(_inventoryDate!))
            : null;

        // Déterminer quel état de stock afficher
        final activeState = historicalStateAsync?.maybeWhen(
              data: (data) => data,
              orElse: () => widget.state,
            ) ??
            widget.state;

        return CustomScrollView(
          slivers: [
            // Premium Header for Stock
            ElyfModuleHeader(
              title: "Inventaire & Mouvements",
              subtitle: "Traçabilité complète de vos stocks : bobines, emballages et produits finis.",
              module: EnterpriseModule.eau,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        _showStockReport(context);
                        break;
                      case 'integrity':
                        showDialog(
                          context: context,
                          builder: (context) =>
                              const StockIntegrityCheckDialog(),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Générer Rapport'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'integrity',
                      child: Row(
                        children: [
                          Icon(Icons.security_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Vérifier Intégrité'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onStockAdjustment,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.tune_outlined, size: 20),
                        label: const Text('Ajustement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_inventoryDate != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: theme.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AFFICHAGE DU BILAN AU ${DateFormatter.formatDate(_inventoryDate!)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _onFiltersChanged(
                          startDate: DateTime.now().subtract(const Duration(days: 30)),
                          endDate: DateTime.now(),
                          inventoryDate: null,
                          productName: _selectedProduct,
                          type: _selectedType,
                        ),
                        child: const Text('Retour au présent'),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isWide
                    ? Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: RawMaterialsCard(
                                  items: activeState.items,
                                  products: ref.watch(productsProvider).value,
                                  availableMachineMaterials: activeState.availableMachineMaterials,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FinishedProductsCard(
                                  items: activeState.items,
                                  products: ref.watch(productsProvider).value,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          RawMaterialsCard(
                            items: activeState.items,
                            products: ref.watch(productsProvider).value,
                            availableMachineMaterials: activeState.availableMachineMaterials,
                          ),
                          const SizedBox(height: 16),
                          FinishedProductsCard(
                            items: activeState.items,
                            products: ref.watch(productsProvider).value,
                          ),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des Mouvements',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Traçabilité complète de tous les mouvements de stock (bobines, emballages, produits finis)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StockMovementFilters(onFiltersChanged: _onFiltersChanged),
                    const SizedBox(height: 16),
                    movementsAsync.when(
                      data: (movements) {
                        final filtered = _filterMovements(movements);
                        return StockMovementTable(movements: filtered);
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: LoadingIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur lors du chargement des mouvements',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                final filterParams = StockMovementFiltersParams(
                                  startDate: _startDate,
                                  endDate: _endDate,
                                  type: _selectedType,
                                  productName: _selectedProduct,
                                );
                                ref.invalidate(
                                  stockMovementsProvider((filterParams)),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
