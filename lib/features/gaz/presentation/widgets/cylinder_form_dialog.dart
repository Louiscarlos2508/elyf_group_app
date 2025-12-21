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

class _CylinderFormDialogState extends ConsumerState<CylinderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();

  int? _selectedWeight;
  bool _isLoading = false;
  String? _enterpriseId;
  String? _moduleId;

  final List<int> _availableWeights = [3, 6, 10, 12];

  @override
  void initState() {
    super.initState();
    // TODO: Récupérer enterpriseId et moduleId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';
    _moduleId ??= 'gaz';

    if (widget.cylinder != null) {
      _selectedWeight = widget.cylinder!.weight;
      _weightController.text = widget.cylinder!.weight.toString();
      _buyPriceController.text = widget.cylinder!.buyPrice.toStringAsFixed(0);
      _sellPriceController.text = widget.cylinder!.sellPrice.toStringAsFixed(0);
      _enterpriseId = widget.cylinder!.enterpriseId;
      _moduleId = widget.cylinder!.moduleId;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWeight == null || _enterpriseId == null || _moduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(cylinderControllerProvider);
      final weight = int.tryParse(_weightController.text) ?? _selectedWeight!;
      final buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
      final sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;

      final cylinder = Cylinder(
        id: widget.cylinder?.id ??
            'cyl-${DateTime.now().millisecondsSinceEpoch}',
        weight: weight,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        enterpriseId: _enterpriseId!,
        moduleId: _moduleId!,
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
                  // Poids
                  DropdownButtonFormField<int>(
                    value: _selectedWeight,
                    decoration: InputDecoration(
                      labelText: 'Poids (kg) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    items: _availableWeights.map((weight) {
                      return DropdownMenuItem(
                        value: weight,
                        child: Text('$weight kg'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWeight = value;
                        if (value != null) {
                          _weightController.text = value.toString();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un poids';
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
                  const SizedBox(height: 24),
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
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
                                  widget.cylinder == null ? 'Créer' : 'Enregistrer',
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