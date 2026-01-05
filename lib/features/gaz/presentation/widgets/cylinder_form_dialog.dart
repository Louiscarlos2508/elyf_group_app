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
  final _sellPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();

  int? _selectedWeight;
  bool _isLoading = false;
  String? _enterpriseId;
  String? _moduleId;

  @override
  void initState() {
    super.initState();
    _enterpriseId ??= 'gaz_1';
    _moduleId ??= 'gaz';

    if (widget.cylinder != null) {
      _selectedWeight = widget.cylinder!.weight;
      _weightController.text = widget.cylinder!.weight.toString();
      _sellPriceController.text = widget.cylinder!.sellPrice.toStringAsFixed(0);
      _enterpriseId = widget.cylinder!.enterpriseId;
      _moduleId = widget.cylinder!.moduleId;
      
      // Charger le prix en gros depuis les settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWholesalePrice();
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sellPriceController.dispose();
    _wholesalePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadWholesalePrice() async {
    if (_enterpriseId == null || _moduleId == null || _selectedWeight == null) {
      return;
    }

    try {
      final settingsController = ref.read(gazSettingsControllerProvider);
      final wholesalePrice = await settingsController.getWholesalePrice(
        enterpriseId: _enterpriseId!,
        moduleId: _moduleId!,
        weight: _selectedWeight!,
      );

      if (wholesalePrice != null && wholesalePrice > 0 && mounted) {
        _wholesalePriceController.text = wholesalePrice.toStringAsFixed(0);
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await CylinderSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedWeight: _selectedWeight,
      weightText: _weightController.text,
      sellPriceText: _sellPriceController.text,
      wholesalePriceText: _wholesalePriceController.text,
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
                  // Poids (saisie libre)
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Poids (kg) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.scale),
                      hintText: 'Ex: 3, 6, 10, 12...',
                      helperText: 'Entrez le poids de la bouteille en kg',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      final weight = int.tryParse(value);
                      setState(() {
                        _selectedWeight = weight;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un poids';
                      }
                      final weight = int.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Le poids doit être un nombre positif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Prix détail
                  TextFormField(
                    controller: _sellPriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix détail (FCFA) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'FCFA',
                      helperText: 'Prix de vente au détail',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un prix détail';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Prix invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Prix en gros (optionnel)
                  TextFormField(
                    controller: _wholesalePriceController,
                    decoration: InputDecoration(
                      labelText: 'Prix en gros (FCFA)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.store),
                      suffixText: 'FCFA',
                      helperText: 'Prix de vente en gros (optionnel)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Prix invalide';
                        }
                        if (_sellPriceController.text.isNotEmpty) {
                          final sellPrice =
                              double.tryParse(_sellPriceController.text) ?? 0;
                          if (price >= sellPrice) {
                            return 'Le prix en gros doit être inférieur au prix détail';
                          }
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
