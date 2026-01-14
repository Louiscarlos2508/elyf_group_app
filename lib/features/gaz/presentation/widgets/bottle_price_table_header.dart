import 'package:flutter/material.dart';

/// En-tête du tableau des tarifs des bouteilles.
class BottlePriceTableHeader extends StatelessWidget {
  const BottlePriceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7.99,
        vertical: 8.97,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF000000),
            width: 1.305,
            style: BorderStyle.solid,
          ),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              'Type de bouteille',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'Prix détail',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'Prix gros',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Statut',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Actions',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
