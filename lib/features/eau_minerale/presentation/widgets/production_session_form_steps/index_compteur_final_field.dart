import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import 'production_session_form_helpers.dart';

/// Champ pour l'index compteur électrique final.
class IndexCompteurFinalField extends ConsumerWidget {
  const IndexCompteurFinalField({
    super.key,
    required this.indexCompteurInitialController,
    required this.indexCompteurFinalController,
    required this.consommationController,
  });

  final TextEditingController indexCompteurInitialController;
  final TextEditingController indexCompteurFinalController;
  final TextEditingController consommationController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              meterType.finalLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: indexCompteurFinalController,
              decoration: InputDecoration(
                labelText: '${meterType.finalLabel} *',
                prefixIcon: const Icon(Icons.bolt),
                helperText: meterType.finalHelperText,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                final cleanedValue = value.replaceAll(',', '.');
                final finalValue = double.tryParse(cleanedValue);
                if (finalValue == null) {
                  return 'Nombre invalide';
                }
                if (finalValue < 0) {
                  return 'Le nombre doit être positif';
                }
                final indexInitial = ProductionSessionFormHelpers
                    .parseIndexCompteur(indexCompteurInitialController.text);
                if (indexInitial != null) {
                  if (!meterType.isValidRange(
                    indexInitial.toDouble(),
                    finalValue,
                  )) {
                    return meterType.validationErrorMessage;
                  }
                }
                return null;
              },
              onChanged: (value) {
                final indexInitial = ProductionSessionFormHelpers
                    .parseIndexCompteur(indexCompteurInitialController.text);
                if (indexInitial != null && value.isNotEmpty) {
                  final cleanedValue = value.replaceAll(',', '.');
                  final finalValue = double.tryParse(cleanedValue);
                  if (finalValue != null) {
                    final consommation = meterType.calculateConsumption(
                      indexInitial.toDouble(),
                      finalValue,
                    );
                    consommationController.text = consommation.toStringAsFixed(2);
                  }
                }
              },
            ),
          ],
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Chargement...',
          prefixIcon: Icon(Icons.bolt),
        ),
        enabled: false,
      ),
      error: (_, __) => TextFormField(
        controller: indexCompteurFinalController,
        decoration: const InputDecoration(
          labelText: 'Index compteur final *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

