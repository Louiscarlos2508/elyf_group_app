import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/currency_formatter.dart';

/// Widget réutilisable pour répartir un paiement entre Cash et Mobile Money.
///
/// Utilisé quand PaymentMethod.both est sélectionné.
class PaymentSplitter extends StatefulWidget {
  const PaymentSplitter({
    super.key,
    required this.totalAmount,
    required this.onSplitChanged,
    this.initialCashAmount = 0,
    this.initialMobileMoneyAmount = 0,
    this.cashLabel = 'Cash',
    this.mobileMoneyLabel = 'Mobile Money',
  });

  /// Montant total à répartir
  final int totalAmount;

  /// Callback appelé quand la répartition change
  final void Function(int cashAmount, int mobileMoneyAmount) onSplitChanged;

  /// Montant initial en cash
  final int initialCashAmount;

  /// Montant initial en mobile money
  final int initialMobileMoneyAmount;

  /// Label personnalisé pour cash (ex: "Espèces")
  final String cashLabel;

  /// Label personnalisé pour mobile money (ex: "Orange Money")
  final String mobileMoneyLabel;

  @override
  State<PaymentSplitter> createState() => _PaymentSplitterState();
}

class _PaymentSplitterState extends State<PaymentSplitter> {
  late TextEditingController _cashController;
  late TextEditingController _mobileMoneyController;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(
      text: widget.initialCashAmount > 0
          ? widget.initialCashAmount.toString()
          : '',
    );
    _mobileMoneyController = TextEditingController(
      text: widget.initialMobileMoneyAmount > 0
          ? widget.initialMobileMoneyAmount.toString()
          : '',
    );

    // Appeler onSplitChanged après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }

  void _updateSplit() {
    final cash = int.tryParse(_cashController.text) ?? 0;
    final mobileMoney = int.tryParse(_mobileMoneyController.text) ?? 0;
    widget.onSplitChanged(cash, mobileMoney);
  }

  void _onCashChanged(String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  void _onMobileMoneyChanged(String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSplit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cash = int.tryParse(_cashController.text) ?? 0;
    final mobileMoney = int.tryParse(_mobileMoneyController.text) ?? 0;
    final total = cash + mobileMoney;
    final isValid = total == widget.totalAmount;
    final remaining = widget.totalAmount - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? colors.primary : colors.error,
          width: 1,
        ),
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
              labelText: '${widget.cashLabel} (FCFA)',
              prefixIcon: const Icon(Icons.money),
              helperText: cash > 0 ? CurrencyFormatter.formatFCFA(cash) : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onCashChanged,
            validator: (value) {
              final amount = int.tryParse(value ?? '') ?? 0;
              if (amount < 0) return 'Montant invalide';
              if (amount + mobileMoney > widget.totalAmount) {
                return 'Dépasse le total';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mobileMoneyController,
            decoration: InputDecoration(
              labelText: '${widget.mobileMoneyLabel} (FCFA)',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              helperText: mobileMoney > 0
                  ? CurrencyFormatter.formatFCFA(mobileMoney)
                  : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onMobileMoneyChanged,
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
                      CurrencyFormatter.formatFCFA(total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isValid ? colors.primary : colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total attendu',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.formatFCFA(widget.totalAmount),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (!isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    remaining > 0
                        ? 'Reste à saisir: ${CurrencyFormatter.formatFCFA(remaining)}'
                        : 'Dépassement: ${CurrencyFormatter.formatFCFA(-remaining)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
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

