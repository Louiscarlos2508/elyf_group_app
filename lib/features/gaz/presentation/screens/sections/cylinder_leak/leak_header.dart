import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';

/// En-tête de l'écran de gestion des fuites.
class LeakHeader extends StatelessWidget {
  const LeakHeader({
    super.key,
    required this.isMobile,
    required this.onReportLeak,
  });

  final bool isMobile;
  final VoidCallback onReportLeak;

  @override
  Widget build(BuildContext context) {
    return GazHeader(
      title: 'FUITES',
      subtitle: 'Gestion des Fuites',
      asSliver: false,
      additionalActions: [
        ElyfButton(
          onPressed: onReportLeak,
          icon: Icons.add,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Signaler une fuite'),
        ),
      ],
    );
  }
}
