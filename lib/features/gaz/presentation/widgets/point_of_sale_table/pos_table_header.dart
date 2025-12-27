import 'package:flutter/material.dart';

/// En-tête du tableau des points de vente.
class PosTableHeader extends StatelessWidget {
  const PosTableHeader({super.key});

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
            width: 200,
            child: Text(
              'Nom du point de vente',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Adresse',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          SizedBox(
            width: 260,
            child: Text(
              'Contact',
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
          Expanded(
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

