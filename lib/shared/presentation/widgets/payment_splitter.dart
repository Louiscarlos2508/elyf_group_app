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
    this.cashLabel = 'Espèces',
    this.mobileMoneyLabel = 'Mobile Money',
  });

  final int totalAmount;
  final void Function(int cashAmount, int mobileMoneyAmount) onSplitChanged;
  final int initialCashAmount;
  final int initialMobileMoneyAmount;
  final String cashLabel;
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
      text: widget.initialCashAmount > 0 ? widget.initialCashAmount.toString() : '',
    );
    _mobileMoneyController = TextEditingController(
      text: widget.initialMobileMoneyAmount > 0 ? widget.initialMobileMoneyAmount.toString() : '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateSplit();
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

  void _onFieldChanged(String _) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateSplit();
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildField(_cashController, widget.cashLabel, Icons.money, cash),
          const SizedBox(height: 12),
          _buildField(_mobileMoneyController, widget.mobileMoneyLabel, Icons.account_balance_wallet, mobileMoney),
          const SizedBox(height: 16),
          _buildSummary(theme, colors, total, isValid, remaining),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, int value) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label (FCFA)',
        prefixIcon: Icon(icon),
        helperText: value > 0 ? CurrencyFormatter.formatFCFA(value) : null,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: _onFieldChanged,
    );
  }

  Widget _buildSummary(ThemeData theme, ColorScheme colors, int total, bool isValid, int remaining) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total saisi', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                CurrencyFormatter.formatFCFA(total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isValid ? colors.primary : colors.error,
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 4),
            Text(
              remaining > 0
                  ? 'Reste: ${CurrencyFormatter.formatFCFA(remaining)}'
                  : 'Dépassement: ${CurrencyFormatter.formatFCFA(-remaining)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
