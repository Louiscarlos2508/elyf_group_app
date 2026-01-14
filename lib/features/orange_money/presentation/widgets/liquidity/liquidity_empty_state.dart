import 'package:flutter/material.dart';

/// Widget affichant un état vide pour la liste des pointages.
class LiquidityEmptyState extends StatelessWidget {
  const LiquidityEmptyState({super.key, this.isRecent = false});

  final bool isRecent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Color(0xFF6A7282),
            ),
            const SizedBox(height: 16),
            Text(
              isRecent ? 'Aucun pointage enregistré' : 'Aucun pointage trouvé',
              style: const TextStyle(fontSize: 16, color: Color(0xFF6A7282)),
            ),
            const SizedBox(height: 8),
            Text(
              isRecent
                  ? 'Commencez par faire votre pointage du matin'
                  : 'Essayez de modifier vos critères de recherche',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6A7282)),
            ),
          ],
        ),
      ),
    );
  }
}
