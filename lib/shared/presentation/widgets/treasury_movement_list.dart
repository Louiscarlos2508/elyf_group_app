import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/entities/treasury_movement.dart';

/// Widget pour afficher la liste des mouvements de trésorerie.
class TreasuryMovementList extends StatelessWidget {
  const TreasuryMovementList({
    super.key,
    required this.movements,
  });

  final List<TreasuryMovement> movements;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  IconData _getTypeIcon(TreasuryMovementType type) {
    switch (type) {
      case TreasuryMovementType.entree:
        return Icons.arrow_downward;
      case TreasuryMovementType.sortie:
        return Icons.arrow_upward;
      case TreasuryMovementType.transfert:
        return Icons.swap_horiz;
    }
  }

  Color _getTypeColor(TreasuryMovementType type) {
    switch (type) {
      case TreasuryMovementType.entree:
        return Colors.green;
      case TreasuryMovementType.sortie:
        return Colors.red;
      case TreasuryMovementType.transfert:
        return Colors.blue;
    }
  }

  String _getTypeLabel(TreasuryMovementType type) {
    switch (type) {
      case TreasuryMovementType.entree:
        return 'Entrée';
      case TreasuryMovementType.sortie:
        return 'Sortie';
      case TreasuryMovementType.transfert:
        return 'Transfert';
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucun mouvement enregistré',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        ),
      );
    }

    final sortedMovements = List<TreasuryMovement>.from(movements)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Column(
        children: sortedMovements.map((movement) {
          final typeColor = _getTypeColor(movement.type);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: typeColor.withOpacity(0.1),
              child: Icon(
                _getTypeIcon(movement.type),
                color: typeColor,
                size: 20,
              ),
            ),
            title: Text(movement.description),
            subtitle: Text(
              '${_getTypeLabel(movement.type)} • ${_getMethodLabel(movement.method)} • ${_formatDate(movement.date)}',
            ),
            trailing: Text(
              movement.isSortie
                  ? '-${_formatCurrency(movement.amount)}'
                  : '+${_formatCurrency(movement.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

