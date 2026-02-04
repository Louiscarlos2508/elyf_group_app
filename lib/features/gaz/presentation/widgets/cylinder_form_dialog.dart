import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../domain/entities/cylinder.dart';
import 'cylinder_form/cylinder_submit_handler.dart';

/// Dialogue pour créer ou modifier une bouteille de gaz.
class CylinderFormDialog extends ConsumerStatefulWidget {
  const CylinderFormDialog({super.key, this.cylinder});

  final Cylinder? cylinder;

  @override
  ConsumerState<CylinderFormDialog> createState() => _CylinderFormDialogState();
}

class _CylinderFormDialogState extends ConsumerState<CylinderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _buyPriceController = TextEditingController();

  int? _selectedWeight;
  bool _isLoading = false;
  String? _enterpriseId;
  String? _moduleId;

  @override
  void initState() {
    super.initState();
    // Les valeurs seront initialisées dans build() avec activeEnterpriseProvider

    if (widget.cylinder != null) {
      _selectedWeight = widget.cylinder!.weight;
      _weightController.text = widget.cylinder!.weight.toString();
      _sellPriceController.text = widget.cylinder!.sellPrice.toStringAsFixed(0);
      _buyPriceController.text = widget.cylinder!.buyPrice.toStringAsFixed(0);
      _enterpriseId = widget.cylinder!.enterpriseId;
      _moduleId = widget.cylinder!.moduleId;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sellPriceController.dispose();
    _buyPriceController.dispose();
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
      buyPriceText: _buyPriceController.text,
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
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    activeEnterpriseAsync.whenData((enterprise) {
      if (_enterpriseId == null && enterprise != null) {
        _enterpriseId = enterprise.id;
        _moduleId = 'gaz';
      }
    });
    
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
              FilledButton(
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
                      labelText: 'Prix de vente',
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
                  
                  // Prix d'achat
                  TextFormField(
                    controller: _buyPriceController,
                    decoration: InputDecoration(
                      labelText: "Prix d'achat",
                      hintText: 'Optionnel',
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
                        if (_sellPriceController.text.isNotEmpty) {
                          final sellPrice = double.tryParse(_sellPriceController.text) ?? 0;
                          if (price >= sellPrice) {
                            return "Doit être inférieur au prix de vente";
                          }
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isLoading ? null : _saveCylinder,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.cylinder == null ? 'Créer' : 'Enregistrer'),
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
