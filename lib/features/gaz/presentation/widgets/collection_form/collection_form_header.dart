import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// En-tête du formulaire de collecte.
class CollectionFormHeader extends StatelessWidget {
  const CollectionFormHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return FormDialogHeader(
      title: title ?? 'Ajouter une collecte',
      subtitle: subtitle ?? 'Enregistrez les bouteilles vides collectées',
    );
  }
}
