import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/transaction.dart';

/// Widget pour les filtres de recherche et de date.
class TransactionsHistoryFilters extends StatelessWidget {
  const TransactionsHistoryFilters({
    super.key,
    required this.searchController,
    required this.selectedTypeFilter,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateSelected,
  });

  final TextEditingController searchController;
  final TransactionType? selectedTypeFilter;
  final DateTime? selectedDate;
  final ValueChanged<TransactionType?> onTypeChanged;
  final VoidCallback onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ de recherche
          _buildSearchField(context),
          SizedBox(height: AppSpacing.md),
          // Filtres Type et Date
          Row(
            children: [
              Expanded(child: _buildTypeFilter(context)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _buildDateFilter(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rechercher',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: searchController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Nom, téléphone ou n° pièce...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.search, 
                size: 20, 
                color: theme.colorScheme.primary,
              ),
            ),
            onChanged: (value) {
              // Trigger search update via parent setState if needed, 
              // but here it's likely handled by the controller and providerKey rebuild.
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TransactionType?>(
              value: selectedTypeFilter,
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              hint: Text(
                'Tous',
                style: theme.textTheme.bodyMedium,
              ),
              selectedItemBuilder: (context) {
                return [
                  null,
                  TransactionType.cashIn,
                  TransactionType.cashOut,
                ].map((type) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      type == null ? 'Tous types' : type.label,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }).toList();
              },
              items: [
                const DropdownMenuItem<TransactionType?>(
                  value: null,
                  child: Text('Tous types'),
                ),
                DropdownMenuItem<TransactionType>(
                  value: TransactionType.cashIn,
                  child: Text(TransactionType.cashIn.label),
                ),
                DropdownMenuItem<TransactionType>(
                  value: TransactionType.cashOut,
                  child: Text(TransactionType.cashOut.label),
                ),
              ],
              onChanged: onTypeChanged,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onDateSelected,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Filtrer par date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
