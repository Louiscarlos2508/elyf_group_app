import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Champ pour l'index compteur électrique initial.
class IndexCompteurInitialField extends ConsumerWidget {
  const IndexCompteurInitialField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '${meterType.initialLabel} *',
            prefixIcon: const Icon(Icons.bolt),
            helperText: meterType.initialHelperText,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            final cleanedValue = value.replaceAll(',', '.');
            final doubleValue = double.tryParse(cleanedValue);
            if (doubleValue == null) {
              return 'Nombre invalide';
            }
            if (doubleValue < 0) {
              return 'Le nombre doit être positif';
            }
            return null;
          },
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
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Index compteur initial *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

