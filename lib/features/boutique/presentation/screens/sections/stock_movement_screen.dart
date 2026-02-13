
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:open_file/open_file.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/stock_movement.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class StockMovementScreen extends ConsumerStatefulWidget {
  const StockMovementScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends ConsumerState<StockMovementScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  StockMovementType? _selectedType;
  String? _selectedProductId;
  bool _isLoading = false;
  List<StockMovement> _movements = [];

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _fetchMovements();
  }

  Future<void> _fetchMovements() async {
    setState(() => _isLoading = true);
    try {
      final movements = await ref.read(storeControllerProvider).fetchStockMovements(
        productId: _selectedProductId,
        startDate: _startDate,
        endDate: _endDate?.add(const Duration(days: 1)), // Include end date fully
        type: _selectedType,
      );
      if (mounted) {
        setState(() {
          _movements = movements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationService.showError(context, 'Erreur lors du chargement des mouvements: $e');
      }
    }
  }

  Future<void> _exportData() async {
    if (_movements.isEmpty) {
      NotificationService.showInfo(context, 'Aucune donnée à exporter');
      return;
    }

    try {
      NotificationService.showInfo(context, 'Génération du fichier CSV...');
      final file = await ref.read(boutiqueExportServiceProvider).exportStockMovements(_movements);
      await OpenFile.open(file.path);
    } catch (e) {
      NotificationService.showError(context, 'Erreur lors de l\'export: $e');
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _selectedType = null;
      _selectedProductId = widget.initialProductId; // Keep initial if provided
    });
    _fetchMovements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          BoutiqueHeader(
            title: 'MOUVEMENTS DE STOCK',
            subtitle: 'Historique et Audit',
            gradientColors: [Colors.blueGrey[700]!, Colors.blueGrey[900]!],
            shadowColor: Colors.blueGrey[700]!,
            showBackButton: true,
            additionalActions: [
              IconButton(
                onPressed: _exportData,
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Exporter CSV',
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateFilter(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTypeFilter(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: _fetchMovements,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Actualiser',
                          ),
                          IconButton(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.clear_all),
                            tooltip: 'Réinitialiser filtres',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_movements.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.history,
                title: 'Aucun mouvement',
                message: 'Aucun mouvement de stock trouvé pour les filtres sélectionnés.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movement = _movements[index];
                    return _buildMovementCard(movement);
                  },
                  childCount: _movements.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
          _fetchMovements();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              _startDate != null && _endDate != null
                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                  : 'Filtrer par date',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<StockMovementType>(
      value: _selectedType,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      hint: const Text('Tous les types'),
      items: StockMovementType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(_getTypeLabel(type)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedType = value);
        _fetchMovements();
      },
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    // We need to fetch product name, maybe cache it or fetch eagerly?
    // For now, let's use a FutureBuilder or just show ID detailed if necessary.
    // Ideally, we should fetch products or have a map.
    // Let's use productProvider(id) if available or fetch all products once to map names.
    // Since fetchMovements is done, maybe fetch filtered products?
    // Efficient way: use Consumer with product provider family?
    // Or just storeController.getProduct(id)
    
    final isPositive = movement.quantity > 0;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(movement.type).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTypeIcon(movement.type),
            color: _getTypeColor(movement.type),
            size: 20,
          ),
        ),
        title: Consumer(
          builder: (context, ref, _) {
            final productAsync = ref.watch(productProvider(movement.productId));
            return productAsync.when(
              data: (product) => Text(
                product?.name ?? 'Produit inconnu (${movement.productId})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              loading: () => const Text('Chargement...'),
              error: (_, __) => Text('Produit inconnu (${movement.productId})'),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(movement.date)} • ${_getTypeLabel(movement.type)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (movement.notes != null)
              Text(
                movement.notes!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${movement.quantity}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Stock: ${movement.balanceAfter}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return 'Vente';
      case StockMovementType.purchase:
        return 'Achat';
      case StockMovementType.adjustment:
        return 'Ajustement';
      case StockMovementType.returnItem:
        return 'Retour/Annulation';
      case StockMovementType.initial:
        return 'Initial';
    }
  }

  Color _getTypeColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return Colors.blue;
      case StockMovementType.purchase:
        return Colors.green;
      case StockMovementType.adjustment:
        return Colors.orange;
      case StockMovementType.returnItem:
        return Colors.purple;
      case StockMovementType.initial:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return Icons.shopping_cart;
      case StockMovementType.purchase:
        return Icons.shopping_bag;
      case StockMovementType.adjustment:
        return Icons.tune;
      case StockMovementType.returnItem:
        return Icons.assignment_return;
      case StockMovementType.initial:
        return Icons.flag;
    }
  }
}

// Simple provider to fetch single product for list item
final productProvider = FutureProvider.family<Product?, String>((ref, id) {
  return ref.read(storeControllerProvider).getProduct(id);
});
