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

/// Formulaire pour retirer des stocks (bobines, emballages, produits finis).
/// 
/// Utilisé pour les corrections d'inventaire (retraits uniquement).
/// Pour les ajouts, utiliser le formulaire d'approvisionnement.
class StockAdjustmentForm extends ConsumerStatefulWidget {
  const StockAdjustmentForm({
    super.key,
    this.showSubmitButton = true,
    this.onSubmit,
  });

  /// Afficher le bouton de soumission dans le formulaire.
  final bool showSubmitButton;

  /// Callback optionnel pour la soumission (utilisé par FormDialog).
  final Future<bool> Function()? onSubmit;

  @override
  ConsumerState<StockAdjustmentForm> createState() =>
      StockAdjustmentFormState();
}

enum _AdjustmentType { bobine, emballage, produitFini }

class StockAdjustmentFormState
    extends ConsumerState<StockAdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _justificatifController = TextEditingController();

  _AdjustmentType _selectedType = _AdjustmentType.bobine;
  bool _useLots = false; // Toggle pour saisir en lots au lieu d'unités
  bool _isLoading = false;

  // Type fixe pour toutes les bobines
  static const String _bobineType = 'Bobine';

  @override
  void dispose() {
    _quantityController.dispose();
    _justificatifController.dispose();
    super.dispose();
  }

  /// Méthode publique pour soumettre le formulaire (utilisée par FormDialog).
  Future<bool> submit() async {
    if (widget.onSubmit != null) {
      return await widget.onSubmit!();
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
          'Le justificatif est obligatoire pour les ajustements',
        );
        return false;
      }

      switch (_selectedType) {
        case _AdjustmentType.bobine:
          // Récupérer le stock de bobines
          final bobineController =
              ref.read(bobineStockQuantityControllerProvider);
          var stock = await bobineController.fetchByType(_bobineType);

          if (stock == null) {
            throw NotFoundException('Stock de bobines non trouvé');
          }

          // Vérifier que le stock est suffisant pour le retrait
          final currentQuantity = stock.quantity;
          final quantiteInt = quantite.toInt();
          
          if (currentQuantity < quantiteInt) {
            throw ValidationException(
              'Stock insuffisant. Stock actuel: $currentQuantity, '
              'Demandé: $quantiteInt',
            );
          }

          // Enregistrer le mouvement d'ajustement (retrait uniquement)
          final movementType = BobineMovementType.retrait;

          final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
          final movement = BobineStockMovement(
            id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
            enterpriseId: enterpriseId,
            bobineId: stock.id,
            bobineReference: _bobineType,
            type: movementType,
            date: DateTime.now(),
            quantite: quantite,
            raison: 'Ajustement: $justificatif',
            notes: justificatif,
            createdAt: DateTime.now(),
          );
          // recordMovement met automatiquement à jour le stock
          await bobineController.recordMovement(movement);
          break;

        case _AdjustmentType.emballage:
          // Récupérer le stock d'emballages
          final packagingController =
              ref.read(packagingStockControllerProvider);
          var packagingStock = await packagingController.fetchByType('Emballage');

          if (packagingStock == null) {
            throw NotFoundException('Stock d\'emballages non trouvé');
          }

          // Calculer la quantité en unités si lots sélectionnés
          int quantiteInt = quantite.toInt();
          String quantiteLabel = '$quantiteInt unités';
          
          if (_useLots) {
             final unitsPerLot = packagingStock.unitsPerLot;
             quantiteInt = (quantite * unitsPerLot).toInt();
             quantiteLabel = '${quantite.toInt()} lots (soit $quantiteInt unités)';
          }

          // Vérifier que le stock est suffisant pour le retrait
          if (packagingStock.quantity < quantiteInt) {
            throw ValidationException(
              'Stock insuffisant. Stock actuel: ${packagingStock.quantity}, '
              'Demandé: $quantiteLabel',
            );
          }

          // Enregistrer le mouvement d'ajustement (retrait uniquement)
          // recordMovement met automatiquement à jour le stock (comme pour les bobines)
          final movementType = PackagingMovementType.ajustement;

          final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
          final movement = PackagingStockMovement(
            id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
            enterpriseId: enterpriseId,
            packagingId: packagingStock.id,
            packagingType: 'Emballage',
            type: movementType,
            date: DateTime.now(),
            quantite: quantiteInt,
            raison: 'Ajustement: $justificatif',
            notes: justificatif,
            createdAt: DateTime.now(),
          );
          // recordMovement met automatiquement à jour le stock
          await packagingController.recordMovement(movement);
          break;

        case _AdjustmentType.produitFini:
          // Récupérer le stock de produits finis
          final stockState = await stockController.fetchSnapshot();
          final stockItems = stockState.items;

          // Pack uniquement (même qu'en stock / paramètres / ventes)
          StockItem packStock;
          try {
            packStock = stockItems.firstWhere(
              (item) =>
                  item.type == StockType.finishedGoods &&
                  item.name.toLowerCase().contains(packName.toLowerCase()),
            );
          } catch (_) {
            throw NotFoundException(
              'Stock $packName non trouvé. Créez un item « $packName » '
              'en produits finis.',
            );
          }

          // Vérifier que le stock est suffisant pour le retrait
          final currentQuantity = packStock.quantity;
          
          if (currentQuantity < quantite) {
            throw ValidationException(
              'Stock insuffisant. Stock actuel: $currentQuantity, '
              'Demandé: $quantite',
            );
          }

          // Enregistrer le mouvement d'ajustement (retrait uniquement)
          final movementType = StockMovementType.exit;

          await stockController.recordItemMovement(
            itemId: packStock.id,
            itemName: packStock.name,
            type: movementType,
            quantity: quantite,
            unit: packStock.unit,
            reason: 'Ajustement: $justificatif',
            notes: justificatif,
          );
          break;
      }

      if (!mounted) return false;

      // Invalider les providers pour rafraîchir l'affichage
      ref.invalidate(stockStateProvider);
      // Invalider tous les providers de mouvements pour rafraîchir l'historique
      // Note: stockMovementsProvider est un family provider, donc on doit invalider
      // tous les paramètres possibles. On utilise invalidateAll pour être sûr.
      ref.invalidate(stockMovementsProvider);
      
      final typeLabel = _selectedType == _AdjustmentType.bobine
          ? 'bobine(s)'
          : _selectedType == _AdjustmentType.emballage
          ? (_useLots ? 'lot(s) d\'emballages' : 'emballage(s)')
          : 'pack(s)';
      final message =
          '${quantite.toStringAsFixed(0)} $typeLabel retiré(s)';
      NotificationService.showSuccess(context, message);

      // Ne pas fermer le dialog ici - le FormDialog le fera automatiquement
      // si on retourne true
      return true;
    } catch (e) {
      if (!mounted) return false;
      
      // Gérer les exceptions de manière cohérente
      String errorMessage;
      if (e is AppException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.isEmpty) {
          errorMessage = 'Erreur lors de l\'ajustement. Veuillez réessayer.';
        }
      }
      
      NotificationService.showError(context, errorMessage);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    await submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final quantite = double.tryParse(_quantityController.text) ?? 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Type de Stock
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Type de Stock à Ajuster',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<_AdjustmentType>(
                    segments: const [
                      ButtonSegment(
                        value: _AdjustmentType.bobine,
                        label: Text('Bobine'),
                        icon: Icon(Icons.repeat_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: _AdjustmentType.emballage,
                        label: Text('Emb.'),
                        icon: Icon(Icons.layers_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: _AdjustmentType.produitFini,
                        label: Text('Pack'),
                        icon: Icon(Icons.shopping_bag_rounded, size: 18),
                      ),
                    ],
                    selected: {_selectedType},
                    style: SegmentedButton.styleFrom(
                      side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                      selectedBackgroundColor: colors.primary,
                      selectedForegroundColor: colors.onPrimary,
                    ),
                    onSelectionChanged: (Set<_AdjustmentType> newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Quantité & Justificatif
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Détails de l\'Ajustement',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedType == _AdjustmentType.emballage) ...[
                    // Toggle Lot vs Unité
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUnitToggleSegment(
                              isSelected: !_useLots,
                              label: 'Unités',
                              onTap: () => setState(() => _useLots = false),
                            ),
                          ),
                          Expanded(
                            child: _buildUnitToggleSegment(
                              isSelected: _useLots,
                              label: 'Lots',
                              onTap: () => setState(() => _useLots = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _quantityController,
                    decoration: _buildInputDecoration(
                      label: 'Quantité à retirer *',
                      icon: Icons.numbers_rounded,
                      hintText: '0',
                      helperText: _selectedType == _AdjustmentType.bobine
                          ? 'Nombre de bobines'
                          : _selectedType == _AdjustmentType.emballage
                          ? (_useLots ? 'Nombre de lots' : 'Nombre d\'emballages')
                          : 'Nombre de packs',
                      suffixText: _selectedType == _AdjustmentType.emballage && _useLots
                          ? 'lot${quantite > 1 ? 's' : ''}'
                          : 'unité${quantite > 1 ? 's' : ''}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      final qty = double.tryParse(v);
                      if (qty == null || qty <= 0) return 'Quantité invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _justificatifController,
                    decoration: _buildInputDecoration(
                      label: 'Justificatif *',
                      icon: Icons.description_rounded,
                      hintText: 'Raison de l\'ajustement...',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obligatoire';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (widget.showSubmitButton) _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitToggleSegment({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? helperText,
    String? suffixText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      suffixText: suffixText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'RETIRER DU STOCK',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
    );
  }
}
