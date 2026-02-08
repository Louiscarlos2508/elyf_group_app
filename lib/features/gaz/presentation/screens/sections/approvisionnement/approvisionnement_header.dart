import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';

/// En-tête de l'écran d'approvisionnement avec bouton d'ajout.
class ApprovisionnementHeader extends StatelessWidget {
  const ApprovisionnementHeader({
    super.key,
    required this.isMobile,
    required this.onNewTour,
  });

  final bool isMobile;
  final VoidCallback onNewTour;

  @override
  Widget build(BuildContext context) {
    return GazHeader(
      title: 'APPROVISIONNEMENT',
      subtitle: 'Cycles de collecte',
      asSliver: false,
      additionalActions: [
        ElyfButton(
          onPressed: onNewTour,
          icon: Icons.add,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Nouveau tour'),
        ),
      ],
    );
  }
}
