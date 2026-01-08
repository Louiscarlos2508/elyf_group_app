import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Champ pour la consommation électrique.
class ConsommationField extends ConsumerWidget {
  const ConsommationField({
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
            labelText: 'Consommation électrique (${meterType.unit}) *',
            prefixIcon: const Icon(Icons.bolt),
            helperText: 'Consommation électrique totale de la session',
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
          labelText: 'Consommation électrique *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

