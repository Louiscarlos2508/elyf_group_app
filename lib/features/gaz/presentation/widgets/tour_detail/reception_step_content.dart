import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/tour.dart';

/// Contenu de l'étape Réception du tour.
///
/// Permet de saisir les bouteilles pleines reçues du fournisseur
/// et le coût d'achat du gaz.
class ReceptionStepContent extends ConsumerStatefulWidget {
  const ReceptionStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  ConsumerState<ReceptionStepContent> createState() =>
      _ReceptionStepContentState();
}

class _ReceptionStepContentState extends ConsumerState<ReceptionStepContent> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _exchangeFeeControllers = {};
  late final TextEditingController _costController;
  late final TextEditingController _fixedUnloadingFeeController;
  late final TextEditingController _supplierController;
  final List<int> _commonWeights = [3, 6, 12, 38];

  @override
  void initState() {
    super.initState();
    for (final weight in _commonWeights) {
      _controllers[weight] = TextEditingController(
        text: (widget.tour.fullBottlesReceived[weight] ?? 0).toString(),
      );
      _exchangeFeeControllers[weight] = TextEditingController(
        text: (widget.tour.exchangeFees[weight] ?? 0.0).toString(),
      );
    }
    _costController = TextEditingController(
      text: (widget.tour.gasPurchaseCost ?? 0).toString(),
    );
    _fixedUnloadingFeeController = TextEditingController(
      text: (widget.tour.fixedUnloadingFee).toString(),
    );
    _supplierController = TextEditingController(
      text: widget.tour.supplierName ?? '',
    );

    // Charger les frais d'échange par défaut si vide
    if (widget.tour.exchangeFees.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDefaultExchangeFees();
      });
    }
  }

  Future<void> _loadDefaultExchangeFees() async {
    final settingsAsync = await ref.read(gazSettingsControllerProvider).getSettings(
          enterpriseId: widget.enterpriseId,
          moduleId: 'gaz',
        );
    if (settingsAsync != null && mounted) {
      setState(() {
        for (final weight in _commonWeights) {
          final purchasePrice = settingsAsync.getPurchasePrice(weight);
          final fee = purchasePrice ?? settingsAsync.getSupplierExchangeFee(weight);
          if (fee != null && fee > 0) {
            _exchangeFeeControllers[weight]?.text = fee.toStringAsFixed(0);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _exchangeFeeControllers.values) {
      controller.dispose();
    }
    _costController.dispose();
    _fixedUnloadingFeeController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElyfCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Réception des bouteilles pleines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: 'Nom du fournisseur',
                  hintText: 'Ex: SODIGAZ, TOTAL...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),
              // Tableau des bouteilles et frais d'échange
              Text(
                'Quantités et Frais d\'échange',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._commonWeights.map((weight) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        SizedBox(width: 50, child: Text('$weight kg')),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _controllers[weight],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Qté',
                              suffixText: 'btl',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _exchangeFeeControllers[weight],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Frais éch.',
                              suffixText: 'F',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              // Coûts fixes
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Coût d\'achat gaz',
                        suffixText: 'F',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fixedUnloadingFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Frais déchargement fixe',
                        suffixText: 'F',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saveReception,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Enregistrer la réception'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveReception() async {
    final fullBottles = <int, int>{};
    final exchangeFees = <int, double>{};
    for (final weight in _commonWeights) {
      final qty = int.tryParse(_controllers[weight]?.text ?? '') ?? 0;
      if (qty > 0) fullBottles[weight] = qty;
      
      final fee = double.tryParse(_exchangeFeeControllers[weight]?.text ?? '') ?? 0.0;
      if (fee > 0) exchangeFees[weight] = fee;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final gasCost = double.tryParse(_costController.text) ?? 0.0;
      final fixedUnloading = double.tryParse(_fixedUnloadingFeeController.text) ?? 0.0;
      
      final updatedTour = widget.tour.copyWith(
        fullBottlesReceived: fullBottles,
        exchangeFees: exchangeFees,
        gasPurchaseCost: gasCost,
        fixedUnloadingFee: fixedUnloading,
        supplierName: _supplierController.text.isNotEmpty ? _supplierController.text : null,
        updatedAt: DateTime.now(),
      );
      
      await controller.updateTour(updatedTour);

      if (mounted) {
        NotificationService.showSuccess(context, 'Réception enregistrée');
        ref.invalidate(tourProvider(widget.tour.id));
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
