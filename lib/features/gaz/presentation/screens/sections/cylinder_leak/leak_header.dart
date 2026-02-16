import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';

/// En-tête de l'écran de gestion des fuites.
class LeakHeader extends StatelessWidget {
  const LeakHeader({
    super.key,
    required this.isMobile,
    required this.onReportLeak,
    required this.onGenerateClaim,
  });

  final bool isMobile;
  final VoidCallback onReportLeak;
  final VoidCallback onGenerateClaim;

  @override
  Widget build(BuildContext context) {
    return GazHeader(
      title: 'FUITES',
      subtitle: 'Gestion des Fuites',
      asSliver: false,
      additionalActions: [
        ElyfButton(
          onPressed: onGenerateClaim,
          icon: Icons.assignment_outlined,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Réclamation Fournisseur'),
        ),
        const SizedBox(width: 8),
        ElyfButton(
          onPressed: onReportLeak,
          icon: Icons.add,
          variant: ElyfButtonVariant.filled,
          child: const Text('Signaler une fuite'),
        ),
      ],
    );
  }
}
