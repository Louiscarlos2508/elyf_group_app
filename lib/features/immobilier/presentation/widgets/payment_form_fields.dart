import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import 'payment_form_helpers.dart';

/// Widgets de champs pour le formulaire de paiement.
class PaymentFormFields {
  PaymentFormFields._();

  static Widget contractField({
    required Contract? selectedContract,
    required List<Contract> contracts,
    required ValueChanged<Contract?> onChanged,
    required String? Function(Contract?) validator,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<Contract>(
      initialValue: selectedContract,
      decoration: const InputDecoration(
        labelText: 'Contrat *',
        prefixIcon: Icon(Icons.description),
      ),
      items: contracts.map((contract) {
        return DropdownMenuItem(
          value: contract,
          child: Text(contract.displayName),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }

  static Widget dateField({
    required DateTime paymentDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date de paiement *',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(PaymentFormHelpers.formatDate(paymentDate)),
      ),
    );
  }

  static Widget amountField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    String label = 'Montant Total (FCFA) *',
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  static Widget paidAmountField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Montant Reçu (FCFA) *',
        prefixIcon: const Icon(Icons.payments_outlined),
        helperText: helperText,
        helperStyle: const TextStyle(color: Colors.blue),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  static Widget monthYearFields({
    required int? month,
    required int? year,
    required ValueChanged<int?> onMonthChanged,
    required ValueChanged<int?> onYearChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            initialValue: month,
            decoration: const InputDecoration(
              labelText: 'Mois',
              prefixIcon: Icon(Icons.calendar_month),
            ),
            items: List.generate(12, (index) => index + 1).map((month) {
              final monthNames = [
                'Janvier',
                'Février',
                'Mars',
                'Avril',
                'Mai',
                'Juin',
                'Juillet',
                'Août',
                'Septembre',
                'Octobre',
                'Novembre',
                'Décembre',
              ];
              return DropdownMenuItem(
                value: month,
                child: Text(monthNames[month - 1]),
              );
            }).toList(),
            onChanged: onMonthChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int?>(
            initialValue: year,
            decoration: const InputDecoration(
              labelText: 'Année',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: List.generate(10, (index) {
              final year = DateTime.now().year - 5 + index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }).toList(),
            onChanged: onYearChanged,
          ),
        ),
      ],
    );
  }

  static Widget paymentMethodField({
    required PaymentMethod value,
    required ValueChanged<PaymentMethod?> onChanged,
  }) {
    return DropdownButtonFormField<PaymentMethod>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Méthode de paiement *',
        prefixIcon: Icon(Icons.payment),
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(PaymentFormHelpers.getMethodLabel(method)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget paymentTypeField({
    required PaymentType value,
    required ValueChanged<PaymentType?> onChanged,
  }) {
    return DropdownButtonFormField<PaymentType>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Type de paiement *',
        prefixIcon: Icon(Icons.category),
      ),
      items: PaymentType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(_getPaymentTypeLabel(type)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget statusField({
    required PaymentStatus value,
    required ValueChanged<PaymentStatus?> onChanged,
  }) {
    return DropdownButtonFormField<PaymentStatus>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Statut *',
        prefixIcon: Icon(Icons.info_outline),
      ),
      items: PaymentStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(PaymentFormHelpers.getStatusLabel(status)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.rent:
        return 'Loyer';
      case PaymentType.deposit:
        return 'Caution';
    }
  }



  static Widget transactionIdField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'ID Transaction',
        hintText: 'Ex: PP2304...',
        prefixIcon: Icon(Icons.receipt_long),
      ),
      textCapitalization: TextCapitalization.characters,
    );
  }

  static Widget splitAmountFields({
    required TextEditingController cashController,
    required TextEditingController mobileMoneyController,
    required String? Function(String?) cashValidator,
    required String? Function(String?) mobileMoneyValidator,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: cashController,
            decoration: const InputDecoration(
              labelText: 'Espèces (FCFA)',
              prefixIcon: Icon(Icons.money),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: cashValidator,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: mobileMoneyController,
            decoration: const InputDecoration(
              labelText: 'Mobile Money (FCFA)',
              prefixIcon: Icon(Icons.smartphone),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: mobileMoneyValidator,
          ),
        ),
      ],
    );
  }

  static Widget notesField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Notes supplémentaires...',
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
