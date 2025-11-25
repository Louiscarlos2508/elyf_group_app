import 'package:flutter/material.dart';

import '../../domain/entities/production_payment_person.dart';
import 'production_payment_person_row.dart';

/// Section for managing persons to pay in production payment.
class ProductionPaymentPersonsSection extends StatelessWidget {
  const ProductionPaymentPersonsSection({
    super.key,
    required this.persons,
    required this.onAddPerson,
    required this.onRemovePerson,
    required this.onUpdatePerson,
  });

  final List<ProductionPaymentPerson> persons;
  final VoidCallback onAddPerson;
  final void Function(int) onRemovePerson;
  final void Function(int, ProductionPaymentPerson) onUpdatePerson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Personnes à Payer *',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IntrinsicWidth(
              child: OutlinedButton.icon(
                onPressed: onAddPerson,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle personne'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (persons.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Ajoutez des personnes à payer',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...List.generate(persons.length, (index) {
            return ProductionPaymentPersonRow(
              person: persons[index],
              onChanged: (person) => onUpdatePerson(index, person),
              onRemove: () => onRemovePerson(index),
            );
          }),
      ],
    );
  }
}

