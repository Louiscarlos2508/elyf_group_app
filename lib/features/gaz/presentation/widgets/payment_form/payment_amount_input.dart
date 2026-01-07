import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../shared.dart';
import '../../../domain/entities/collection.dart';

/// Section d'affichage des montants et saisie du montant reçu.
class PaymentAmountInput extends StatelessWidget {
  const PaymentAmountInput({
    super.key,
    required this.collection,
    required this.newAmountDue,
    required this.amountController,
    required this.amountToPayNow,
  });

  final Collection collection;
  final double newAmountDue;
  final TextEditingController amountController;
  final double amountToPayNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###', 'fr_FR');
    final originalAmountDue = collection.amountDue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section des montants initiaux
        Container(
          padding: const EdgeInsets.fromLTRB(17.292, 17.292, 17.292, 1.305),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.305,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Montant dû
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Montant dû:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF4A5565),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatDouble(originalAmountDue),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7.993),
              // Déjà payé
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Déjà payé:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF00A63E),
                    ),
                  ),
                  Text(
                    '-${CurrencyFormatter.formatDouble(collection.amountPaid)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF00A63E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7.993),
              // Reste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reste:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatDouble(collection.remainingAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFFE7000B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11.99),
        // Nouveau montant dû après fuites
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouveau montant dû:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                Text(
                  '${numberFormat.format(newAmountDue.toInt())} F',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF155DFC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7.993),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Déjà payé:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                Text(
                  '-${numberFormat.format(collection.amountPaid.toInt())} F',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF00A63E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7.993),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'À payer maintenant:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                Text(
                  '${numberFormat.format(amountToPayNow.toInt())} F',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFFE7000B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 11.99),
        // Divider
        Container(
          height: 0.999,
          color: Colors.black.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 11.99),
        // Champ montant reçu
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant reçu du client',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 7.993),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      hintText: '0',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF717182),
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF717182),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un montant';
                      }
                      final amount =
                          double.tryParse(value.replaceAll(' ', ''));
                      if (amount == null || amount <= 0) {
                        return 'Le montant doit être supérieur à 0';
                      }
                      if (amount > amountToPayNow) {
                        return 'Le montant ne peut pas dépasser ${numberFormat.format(amountToPayNow.toInt())} FCFA';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'FCFA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF6A7282),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

