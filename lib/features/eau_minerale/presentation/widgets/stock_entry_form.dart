
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/packaging_stock.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';

/// Formulaire pour ajouter des matières premières en stock (bobines, emballages, autres).
class StockEntryForm extends ConsumerStatefulWidget {
  const StockEntryForm({
    super.key,
    this.showSubmitButton = true,
    this.onSubmit,
  });

  /// Afficher le bouton de soumission dans le formulaire.
  /// Si false, le bouton n'est pas affiché (pour utiliser le bouton du FormDialog).
  final bool showSubmitButton;

  /// Callback optionnel pour la soumission (utilisé par FormDialog).
  final Future<bool> Function()? onSubmit;

  @override
  ConsumerState<StockEntryForm> createState() => StockEntryFormState();
}

class StockEntryFormState extends ConsumerState<StockEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitsPerLotController = TextEditingController(text: '1000');

  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  bool _useLots = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _unitsPerLotController.dispose();
    super.dispose();
  }

  /// Méthode publique pour soumettre le formulaire (utilisée par FormDialog).
  Future<bool> submit() async {
    AppLogger.debug('StockEntryForm.submit() called', name: 'StockEntryForm');
    
    if (widget.onSubmit != null) {
      AppLogger.debug('Using widget.onSubmit', name: 'StockEntryForm');
      return await widget.onSubmit!();
    }
    
    if (!_formKey.currentState!.validate()) {
      AppLogger.debug('Form validation failed', name: 'StockEntryForm');
      return false;
    }

    final selectedProduct = _selectedProduct;
    if (selectedProduct == null) {
      throw const ValidationException('Veuillez sélectionner un produit', 'MISSING_PRODUCT');
    }

    AppLogger.debug('Starting stock entry submission', name: 'StockEntryForm');
    setState(() => _isLoading = true);
    try {
      final stockController = ref.read(stockControllerProvider);
      final quantiteStr = _quantityController.text.trim().replaceAll(',', '.');
      
      // Valider et parser la quantité
      if (quantiteStr.isEmpty) {
        throw const ValidationException('La quantité est requise', 'MISSING_QUANTITY');
      }
      
      final quantite = double.tryParse(quantiteStr);
      if (quantite == null || quantite <= 0) {
        throw const ValidationException('La quantité doit être un nombre positif', 'INVALID_QUANTITY');
      }
      
      AppLogger.debug('Quantité validée: $quantite, Produit: ${selectedProduct.name}', name: 'StockEntryForm');

      final isBobine = selectedProduct.name.toLowerCase().contains('bobine');

      if (isBobine) {
          await stockController.recordBobineEntry(
            bobineType: selectedProduct.name,
            quantite: quantite.round(), // Les bobines restent en int
            prixUnitaire: _priceController.text.isEmpty
                ? null
                : int.tryParse(_priceController.text),
            fournisseur: _supplierController.text.isEmpty
                ? null
                : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
      } else {
          final packagingId = 'packaging-${selectedProduct.name.toLowerCase().replaceAll(' ', '-')}';
          final packagingController = ref.read(packagingStockControllerProvider);
          var stockEmballage = await packagingController.fetchById(packagingId);

          if (stockEmballage == null) {
            final unitsPerLot = _useLots ? (int.tryParse(_unitsPerLotController.text) ?? selectedProduct.unitsPerLot) : selectedProduct.unitsPerLot;
            final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
            stockEmballage = PackagingStock(
              id: packagingId,
              enterpriseId: enterpriseId,
              type: selectedProduct.name,
              quantity: 0, 
              unit: selectedProduct.unit,
              unitsPerLot: unitsPerLot,
              fournisseur: _supplierController.text.isEmpty ? null : _supplierController.text,
              prixUnitaire: _priceController.text.isEmpty ? null : int.tryParse(_priceController.text),
              createdAt: _selectedDate,
              updatedAt: _selectedDate,
            );
            await packagingController.save(stockEmballage);
          } else if (_useLots) {
             final newUnitsPerLot = int.tryParse(_unitsPerLotController.text) ?? selectedProduct.unitsPerLot;
             if (newUnitsPerLot > 0 && stockEmballage.unitsPerLot != newUnitsPerLot) {
               await packagingController.save(stockEmballage.copyWith(unitsPerLot: newUnitsPerLot));
             }
          }

          int? prixFinalUnitaire;
          final prixSaisiStr = _priceController.text.trim();
          if (prixSaisiStr.isNotEmpty) {
            final prixSaisi = int.tryParse(prixSaisiStr) ?? 0;
            if (_useLots) {
              final unitsPerLot = int.tryParse(_unitsPerLotController.text) ?? stockEmballage.unitsPerLot;
              prixFinalUnitaire = (prixSaisi / (unitsPerLot > 0 ? unitsPerLot : 1)).round();
            } else {
              prixFinalUnitaire = prixSaisi;
            }
          }

          final unitsPerLot = _useLots ? (int.tryParse(_unitsPerLotController.text) ?? stockEmballage.unitsPerLot) : null;
          await stockController.recordPackagingEntry(
            packagingId: stockEmballage.id,
            packagingType: selectedProduct.name,
            quantite: quantite,
            prixUnitaire: prixFinalUnitaire,
            isInLots: _useLots,
            unitsPerLot: unitsPerLot,
            fournisseur: _supplierController.text.isEmpty ? null : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
      }

      if (!mounted) return false;
      
      ref.invalidate(stockStateProvider);
      ref.invalidate(stockMovementsProvider);
      
      final message = isBobine
          ? '$quantite bobine(s) ajoutée(s)'
          : '$quantite emballage(s) ajouté(s)';
      NotificationService.showSuccess(context, message);
      return true;
    } catch (e, stackTrace) {
      if (!mounted) return false;
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      NotificationService.showError(context, appException.message);
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
    final quantite = int.tryParse(_quantityController.text) ?? 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        'Matière Première',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ref.watch(rawMaterialsProvider).when(
                    data: (products) {
                      if (products.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Aucune matière première configurée dans le catalogue.',
                              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      
                      if (_selectedProduct == null && products.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedProduct = products.first);
                        });
                      }

                      return DropdownButtonFormField<Product>(
                        initialValue: _selectedProduct,
                        decoration: _buildInputDecoration(
                          label: 'Sélectionner une matière',
                          icon: Icons.category_rounded,
                        ),
                        items: products.map((p) {
                          return DropdownMenuItem<Product>(
                            value: p,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (p) {
                          setState(() {
                             _selectedProduct = p;
                             if (p != null) {
                               // Pour l'emballage, on force l'utilisation des lots
                               _useLots = p.name.toLowerCase().contains('emballage');
                               // Charger le facteur de conversion du produit
                               _unitsPerLotController.text = p.unitsPerLot.toString();
                             }
                          });
                        },
                        validator: (v) => v == null ? 'Requis' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Informations de Réception',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de réception',
                                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                                ),
                                Text(
                                  DateFormatter.formatLongDate(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _quantityController,
                    decoration: _buildInputDecoration(
                      label: 'Quantité',
                      icon: Icons.numbers_rounded,
                      hintText: _useLots ? 'Nombre de lots' : 'Nombre d\'unités',
                      suffixText: _useLots 
                          ? 'lot${quantite > 1 ? 's' : ''}'
                          : 'unité${quantite > 1 ? 's' : ''}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                    ],
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                      Icon(Icons.add_business_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Détails Supplémentaires',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _supplierController,
                    decoration: _buildInputDecoration(
                      label: 'Fournisseur (Optionnel)',
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: _buildInputDecoration(
                      label: (_selectedProduct != null && _selectedProduct!.name.toLowerCase().contains('emballage') && _useLots)
                          ? 'Prix du lot total (FCFA, Optionnel)'
                          : 'Prix unitaire (FCFA, Optionnel)',
                      icon: Icons.payments_rounded,
                      helperText: (_selectedProduct != null && _selectedProduct!.name.toLowerCase().contains('emballage') && _useLots)
                          ? 'Le système calculera automatiquement le prix à l\'unité'
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: _buildInputDecoration(
                      label: 'Notes (Optionnel)',
                      icon: Icons.note_alt_rounded,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (widget.showSubmitButton) ...[
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? suffixText,
    String? helperText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      helperText: helperText,
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
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
            'AJOUTER AU STOCK',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
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
}
