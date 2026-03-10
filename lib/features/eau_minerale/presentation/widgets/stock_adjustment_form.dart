import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/pack_constants.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/packaging_stock_movement.dart';

/// Formulaire pour ajuster les stocks (ajouter ou retirer).
/// 
/// Audit & UX: Design simplifié avec icônes et codes couleurs pour l'accessibilité.
/// Idéal pour les utilisateurs non-lettrés grâce aux repères visuels forts.
class StockAdjustmentForm extends ConsumerStatefulWidget {
  const StockAdjustmentForm({
    super.key,
    this.showSubmitButton = true,
    this.onSubmit,
  });

  final bool showSubmitButton;
  final Future<bool> Function()? onSubmit;

  @override
  ConsumerState<StockAdjustmentForm> createState() =>
      StockAdjustmentFormState();
}

enum _AdjustmentType { bobine, emballage, produitFini }
enum _AdjustmentDirection { addition, removal }

class StockAdjustmentFormState
    extends ConsumerState<StockAdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _justificatifController = TextEditingController();

  _AdjustmentType _selectedType = _AdjustmentType.bobine;
  _AdjustmentDirection _direction = _AdjustmentDirection.removal;
  bool _useLots = false;
  bool _isLoading = false;

  static const String _bobineType = 'Bobine';

  @override
  void dispose() {
    _quantityController.dispose();
    _justificatifController.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    if (widget.onSubmit != null) {
      return widget.onSubmit!();
    }

    if (!_formKey.currentState!.validate()) return false;

    setState(() => _isLoading = true);
    try {
      final stockController = ref.read(stockControllerProvider);
      final quantiteStr = _quantityController.text;
      final quantite = double.parse(quantiteStr);
      final justificatif = _justificatifController.text.trim();

      if (justificatif.isEmpty) {
        if (!mounted) return false;
        NotificationService.showError(
          context,
          'Un justificatif est nécessaire.',
        );
        return false;
      }

      final isAddition = _direction == _AdjustmentDirection.addition;
      final prefix = isAddition ? '[AJOUT]' : '[RETRAIT]';
      final fullReason = 'Ajustement $prefix: $justificatif';

      switch (_selectedType) {
        case _AdjustmentType.bobine:
          final bobineController = ref.read(bobineStockQuantityControllerProvider);
          var stock = await bobineController.fetchByType(_bobineType);

          if (stock == null && !isAddition) {
             throw const NotFoundException('Stock de bobines non trouvé');
          }

          if (!isAddition && stock != null) {
            final currentQuantity = stock.quantity;
            if (currentQuantity < quantite.toInt()) {
              throw ValidationException('Stock insuffisant ($currentQuantity disponible).');
            }
          }

          final movementType = isAddition ? BobineMovementType.entree : BobineMovementType.retrait;
          final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
          
          final movement = BobineStockMovement(
            id: 'local_adj_bb_${DateTime.now().millisecondsSinceEpoch}',
            enterpriseId: enterpriseId,
            bobineId: stock?.id ?? 'bobine-standard',
            bobineReference: _bobineType,
            type: movementType,
            date: DateTime.now(),
            quantite: quantite,
            raison: fullReason,
            notes: justificatif,
            createdAt: DateTime.now(),
          );
          await bobineController.recordMovement(movement);
          break;

        case _AdjustmentType.emballage:
          final packagingController = ref.read(packagingStockControllerProvider);
          var packagingStock = await packagingController.fetchByType('Emballage');

          if (packagingStock == null && !isAddition) {
            throw const NotFoundException('Stock d\'emballages non trouvé');
          }

          int quantiteUnits = quantite.toInt();
          if (_useLots && packagingStock != null) {
             quantiteUnits = (quantite * packagingStock.unitsPerLot).toInt();
          } else if (_useLots) {
             quantiteUnits = (quantite * 100).toInt(); // Fallback lot size if new stock
          }

          if (!isAddition && packagingStock != null && packagingStock.quantity < quantiteUnits) {
            throw ValidationException('Stock insuffisant (${packagingStock.quantity} disponible).');
          }

          final movementType = isAddition ? PackagingMovementType.entree : PackagingMovementType.ajustement;
          final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
          
          final movement = PackagingStockMovement(
            id: 'local_adj_pkg_${DateTime.now().millisecondsSinceEpoch}',
            enterpriseId: enterpriseId,
            packagingId: packagingStock?.id ?? 'packaging-emballage',
            packagingType: 'Emballage',
            type: movementType,
            date: DateTime.now(),
            quantite: quantiteUnits,
            isInLots: _useLots,
            quantiteSaisie: quantite,
            raison: fullReason,
            notes: justificatif,
            createdAt: DateTime.now(),
          );
          await packagingController.recordMovement(movement);
          break;

        case _AdjustmentType.produitFini:
          final stockState = await stockController.fetchSnapshot();
          final stockItems = stockState.items;

          StockItem? packStock;
          try {
            packStock = stockItems.firstWhere(
              (item) =>
                  item.type == StockType.finishedGoods &&
                  item.name.toLowerCase().contains(packName.toLowerCase()),
            );
          } catch (_) {}

          if (packStock == null && !isAddition) {
             throw const NotFoundException('Stock $packName non trouvé.');
          }

          if (!isAddition && packStock != null && packStock.quantity < quantite) {
            throw ValidationException('Stock insuffisant (${packStock.quantity.toInt()} disponible).');
          }

          final movementType = isAddition ? StockMovementType.entry : StockMovementType.exit;

          if (isAddition && packStock == null) {
            // S'assurer que l'item existe pour l'ajout
            packStock = await stockController.ensureStockItemForProduct(
              productName: packName,
              unit: packUnit,
            );
          }

          await stockController.recordItemMovement(
            itemId: packStock!.id,
            itemName: packStock.name,
            type: movementType,
            quantity: quantite,
            unit: packStock.unit,
            reason: fullReason,
            notes: justificatif,
          );
          break;
      }

      if (!mounted) return false;

      ref.invalidate(stockStateProvider);
      ref.invalidate(stockMovementsProvider);
      
      final label = isAddition ? 'ajouté(s)' : 'retiré(s)';
      NotificationService.showSuccess(context, 'Stock mis à jour ($label)');

      return true;
    } catch (e) {
      if (!mounted) return false;
      NotificationService.showError(context, e.toString().replaceAll('Exception: ', ''));
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

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DIRECTION (GROS ICONES POUR NON-LECTEURS)
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

            // 2. TYPE DE STOCK (AVEC ICONES CLAIRES)
            ElyfCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              backgroundColor: colors.surfaceContainerLow,
              child: SegmentedButton<_AdjustmentType>(
                segments: const [
                  ButtonSegment(
                    value: _AdjustmentType.bobine,
                    label: Text('BOBINE'),
                    icon: Icon(Icons.repeat_rounded, size: 20),
                  ),
                  ButtonSegment(
                    value: _AdjustmentType.emballage,
                    label: Text('SACHET'),
                    icon: Icon(Icons.layers_rounded, size: 20),
                  ),
                  ButtonSegment(
                    value: _AdjustmentType.produitFini,
                    label: Text('PACK'),
                    icon: Icon(Icons.local_drink_rounded, size: 20),
                  ),
                ],
                selected: {_selectedType},
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorTheme.withAlpha(25),
                  selectedForegroundColor: colorTheme,
                  side: BorderSide(color: colorTheme.withAlpha(50)),
                ),
                onSelectionChanged: (newVal) => setState(() => _selectedType = newVal.first),
              ),
            ),
            const SizedBox(height: 16),

            // 3. QUANTITÉ (GROS TEXTE)
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              borderColor: colorTheme.withAlpha(70),
              backgroundColor: colorTheme.withAlpha(5),
              child: Column(
                children: [
                  if (_selectedType == _AdjustmentType.emballage) _buildPkgToggle(),
                  TextFormField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.numbers_rounded, color: colorTheme),
                      labelText: isAdd ? 'Combien on ajoute ?' : 'Combien on retire ?',
                      labelStyle: TextStyle(color: colorTheme, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                      suffixText: _getSuffix(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorTheme,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (v) => (v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0) ? 'Entrez un nombre' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. JUSTIFICATIF (SIMPLE ET AVEC CHOIX)
            Text(
              'Raison (Facultatif mais recommandé)',
              style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildReasonChip('Erreur de saisie'),
                _buildReasonChip('Perte / Casse'),
                _buildReasonChip('Inventaire'),
                _buildReasonChip('Don / Échantillon'),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _justificatifController,
              decoration: _buildInputDecoration(
                label: 'Ou écrivez ici...',
                icon: Icons.chat_bubble_outline_rounded,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            if (widget.showSubmitButton) _buildSubmitButton(colorTheme),
          ],
        ),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : activeColor.withAlpha(50),
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: activeColor.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : activeColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : activeColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPkgToggle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text('UNITÉS'),
            selected: !_useLots,
            onSelected: (v) => setState(() => _useLots = false),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('LOTS'),
            selected: _useLots,
            onSelected: (v) => setState(() => _useLots = true),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(String reason) {
    return ActionChip(
      label: Text(reason, style: const TextStyle(fontSize: 12)),
      onPressed: () => setState(() => _justificatifController.text = reason),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _getSuffix() {
    if (_selectedType == _AdjustmentType.bobine) return 'bob.';
    if (_selectedType == _AdjustmentType.emballage) return _useLots ? 'lots' : 'unit.';
    return 'packs';
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, required Color color}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: color),
      filled: true,
      fillColor: color.withAlpha(10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  Widget _buildSubmitButton(Color color) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => submit(),
      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_rounded),
      label: Text(_direction == _AdjustmentDirection.addition ? 'VALIDER L\'AJOUT' : 'VALIDER LE RETRAIT'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
