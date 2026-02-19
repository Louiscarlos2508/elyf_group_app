import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/stock_movement.dart';

/// Widget pour filtrer les mouvements de stock par période et type
class StockMovementFilters extends ConsumerStatefulWidget {
  const StockMovementFilters({super.key, required this.onFiltersChanged});

  final void Function({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? inventoryDate,
    StockMovementType? type,
    String? productName,
  })
  onFiltersChanged;

  @override
  ConsumerState<StockMovementFilters> createState() =>
      _StockMovementFiltersState();
}

class _StockMovementFiltersState extends ConsumerState<StockMovementFilters> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _inventoryDate;
  StockMovementType? _selectedType;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Par défaut, afficher les 30 derniers jours
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      startDate: _startDate,
      endDate: _endDate,
      inventoryDate: _inventoryDate,
      type: _selectedType,
      productName: _selectedProduct,
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _applyFilters();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _applyFilters();
      });
    }
  }

  Future<void> _selectInventoryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inventoryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Date pour l\'état des stocks (Bilan)',
    );
    if (picked != null) {
      setState(() {
        _inventoryDate = picked;
        // Aligner les filtres de mouvements sur cette date
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _applyFilters();
      });
    }
  }

  void _selectPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          break;
        case 'quarter':
          final quarter = (now.month - 1) ~/ 3;
          _startDate = DateTime(now.year, quarter * 3 + 1, 1);
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          break;
        case 'all':
          _startDate = null;
          _endDate = null;
          break;
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _inventoryDate = null;
      _selectedType = null;
      _selectedProduct = null;
      _applyFilters();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Toutes';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      isGlass: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filtres de l\'historique',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip(context, 'Aujourd\'hui', 'today'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, '7 jours', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'Mois', 'month'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'Année', 'year'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'All', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        context,
                        'Date début',
                        _startDate,
                        _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateField(
                        context,
                        'Date Bilan Stock',
                        _inventoryDate,
                        _selectInventoryDate,
                        color: theme.colorScheme.secondary,
                        icon: Icons.history,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTypeFilter(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            context,
                            'Début',
                            _startDate,
                            _selectStartDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            context,
                            'Fin',
                            _endDate,
                            _selectEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            context,
                            'Date Bilan Stock',
                            _inventoryDate,
                            _selectInventoryDate,
                            color: theme.colorScheme.secondary,
                            icon: Icons.history,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeFilter(context)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, String period) {
    final theme = Theme.of(context);
    final isSelected = _isPeriodSelected(period);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectPeriod(period),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }



  bool _isPeriodSelected(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return _startDate != null &&
            _startDate!.year == now.year &&
            _startDate!.month == now.month &&
            _startDate!.day == now.day;
      case 'week':
        return _startDate != null &&
            _endDate != null &&
            _endDate!.difference(_startDate!) == const Duration(days: 7);
      case 'month':
        return _startDate != null &&
            _startDate!.year == now.year &&
            _startDate!.month == now.month &&
            _startDate!.day == 1;
      case 'quarter':
        if (_startDate == null) return false;
        final quarter = (_startDate!.month - 1) ~/ 3;
        return _startDate!.year == now.year &&
            _startDate!.month == quarter * 3 + 1 &&
            _startDate!.day == 1;
      case 'year':
        return _startDate != null &&
            _startDate!.year == now.year &&
            _startDate!.month == 1 &&
            _startDate!.day == 1;
      case 'all':
        return _startDate == null && _endDate == null;
      default:
        return false;
    }
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    Future<void> Function(BuildContext) onTap, {
    Color? color,
    IconData icon = Icons.calendar_today,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: color != null
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                )
              : null,
        ),
        child: Text(
          _formatDate(date),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: color != null ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;

        return DropdownButtonFormField<StockMovementType?>(
          decoration: InputDecoration(
            labelText: 'Type',
            prefixIcon: const Icon(Icons.swap_vert, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          initialValue: _selectedType,
          items: [
            const DropdownMenuItem<StockMovementType?>(
              value: null,
              child: Text('Tous'),
            ),
            DropdownMenuItem<StockMovementType>(
              value: StockMovementType.entry,
              child: isWide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        const Text('Entrées'),
                      ],
                    )
                  : const Text('Entrées'),
            ),
            DropdownMenuItem<StockMovementType>(
              value: StockMovementType.exit,
              child: isWide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Sorties'),
                      ],
                    )
                  : const Text('Sorties'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value;
              _applyFilters();
            });
          },
        );
      },
    );
  }
}
