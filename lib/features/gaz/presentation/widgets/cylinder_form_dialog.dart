import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/cylinder_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';

/// Dialogue pour créer ou modifier une bouteille de gaz.
class CylinderFormDialog extends ConsumerStatefulWidget {
  const CylinderFormDialog({
    super.key,
    this.cylinder,
  });

  final Cylinder? cylinder;

  @override
  ConsumerState<CylinderFormDialog> createState() =>
      _CylinderFormDialogState();
}

class _CylinderFormDialogState
    extends ConsumerState<CylinderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  CylinderType? _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cylinder != null) {
      _selectedType = widget.cylinder!.type;
      _weightController.text = widget.cylinder!.weight.toString();
      _buyPriceController.text = widget.cylinder!.buyPrice.toStringAsFixed(0);
      _sellPriceController.text = widget.cylinder!.sellPrice.toStringAsFixed(0);
      _stockController.text = widget.cylinder!.stock.toString();
    } else {
      _stockController.text = '0';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de bouteille'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(cylinderControllerProvider);
      final weight = double.tryParse(_weightController.text) ?? 
          _selectedType!.defaultWeight;
      final buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
      final sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;

      final cylinder = Cylinder(
        id: widget.cylinder?.id ?? 
            'cyl-${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType!,
        weight: weight,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
      );

      if (widget.cylinder == null) {
        await controller.addCylinder(cylinder);
      } else {
        await controller.updateCylinder(cylinder);
      }

      if (!mounted) return;

      // Invalider le provider pour rafraîchir la liste
      ref.invalidate(cylindersProvider);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.cylinder == null
                ? 'Bouteille créée avec succès'
                : 'Bouteille mise à jour',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.cylinder == null
                              ? 'Nouvelle Bouteille'
                              : 'Modifier la Bouteille',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Type de bouteille
                  DropdownButtonFormField<CylinderType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type de bouteille *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department),
                    ),
                    items: CylinderType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        if (value != null && _weightController.text.isEmpty) {
                          _weightController.text =
                              value.defaultWeight.toString();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Poids
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Poids (kg) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.scale),
                      suffixText: 'kg',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un poids';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Poids invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Prix d'achat
                  TextFormField(
                    controller: _buyPriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix d\'achat (FCFA) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.shopping_cart),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un prix d\'achat';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Prix invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Prix de vente
                  TextFormField(
                    controller: _sellPriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix de vente (FCFA) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un prix de vente';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Prix invalide';
                      }
                      if (_buyPriceController.text.isNotEmpty) {
                        final buyPrice =
                            double.tryParse(_buyPriceController.text) ?? 0;
                        if (price < buyPrice) {
                          return 'Le prix de vente doit être supérieur au prix d\'achat';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Stock initial
                  TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Stock initial',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Stock invalide';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      IntrinsicWidth(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _saveCylinder,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.cylinder == null
                                      ? 'Créer'
                                      : 'Enregistrer',
                                ),
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
