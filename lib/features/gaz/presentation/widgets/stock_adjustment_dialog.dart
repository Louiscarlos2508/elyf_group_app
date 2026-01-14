import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/entities/point_of_sale.dart';
import 'stock_adjustment/stock_adjustment_header.dart';
import 'stock_adjustment/cylinder_selector_field.dart';
import 'stock_adjustment/current_stock_info.dart';

/// Dialog pour ajuster le stock de bouteilles.
class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  PointOfSale? _selectedPointOfSale;
  Cylinder? _selectedCylinder;
  CylinderStatus? _selectedStatus;
  CylinderStock? _existingStock;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingStock() async {
    if (_selectedCylinder == null || _selectedStatus == null) {
      setState(() {
        _existingStock = null;
        if (_quantityController.text.isEmpty) {
          _quantityController.text = '0';
        }
      });
      return;
    }

    try {
      final stocks = await ref.read(
        cylinderStocksProvider((
          enterpriseId: widget.enterpriseId,
          status: _selectedStatus,
          siteId: _selectedPointOfSale?.id,
        )).future,
      );
      final stock = stocks.firstWhere(
        (s) =>
            s.weight == _selectedCylinder!.weight &&
            s.cylinderId == _selectedCylinder!.id &&
            s.siteId == _selectedPointOfSale?.id,
        orElse: () => throw StateError('Stock non trouvé'),
      );

      setState(() {
        _existingStock = stock;
        _quantityController.text = stock.quantity.toString();
      });
    } catch (e) {
      setState(() {
        _existingStock = null;
        if (_quantityController.text.isEmpty) {
          _quantityController.text = '0';
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCylinder == null || _selectedStatus == null) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'Veuillez sélectionner un type de bouteille et un statut',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newQuantity = int.tryParse(_quantityController.text);
      if (newQuantity == null || newQuantity < 0) {
        if (!mounted) return;
        NotificationService.showError(context, 'Quantité invalide');
        return;
      }

      final stockController = ref.read(cylinderStockControllerProvider);

      // Si un stock existe, on l'ajuste
      if (_existingStock != null) {
        await stockController.adjustStockQuantity(
          _existingStock!.id,
          newQuantity,
        );
      } else {
        // Sinon, on doit créer un nouveau stock
        final newStock = CylinderStock(
          id: 'stock-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: _selectedCylinder!.id,
          weight: _selectedCylinder!.weight,
          status: _selectedStatus!,
          quantity: newQuantity,
          enterpriseId: widget.enterpriseId,
          siteId: _selectedPointOfSale?.id,
          updatedAt: DateTime.now(),
        );

        await stockController.addStock(newStock);
      }

      if (!mounted) return;

      // Invalider les providers pour rafraîchir les données
      ref.invalidate(
        cylinderStocksProvider((
          enterpriseId: widget.enterpriseId,
          status: null,
          siteId: null,
        )),
      );

      Navigator.of(context).pop();

      NotificationService.showSuccess(context, 'Stock ajusté avec succès');
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider((
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      )),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const StockAdjustmentHeader(),
                  const SizedBox(height: 24),

                  // Point de vente (optionnel)
                  pointsOfSaleAsync.when(
                    data: (pointsOfSale) {
                      final activePointsOfSale = pointsOfSale
                          .where((pos) => pos.isActive)
                          .toList();
                      return DropdownButtonFormField<PointOfSale?>(
                        initialValue: _selectedPointOfSale,
                        decoration: const InputDecoration(
                          labelText: 'Point de vente (optionnel)',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                          helperText:
                              'Laissez vide pour ajuster le stock global',
                        ),
                        items: [
                          const DropdownMenuItem<PointOfSale?>(
                            value: null,
                            child: Text('Tous les points de vente'),
                          ),
                          ...activePointsOfSale.map(
                            (pos) => DropdownMenuItem<PointOfSale?>(
                              value: pos,
                              child: Text(pos.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPointOfSale = value;
                            _selectedCylinder =
                                null; // Réinitialiser le cylinder sélectionné
                            _existingStock = null;
                            _quantityController.text = '';
                          });
                          _loadExistingStock();
                        },
                      );
                    },
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // Type de bouteille (selon le point de vente)
                  CylinderSelectorField(
                    enterpriseId: widget.enterpriseId,
                    moduleId: widget.moduleId,
                    selectedPointOfSale: _selectedPointOfSale,
                    selectedCylinder: _selectedCylinder,
                    onCylinderChanged: (value) {
                      setState(() {
                        _selectedCylinder = value;
                        _existingStock = null;
                        _quantityController.text = '';
                      });
                      _loadExistingStock();
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un type de bouteille';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Statut
                  DropdownButtonFormField<CylinderStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Statut *',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: CylinderStatus.values.map((status) {
                      return DropdownMenuItem<CylinderStatus>(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _existingStock = null;
                        _quantityController.text = '';
                      });
                      _loadExistingStock();
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un statut';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantité actuelle (si stock existe)
                  if (_existingStock != null) ...[
                    CurrentStockInfo(quantity: _existingStock!.quantity),
                    const SizedBox(height: 16),
                  ],

                  // Nouvelle quantité
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle quantité *',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                      helperText: 'Entrez la nouvelle quantité en stock',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une quantité';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity < 0) {
                        return 'Quantité invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: GazButtonStyles.outlined,
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          style: GazButtonStyles.filledPrimary,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Ajuster'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
