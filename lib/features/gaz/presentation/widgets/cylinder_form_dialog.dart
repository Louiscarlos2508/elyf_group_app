import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'cylinder_form/cylinder_form_header.dart';
import 'cylinder_form/cylinder_submit_handler.dart';

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

    setState(() => _isLoading = true);

    final success = await CylinderSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedWeight: _selectedWeight,
      weightText: _weightController.text,
      buyPriceText: _buyPriceController.text,
      sellPriceText: _sellPriceController.text,
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
                  CylinderFormHeader(isEditing: widget.cylinder != null),
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
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: GazButtonStyles.outlined,
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _saveCylinder,
                          style: GazButtonStyles.filledPrimary,
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
