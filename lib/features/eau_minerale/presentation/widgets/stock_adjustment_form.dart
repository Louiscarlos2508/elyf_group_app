import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/errors/app_exceptions.dart';
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

          final movement = BobineStockMovement(
            id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
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

          // Vérifier que le stock est suffisant pour le retrait
          final quantiteInt = quantite.toInt();
          if (packagingStock.quantity < quantiteInt) {
            throw ValidationException(
              'Stock insuffisant. Stock actuel: ${packagingStock.quantity}, '
              'Demandé: $quantiteInt',
            );
          }

          // Enregistrer le mouvement d'ajustement (retrait uniquement)
          // recordMovement met automatiquement à jour le stock (comme pour les bobines)
          final movementType = PackagingMovementType.ajustement;

          final movement = PackagingStockMovement(
            id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
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
          ? 'emballage(s)'
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type de stock à ajuster
            SegmentedButton<_AdjustmentType>(
              segments: const [
                ButtonSegment(
                  value: _AdjustmentType.bobine,
                  label: Text('Bobine'),
                  icon: Icon(Icons.repeat, size: 18),
                ),
                ButtonSegment(
                  value: _AdjustmentType.emballage,
                  label: Text('Emballage'),
                  icon: Icon(Icons.inventory_2, size: 18),
                ),
                ButtonSegment(
                  value: _AdjustmentType.produitFini,
                  label: Text('Produit Fini'),
                  icon: Icon(Icons.shopping_bag, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<_AdjustmentType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Quantité
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité *',
                prefixIcon: const Icon(Icons.numbers),
                helperText: _selectedType == _AdjustmentType.bobine
                    ? 'Nombre de bobines à retirer'
                    : _selectedType == _AdjustmentType.emballage
                    ? 'Nombre d\'emballages à retirer'
                    : 'Quantité de packs à retirer',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
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

            // Justificatif (obligatoire)
            TextFormField(
              controller: _justificatifController,
              decoration: const InputDecoration(
                labelText: 'Justificatif *',
                prefixIcon: Icon(Icons.description),
                helperText:
                    'Justificatif obligatoire pour tous les ajustements',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le justificatif est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Bouton de soumission (seulement si showSubmitButton est true)
            if (widget.showSubmitButton) ...[
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Retirer du stock'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
