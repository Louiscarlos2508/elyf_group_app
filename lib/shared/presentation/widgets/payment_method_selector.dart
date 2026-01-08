import 'package:flutter/material.dart';

import '../../../shared/domain/entities/payment_method.dart';

/// Widget réutilisable pour sélectionner une méthode de paiement.
///
/// Supporte différents styles (SegmentedButton ou Dropdown) et configurations
/// selon les besoins du module.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.config,
    this.style = PaymentMethodSelectorStyle.segmented,
    this.label,
  });

  /// Méthode de paiement actuellement sélectionnée
  final PaymentMethod value;

  /// Callback appelé quand la méthode change
  final ValueChanged<PaymentMethod> onChanged;

  /// Configuration des méthodes disponibles
  final PaymentMethodConfig config;

  /// Style du sélecteur (SegmentedButton ou Dropdown)
  final PaymentMethodSelectorStyle style;

  /// Label optionnel au-dessus du sélecteur
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget selector;
    switch (style) {
      case PaymentMethodSelectorStyle.segmented:
        selector = _buildSegmentedButton(context);
        break;
      case PaymentMethodSelectorStyle.dropdown:
        selector = _buildDropdown(context);
        break;
    }

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          selector,
        ],
      );
    }

    return selector;
  }

  Widget _buildSegmentedButton(BuildContext context) {
    final segments = config.availableMethods.map((method) {
      return ButtonSegment<PaymentMethod>(
        value: method,
        label: Text(_getMethodLabel(method)),
        icon: Icon(_getMethodIcon(method)),
      );
    }).toList();

    return SegmentedButton<PaymentMethod>(
      segments: segments,
      selected: {value},
      onSelectionChanged: (Set<PaymentMethod> selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Méthode de paiement *',
        prefixIcon: Icon(Icons.payment),
      ),
      items: config.availableMethods.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Row(
            children: [
              Icon(_getMethodIcon(method)),
              const SizedBox(width: 8),
              Text(_getMethodLabel(method)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  String _getMethodLabel(PaymentMethod method) {
    if (method == PaymentMethod.mobileMoney && config.mobileMoneyLabel != null) {
      return config.mobileMoneyLabel!;
    }
    return method.label;
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.mobileMoney:
        return Icons.account_balance_wallet;
      case PaymentMethod.both:
        return Icons.payment;
    }
  }
}

/// Style du sélecteur de méthode de paiement
enum PaymentMethodSelectorStyle {
  /// Style avec SegmentedButton (boutons groupés)
  segmented,

  /// Style avec DropdownButton (liste déroulante)
  dropdown,
}

