import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Widget simple pour répartir le montant entre Cash et Orange Money.
class SimplePaymentSplitter extends StatefulWidget {
  const SimplePaymentSplitter({
    super.key,
    required this.totalAmount,
    required this.onSplitChanged,
    this.initialCashAmount = 0,
    this.initialOrangeMoneyAmount = 0,
  });

  final int totalAmount;
  final void Function(int cashAmount, int orangeMoneyAmount) onSplitChanged;
  final int initialCashAmount;
  final int initialOrangeMoneyAmount;

  @override
  State<SimplePaymentSplitter> createState() => _SimplePaymentSplitterState();
}

class _SimplePaymentSplitterState extends State<SimplePaymentSplitter> {
  late TextEditingController _cashController;
  late TextEditingController _orangeMoneyController;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs fournies ou laisser vide pour que l'utilisateur saisisse
    _cashController = TextEditingController(
      text: widget.initialCashAmount > 0
          ? widget.initialCashAmount.toString()
          : '',
    );
    _orangeMoneyController = TextEditingController(
      text: widget.initialOrangeMoneyAmount > 0
          ? widget.initialOrangeMoneyAmount.toString()
          : '',
    );
    // Ne pas appeler _updateSplit() dans initState pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _orangeMoneyController.dispose();
    super.dispose();
  }

  void _updateSplit() {
    final cash = int.tryParse(_cashController.text) ?? 0;
    final orangeMoney = int.tryParse(_orangeMoneyController.text) ?? 0;
    widget.onSplitChanged(cash, orangeMoney);
  }

  void _onCashChanged(String value) {
    // L'utilisateur saisit librement, pas de modification automatique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  void _onOrangeMoneyChanged(String value) {
    // L'utilisateur saisit librement, pas de modification automatique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' CFA';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cash = int.tryParse(_cashController.text) ?? 0;
    final orangeMoney = int.tryParse(_orangeMoneyController.text) ?? 0;
    final total = cash + orangeMoney;
    final isValid = total == widget.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition du paiement',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cashController,
            decoration: InputDecoration(
              labelText: 'Montant Cash (CFA)',
              prefixIcon: const Icon(Icons.money),
            ),
            keyboardType: TextInputType.number,
            onChanged: _onCashChanged,
            validator: (value) {
              final amount = int.tryParse(value ?? '') ?? 0;
              if (amount < 0) return 'Montant invalide';
              if (amount + orangeMoney > widget.totalAmount) {
                return 'Dépasse le total';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orangeMoneyController,
            decoration: InputDecoration(
              labelText: 'Montant Orange Money (CFA)',
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
            keyboardType: TextInputType.number,
            onChanged: _onOrangeMoneyChanged,
            validator: (value) {
              final amount = int.tryParse(value ?? '') ?? 0;
              if (amount < 0) return 'Montant invalide';
              if (amount + cash > widget.totalAmount) {
                return 'Dépasse le total';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid
                  ? colors.primaryContainer.withValues(alpha: 0.3)
                  : colors.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total saisi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isValid ? colors.primary : colors.error,
                      ),
                    ),
                  ],
                ),
                if (!isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reste à saisir: ${_formatCurrency(widget.totalAmount - total)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

