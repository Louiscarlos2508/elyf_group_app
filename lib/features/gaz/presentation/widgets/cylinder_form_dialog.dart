import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_button.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'cylinder_form/cylinder_submit_handler.dart';

/// Dialogue pour créer ou modifier une bouteille de gaz.
class CylinderFormDialog extends ConsumerStatefulWidget {
  const CylinderFormDialog({
    super.key, 
    this.cylinder,
    required this.enterpriseId,
    required this.moduleId,
  });

  final Cylinder? cylinder;
  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<CylinderFormDialog> createState() => _CylinderFormDialogState();
}

class _CylinderFormDialogState extends ConsumerState<CylinderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _initialFullStockController = TextEditingController();
  final _initialEmptyStockController = TextEditingController();

  int? _selectedWeight;
  bool _isLoading = false;
  String? _enterpriseId;
  String? _moduleId;

  @override
  void initState() {
    super.initState();
    // Les valeurs seront initialisées dans build() avec activeEnterpriseProvider
    
    _enterpriseId = widget.enterpriseId;
    _moduleId = widget.moduleId;

    if (widget.cylinder != null) {
      _selectedWeight = widget.cylinder!.weight;
      _weightController.text = widget.cylinder!.weight.toString();
      _sellPriceController.text = widget.cylinder!.sellPrice.toStringAsFixed(0);
      _buyPriceController.text = widget.cylinder!.buyPrice.toStringAsFixed(0);
    }

    // Initialiser tous les prix depuis les réglages (source de vérité prioritaire)
    _loadSettingsPrices();
  }

  Future<void> _loadSettingsPrices() async {
    if (widget.cylinder == null || _enterpriseId == null) return;
    
    final settings = await ref.read(gazSettingsControllerProvider).getSettings(
      enterpriseId: _enterpriseId!,
      moduleId: 'gaz',
    );
    
    if (settings != null && mounted) {
      final weight = widget.cylinder!.weight;
      final retailPrice = settings.getRetailPrice(weight);
      final wholesalePrice = settings.getWholesalePrice(weight);
      final purchasePrice = settings.getPurchasePrice(weight);

      if (retailPrice != null) {
        _sellPriceController.text = retailPrice.toStringAsFixed(0);
      }
      if (wholesalePrice != null) {
        _wholesalePriceController.text = wholesalePrice.toStringAsFixed(0);
      }
      if (purchasePrice != null) {
        _buyPriceController.text = purchasePrice.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sellPriceController.dispose();
    _wholesalePriceController.dispose();
    _buyPriceController.dispose();
    _initialFullStockController.dispose();
    _initialEmptyStockController.dispose();
    super.dispose();
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await CylinderSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedWeight: _selectedWeight,
      weightText: _weightController.text,
      sellPriceText: _sellPriceController.text,
      wholesalePriceText: _wholesalePriceController.text,
      buyPriceText: _buyPriceController.text,
      initialFullStockText: _initialFullStockController.text,
      initialEmptyStockText: _initialEmptyStockController.text,
      enterpriseId: _enterpriseId,
      moduleId: _moduleId,
      existingCylinder: widget.cylinder,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enterpriseId == null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'Aucune entreprise active',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Veuillez sélectionner une entreprise avant de continuer.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElyfButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.cylinder == null 
                              ? Icons.add_circle_outline 
                              : Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          widget.cylinder == null 
                              ? 'Nouveau type de bouteille' 
                              : 'Modifier le type de bouteille',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Poids
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Poids de la bouteille',
                      hintText: 'Ex: 6',
                      suffixText: 'kg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.scale_outlined),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(10), // Using withAlpha instead of withOpacity
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final weight = int.tryParse(value);
                      setState(() {
                        _selectedWeight = weight;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      final weight = int.tryParse(value);
                      if (weight == null || weight <= 0) return 'Invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Prix détail
                  TextFormField(
                    controller: _sellPriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix de vente (Détail)',
                      hintText: '0',
                      suffixText: 'FCFA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.sell_outlined),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(10),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      final price = double.tryParse(value);
                      if (price == null || price < 0) return 'Invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prix en gros
                  TextFormField(
                    controller: _wholesalePriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix de vente (Gros)',
                      hintText: 'Optionnel (Détail par défaut)',
                      suffixText: 'FCFA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.business_center_outlined),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(10),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) return 'Invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prix d'achat
                  TextFormField(
                    controller: _buyPriceController,
                    decoration: InputDecoration(
                      labelText: "Prix d'achat (Fournisseur)",
                      hintText: 'Utilisé pour les Appro/Tours',
                      suffixText: 'FCFA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.shopping_cart_outlined),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(10),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) return 'Invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  
                  if (widget.cylinder == null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Stock Initial (Plein/Vide)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _initialFullStockController,
                            decoration: InputDecoration(
                              labelText: 'Stock Plein',
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.inventory_2_outlined),
                              filled: true,
                              fillColor: Colors.grey.withAlpha(10),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _initialEmptyStockController,
                            decoration: InputDecoration(
                              labelText: 'Stock Vide',
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.inventory_outlined),
                              filled: true,
                              fillColor: Colors.grey.withAlpha(10),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElyfButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        variant: ElyfButtonVariant.text,
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElyfButton(
                        onPressed: _isLoading ? null : _saveCylinder,
                        isLoading: _isLoading,
                        child: Text(widget.cylinder == null ? 'Créer' : 'Enregistrer'),
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
