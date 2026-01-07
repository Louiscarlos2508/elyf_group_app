import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';

/// Formulaire pour ajouter des matières premières en stock (bobines, emballages, autres).
class StockEntryForm extends ConsumerStatefulWidget {
  const StockEntryForm({super.key});

  @override
  ConsumerState<StockEntryForm> createState() => _StockEntryFormState();
}

enum _StockEntryType {
  bobine,
  emballage,
  produitFini,
}

class _StockEntryFormState extends ConsumerState<StockEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _typeController = TextEditingController(); // Type de bobine (ex: "Bobine standard")
  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  _StockEntryType _selectedType = _StockEntryType.bobine;
  StockMovementType _movementType = StockMovementType.entry; // Pour produits finis uniquement
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialiser la valeur par défaut du type de bobine
    _typeController.text = 'Bobine standard';
  }
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _typeController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final stockController = ref.read(stockControllerProvider);
      final quantiteStr = _quantityController.text;
      final quantite = _selectedType == _StockEntryType.produitFini
          ? double.parse(quantiteStr)
          : double.parse(quantiteStr); // Utiliser double pour tous les cas

      switch (_selectedType) {
        case _StockEntryType.bobine:
          final prixUnitaire = _priceController.text.isEmpty
              ? null
              : int.tryParse(_priceController.text);
          
          // Utiliser le nouveau système de stock par type/quantité
          final bobineType = _typeController.text.isEmpty 
              ? 'Bobine standard' 
              : _typeController.text;
          
          // Enregistrer l'entrée de bobines (ajoute à la quantité du type)
          await stockController.recordBobineEntry(
            bobineType: bobineType,
            quantite: quantite.toInt(),
            fournisseur: _supplierController.text.isEmpty ? null : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;

        case _StockEntryType.emballage:
          final prixUnitaire = _priceController.text.isEmpty
              ? null
              : int.tryParse(_priceController.text);
          
          // Récupérer ou créer le stock d'emballages
          final packagingRepo = ref.read(packagingStockRepositoryProvider);
          var stockEmballage = await packagingRepo.fetchByType('Emballage');
          
          if (stockEmballage == null) {
            // Créer un nouveau stock d'emballages
            stockEmballage = PackagingStock(
              id: 'packaging-${DateTime.now().millisecondsSinceEpoch}',
              type: 'Emballage',
              quantity: 0,
              unit: 'unité',
              fournisseur: _supplierController.text.isEmpty ? null : _supplierController.text,
              prixUnitaire: prixUnitaire,
              createdAt: _selectedDate,
              updatedAt: _selectedDate,
            );
            stockEmballage = await packagingRepo.save(stockEmballage);
          }
          
          // Enregistrer l'entrée
          await stockController.recordPackagingEntry(
            packagingId: stockEmballage.id,
            packagingType: 'Emballage',
            quantite: quantite.toInt(),
            fournisseur: _supplierController.text.isEmpty ? null : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;

        case _StockEntryType.produitFini:
          // Récupérer le stock de produits finis
          final stockState = await stockController.fetchSnapshot();
          final stockItems = stockState.items;
          
          // Chercher le stock de produits finis (Pack)
          StockItem packStock;
          try {
            packStock = stockItems.firstWhere(
              (item) => item.type == StockType.finishedGoods &&
                  item.name.toLowerCase().contains('pack'),
            );
          } catch (_) {
            try {
              packStock = stockItems.firstWhere(
                (item) => item.type == StockType.finishedGoods,
              );
            } catch (_) {
              // Créer un nouveau stock de produits finis si aucun n'existe
              packStock = StockItem(
                id: 'pack-1',
                name: 'Pack',
                quantity: 0,
                unit: 'unité',
                type: StockType.finishedGoods,
                updatedAt: DateTime.now(),
              );
              // Le stock sera créé lors de la première mise à jour via recordItemMovement
              // Mais on doit d'abord l'enregistrer dans le repository
              final inventoryRepo = ref.read(inventoryRepositoryProvider);
              final allItems = await inventoryRepo.fetchStockItems();
              if (!allItems.any((item) => item.id == packStock.id)) {
                await inventoryRepo.updateStockItem(packStock);
              }
            }
          }
          
          // Ajuster le stock (entrée ou sortie) - packStock est toujours non-null ici
          final finalPackStock = packStock;
          await stockController.recordItemMovement(
            itemId: finalPackStock.id,
            itemName: finalPackStock.name,
            type: _movementType,
            quantity: quantite,
            unit: finalPackStock.unit,
            reason: _notesController.text.isEmpty 
                ? (_movementType == StockMovementType.entry ? 'Ajustement entrée' : 'Ajustement sortie')
                : _notesController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(stockStateProvider);
      final message = _selectedType == _StockEntryType.bobine
          ? '${quantite.toInt()} bobine(s) ajoutée(s)'
          : _selectedType == _StockEntryType.emballage
              ? '${quantite.toInt()} emballage(s) ajouté(s)'
              : _movementType == StockMovementType.entry
                  ? '${quantite.toStringAsFixed(0)} pack(s) ajouté(s) au stock'
                  : '${quantite.toStringAsFixed(0)} pack(s) retiré(s) du stock';
      NotificationService.showSuccess(context, message);
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantite = int.tryParse(_quantityController.text) ?? 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type de matière première
            SegmentedButton<_StockEntryType>(
              segments: const [
                ButtonSegment(
                  value: _StockEntryType.bobine,
                  label: Text('Bobine'),
                  icon: Icon(Icons.repeat, size: 18),
                ),
                ButtonSegment(
                  value: _StockEntryType.emballage,
                  label: Text('Emballage'),
                  icon: Icon(Icons.inventory_2, size: 18),
                ),
                ButtonSegment(
                  value: _StockEntryType.produitFini,
                  label: Text('Produit Fini'),
                  icon: Icon(Icons.shopping_bag, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<_StockEntryType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Type de mouvement (uniquement pour produits finis)
            if (_selectedType == _StockEntryType.produitFini) ...[
              SegmentedButton<StockMovementType>(
                segments: const [
                  ButtonSegment(
                    value: StockMovementType.entry,
                    label: Text('Ajout'),
                    icon: Icon(Icons.add_circle_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: StockMovementType.exit,
                    label: Text('Retrait'),
                    icon: Icon(Icons.remove_circle_outline, size: 18),
                  ),
                ],
                selected: {_movementType},
                onSelectionChanged: (Set<StockMovementType> newSelection) {
                  setState(() {
                    _movementType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // Date de réception
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de réception',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Quantité
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                prefixIcon: const Icon(Icons.numbers),
                suffixText: 'unité${quantite > 1 ? 's' : ''}',
                helperText: _selectedType == _StockEntryType.bobine
                    ? 'Nombre de bobines à ajouter'
                    : _selectedType == _StockEntryType.emballage
                        ? 'Nombre d\'emballages à ajouter'
                        : _movementType == StockMovementType.entry
                            ? 'Quantité de packs à ajouter au stock'
                            : 'Quantité de packs à retirer du stock',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final qty = double.tryParse(v);
                if (qty == null || qty <= 0) return 'Quantité invalide';
                if (_selectedType == _StockEntryType.produitFini && _movementType == StockMovementType.exit) {
                  // Pour les retraits, vérifier que le stock est suffisant
                  // Cette validation sera faite côté serveur dans recordItemMovement
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Type de bobine (uniquement pour bobines)
            if (_selectedType == _StockEntryType.bobine) ...[
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type de bobine',
                  prefixIcon: Icon(Icons.category),
                  helperText: 'Ex: "Bobine standard", "Bobine grande taille" (par défaut: "Bobine standard")',
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Fournisseur
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),
            const SizedBox(height: 16),
            
            // Prix unitaire (pas pour produits finis)
            if (_selectedType != _StockEntryType.produitFini) ...[
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (FCFA, optionnel)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final price = int.tryParse(v);
                    if (price == null || price < 0) return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Bouton de soumission
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ajouter au stock'),
            ),
          ],
        ),
      ),
    );
  }
}
