import 'package:flutter/material.dart';

/// Widget pour l'état vide de l'historique des transactions.
class TransactionsHistoryEmptyState extends StatelessWidget {
  const TransactionsHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E5E5),
          width: 1.219,
        ),
      ),
      child: Container(
        height: 234,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: const Color(0xFF4A5565).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune transaction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF4A5565),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vos transactions apparaîtront ici',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6A7282),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

