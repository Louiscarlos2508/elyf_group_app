import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';

/// En-tête de l'écran des dépenses avec bouton d'ajout.
class ExpensesHeader extends StatelessWidget {
  const ExpensesHeader({
    super.key,
    required this.isMobile,
    required this.onNewExpense,
  });

  final bool isMobile;
  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    return GazHeader(
      title: 'DÉPENSES',
      subtitle: 'Suivi des dépenses',
      asSliver: false,
      additionalActions: [
        ElyfButton(
          onPressed: onNewExpense,
          icon: Icons.add,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Nouvelle dépense'),
        ),
      ],
    );
  }
}
