import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// En-tête du formulaire de collecte.
class CollectionFormHeader extends StatelessWidget {
  const CollectionFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormDialogHeader(
      title: 'Ajouter une collecte',
      subtitle: 'Enregistrez les bouteilles vides collectées',
    );
  }
}

