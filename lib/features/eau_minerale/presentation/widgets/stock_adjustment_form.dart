import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/product.dart';

class StockAdjustmentForm extends ConsumerStatefulWidget {
  const StockAdjustmentForm({
    super.key,
    this.showSubmitButton = true,
    this.onSubmit,
    this.onSuccess,
  });

  final bool showSubmitButton;
  final Future<bool> Function()? onSubmit;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<StockAdjustmentForm> createState() =>
      StockAdjustmentFormState();
}

enum _AdjustmentDirection { addition, removal }

class StockAdjustmentFormState extends ConsumerState<StockAdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _justificatifController = TextEditingController();

  Product? _selectedProduct;
  _AdjustmentDirection _direction = _AdjustmentDirection.removal;
  bool _isLoading = false;
  bool _isEntryByLot = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _justificatifController.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    if (widget.onSubmit != null) return widget.onSubmit!();
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return false;

    setState(() => _isLoading = true);
    try {
      final stockController = ref.read(stockControllerProvider);
      final quantite = double.parse(_quantityController.text);
      final justificatif = _justificatifController.text.trim();

      if (justificatif.isEmpty) {
        NotificationService.showError(context, 'Un justificatif est nécessaire.');
        return false;
      }

      final isAddition = _direction == _AdjustmentDirection.addition;
      final prefix = isAddition ? '[AJOUT]' : '[RETRAIT]';
      
      double inputQuantite = double.parse(_quantityController.text);
      double quantiteFinale = inputQuantite;
      String lotContext = '';

      if (_isEntryByLot && _selectedProduct != null && _selectedProduct!.supplyUnit != null && _selectedProduct!.unitsPerLot > 1) {
        quantiteFinale = inputQuantite * _selectedProduct!.unitsPerLot;
        lotContext = ' (Saisi sous forme de $inputQuantite ${_selectedProduct!.supplyUnit})';
      }

      final fullReason = 'Ajustement $prefix: $justificatif$lotContext';

      if (isAddition) {
        await stockController.recordEntry(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          quantite: quantiteFinale,
          unit: _selectedProduct!.unit,
          raison: fullReason,
          notes: justificatif,
        );
      } else {
        await stockController.recordExit(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          quantite: quantiteFinale,
          unit: _selectedProduct!.unit,
          raison: fullReason,
          notes: justificatif,
        );
      }

      ref.invalidate(stockStateProvider);
      ref.invalidate(stockMovementsProvider);
      
      NotificationService.showSuccess(context, 'Stock mis à jour');
      if (widget.onSuccess != null) widget.onSuccess!();
      return true;
    } catch (e) {
      NotificationService.showError(context, e.toString());
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAdd = _direction == _AdjustmentDirection.addition;
    final colorTheme = isAdd ? Colors.green : Colors.red;
    
    final productsAsync = ref.watch(eauMineraleProductRepositoryProvider.select((repo) => repo.fetchProducts()));

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDirectionCard(
                  direction: _AdjustmentDirection.addition,
                  icon: Icons.add_circle_outline_rounded,
                  label: 'AJOUTER (+)',
                  activeColor: Colors.green,
                  isSelected: _direction == _AdjustmentDirection.addition,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDirectionCard(
                  direction: _AdjustmentDirection.removal,
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'RETIRER (-)',
                  activeColor: Colors.red,
                  isSelected: _direction == _AdjustmentDirection.removal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sélecteur de produit
          FutureBuilder<List<Product>>(
            future: productsAsync,
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              return ElyfCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Produit à ajuster',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: products.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  )).toList(),
                  onChanged: (p) {
                    setState(() {
                      _selectedProduct = p;
                      if (p == null || p.supplyUnit == null || p.unitsPerLot <= 1) {
                        _isEntryByLot = false;
                      }
                    });
                  },
                  validator: (v) => v == null ? 'Sélectionnez un produit' : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          if (_selectedProduct != null && _selectedProduct!.supplyUnit != null && _selectedProduct!.unitsPerLot > 1 && isAdd)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElyfCard(
                padding: EdgeInsets.zero,
                backgroundColor: colors.surfaceContainerLow,
                child: SwitchListTile(
                  title: Text(
                    'Entrée par Lot (${_selectedProduct!.supplyUnit})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '1 ${_selectedProduct!.supplyUnit} = ${_selectedProduct!.unitsPerLot} ${_selectedProduct!.unit}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  value: _isEntryByLot,
                  onChanged: (val) => setState(() => _isEntryByLot = val),
                  activeColor: colorTheme,
                  secondary: Icon(Icons.layers_outlined, color: _isEntryByLot ? colorTheme : colors.onSurfaceVariant),
                ),
              ),
            ),

          ElyfCard(
            padding: const EdgeInsets.all(20),
            borderColor: colorTheme.withAlpha(70),
            backgroundColor: colorTheme.withAlpha(5),
            child: TextFormField(
              controller: _quantityController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                labelText: isAdd ? 'Quantité ajoutée' : 'Quantité retirée',
                prefixIcon: Icon(Icons.numbers_rounded, color: colorTheme),
                border: InputBorder.none,
                suffixText: (_isEntryByLot && _selectedProduct?.supplyUnit != null)
                    ? _selectedProduct!.supplyUnit!
                    : (_selectedProduct?.unit ?? ''),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorTheme),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
              validator: (v) => (v == null || v.isEmpty) ? 'Entrez un nombre' : null,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _justificatifController,
            decoration: InputDecoration(
              labelText: 'Motif / Justificatif',
              prefixIcon: const Icon(Icons.comment_outlined),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            maxLines: 2,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Le motif est obligatoire' : null,
          ),
          const SizedBox(height: 24),

          if (widget.showSubmitButton) 
            ElevatedButton(
              onPressed: _isLoading ? null : () => submit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTheme,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isAdd ? 'CONFIRMER L\'AJOUT' : 'CONFIRMER LE RETRAIT'),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard({
    required _AdjustmentDirection direction,
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _direction = direction),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : activeColor.withAlpha(50), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : activeColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : activeColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

