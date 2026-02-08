import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/employee.dart';

/// Header section showing employee info and monthly salary.
class MonthlySalaryPaymentHeader extends StatelessWidget {
  const MonthlySalaryPaymentHeader({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Column(
      children: [
        ElyfCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          backgroundColor: colors.primary.withValues(alpha: 0.05),
          borderColor: colors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.person_rounded, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    if (employee.position != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        employee.position!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElyfCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
          borderColor: colors.outline.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salaire Mensuel',
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(employee.monthlySalary),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments_rounded, color: colors.primary, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
