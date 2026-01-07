import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../../application/controllers/stock_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/finished_products_card.dart';
import '../../../../shared.dart';
import '../../widgets/raw_materials_card.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_alerts_widget.dart';
import '../../widgets/stock_movement_table.dart';
import '../../widgets/stock_movement_filters.dart';
import '../../widgets/stock_entry_form.dart';
import '../../../domain/entities/stock_movement.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  void _showStockEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Approvisionnement Matières Premières',
        child: const StockEntryForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockStateProvider);
    return state.when(
      data: (data) => _StockContentWithFilters(
        state: data,
        onStockEntry: () => _showStockEntry(context),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => SectionPlaceholder(
        icon: Icons.inventory_2_outlined,
        title: 'Stocks indisponibles',
        subtitle: 'Impossible de récupérer les inventaires.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () => ref.invalidate(stockStateProvider),
      ),
    );
  }
}

class _StockContentWithFilters extends ConsumerStatefulWidget {
  const _StockContentWithFilters({
    required this.state,
    required this.onStockEntry,
  });

  final StockState state;
  final VoidCallback onStockEntry;

  @override
  ConsumerState<_StockContentWithFilters> createState() =>
      _StockContentWithFiltersState();
}

class _StockContentWithFiltersState
    extends ConsumerState<_StockContentWithFilters> {
  DateTime? _startDate;
  DateTime? _endDate;
  StockMovementType? _selectedType;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Initialiser les filtres par défaut pour éviter les callbacks inattendus
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _selectedType = null;
    _selectedProduct = null;
  }

  void _showStockReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockReportScreen(
          moduleName: 'Eau Minérale',
          stockItems: widget.state.items,
          packagingStocks: widget.state.packagingStocks,
          availableBobines: widget.state.availableBobines,
        ),
      ),
    );
  }

  void _onFiltersChanged({
    DateTime? startDate,
    DateTime? endDate,
    StockMovementType? type,
    String? productName,
  }) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _selectedType = type;
      _selectedProduct = productName;
    });
  }

  List<StockMovement> _filterMovements(List<StockMovement> movements) {
    var filtered = movements;

    // Filtrer par type
    if (_selectedType != null) {
      filtered = filtered.where((m) => m.type == _selectedType).toList();
    }

    // Filtrer par nom de produit
    if (_selectedProduct != null && _selectedProduct!.isNotEmpty) {
      filtered = filtered
          .where((m) => m.productName
              .toLowerCase()
              .contains(_selectedProduct!.toLowerCase()))
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
        final movementsAsync = ref.watch(stockMovementsProvider(filterParams));
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: isWide
                    ? Row(
                        children: [
                          Text(
                            'Gestion des Stocks',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              ref.invalidate(stockStateProvider);
                              final filterParams = StockMovementFiltersParams(
                                startDate: _startDate,
                                endDate: _endDate,
                                type: _selectedType,
                                productName: _selectedProduct,
                              );
                              ref.invalidate(stockMovementsProvider(filterParams));
                            },
                            tooltip: 'Actualiser les stocks',
                          ),
                          IconButton(
                            icon: const Icon(Icons.analytics),
                            onPressed: () => _showStockReport(context),
                            tooltip: 'Rapport de stock',
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: FilledButton.icon(
                              onPressed: widget.onStockEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Approvisionnement'),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Gestion des Stocks',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  ref.invalidate(stockStateProvider);
                                  final filterParams = StockMovementFiltersParams(
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    type: _selectedType,
                                    productName: _selectedProduct,
                                  );
                                  ref.invalidate(stockMovementsProvider(filterParams));
                                },
                                tooltip: 'Actualiser les stocks',
                              ),
                              IconButton(
                                icon: const Icon(Icons.analytics),
                                onPressed: () => _showStockReport(context),
                                tooltip: 'Rapport de stock',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: widget.onStockEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Approvisionnement'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: StockAlertsWidget(),
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
                                  items: widget.state.items,
                                  availableBobines: widget.state.availableBobines,
                                  bobineStocks: widget.state.bobineStocks,
                                  packagingStocks: widget.state.packagingStocks,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FinishedProductsCard(items: widget.state.items),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          RawMaterialsCard(
                            items: widget.state.items,
                            availableBobines: widget.state.availableBobines,
                            bobineStocks: widget.state.bobineStocks,
                            packagingStocks: widget.state.packagingStocks,
                          ),
                          const SizedBox(height: 16),
                          FinishedProductsCard(items: widget.state.items),
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
                    StockMovementFilters(
                      onFiltersChanged: _onFiltersChanged,
                    ),
                    const SizedBox(height: 16),
                    movementsAsync.when(
                      data: (movements) {
                        final filtered = _filterMovements(movements);
                        return StockMovementTable(movements: filtered);
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
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
                                ref.invalidate(stockMovementsProvider(filterParams));
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}
