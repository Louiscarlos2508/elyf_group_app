import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../application/controllers/stock_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../widgets/finished_products_card.dart';
import '../../widgets/raw_materials_card.dart';
import '../../widgets/stock_alerts_widget.dart';
import '../../widgets/stock_movement_table.dart';
import '../../widgets/stock_movement_filters.dart';
import '../../widgets/stock_entry_form.dart';
import '../../widgets/stock_adjustment_form.dart';
import '../../widgets/stock_integrity_check_dialog.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  void _showStockEntry(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<StockEntryFormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FormDialog(
          title: 'Approvisionnement Matières Premières',
          saveLabel: 'Ajouter au stock',
          onSave: () async {
            final formState = formKey.currentState;
            if (formState != null) {
              return await formState.submit();
            }
            return false;
          },
          child: StockEntryForm(
            key: formKey,
            showSubmitButton: false,
          ),
        );
      },
    );
  }

  void _showStockAdjustment(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<StockAdjustmentFormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FormDialog(
          title: 'Ajustement de Stock (Retrait)',
          saveLabel: 'Retirer',
          onSave: () async {
            final formState = formKey.currentState;
            if (formState != null) {
              return await formState.submit();
            }
            return false;
          },
          child: StockAdjustmentForm(
            key: formKey,
            showSubmitButton: false,
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
        onStockEntry: () => _showStockEntry(context, ref),
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
    required this.onStockEntry,
    required this.onStockAdjustment,
  });

  final StockState state;
  final VoidCallback onStockEntry;
  final VoidCallback onStockAdjustment;

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

  Future<void> _reconcilePack(BuildContext context) async {
    final ctrl = ref.read(stockControllerProvider);
    try {
      final updated = await ctrl.reconcilePackQuantityFromMovements();
      if (!context.mounted) return;
      ref.invalidate(stockStateProvider);
      ref.invalidate(stockMovementsProvider);
      if (updated) {
        NotificationService.showSuccess(
          context,
          'Stock Pack aligné avec les mouvements.',
        );
      } else {
        NotificationService.showInfo(
          context,
          'Aucun écart entre stock Pack et mouvements.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Reconcilier Pack: $e');
      }
    }
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  isWide ? AppSpacing.lg : AppSpacing.md,
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
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'Plus d\'options',
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
                                case 'reconcile':
                                  _reconcilePack(context);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics, size: 20),
                                    SizedBox(width: 12),
                                    Text('Rapport de stock'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'integrity',
                                child: Row(
                                  children: [
                                    Icon(Icons.verified_user, size: 20),
                                    SizedBox(width: 12),
                                    Text('Vérifier l\'intégrité'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reconcile',
                                child: Row(
                                  children: [
                                    Icon(Icons.sync, size: 20),
                                    SizedBox(width: 12),
                                    Text('Reconcilier Pack'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: FilledButton.icon(
                              onPressed: widget.onStockEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Approvisionnement'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: OutlinedButton.icon(
                              onPressed: widget.onStockAdjustment,
                              icon: const Icon(Icons.tune),
                              label: const Text('Ajustement'),
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
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                tooltip: 'Plus d\'options',
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
                                    case 'reconcile':
                                      _reconcilePack(context);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'report',
                                    child: Row(
                                      children: [
                                        Icon(Icons.analytics, size: 20),
                                        SizedBox(width: 12),
                                        Text('Rapport de stock'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'integrity',
                                    child: Row(
                                      children: [
                                        Icon(Icons.verified_user, size: 20),
                                        SizedBox(width: 12),
                                        Text('Vérifier l\'intégrité'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reconcile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.sync, size: 20),
                                        SizedBox(width: 12),
                                        Text('Reconcilier Pack'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: widget.onStockEntry,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Approvisionnement'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onStockAdjustment,
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Ajustement'),
                                ),
                              ),
                            ],
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
                                  availableBobines:
                                      widget.state.availableBobines,
                                  bobineStocks: widget.state.bobineStocks,
                                  packagingStocks: widget.state.packagingStocks,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FinishedProductsCard(
                                  items: widget.state.items,
                                ),
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
