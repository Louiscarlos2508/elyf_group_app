import 'package:flutter/material.dart';

/// Champ de sélection de catégorie générique.
///
/// Utilise un enum ou une liste de valeurs avec des labels personnalisés.
class CategorySelectorField<T> extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.labelBuilder,
    this.label = 'Catégorie',
    this.enabled = true,
    this.validator,
  });

  /// Valeur actuellement sélectionnée.
  final T value;

  /// Callback appelé lors du changement de valeur.
  final void Function(T?) onChanged;

  /// Liste des éléments disponibles.
  final List<T> items;

  /// Fonction pour générer le label d'un élément.
  final String Function(T) labelBuilder;

  /// Label du champ.
  final String label;

  /// Indique si le champ est activé.
  final bool enabled;

  /// Validateur optionnel.
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.category),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
