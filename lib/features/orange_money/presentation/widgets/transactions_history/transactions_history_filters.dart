import 'package:flutter/material.dart';
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFD6A7), width: 1.219),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ de recherche
            _buildSearchField(),
            const SizedBox(height: 16),
            // Filtres Type et Date
            Row(
              children: [
                Expanded(child: _buildTypeFilter()),
                const SizedBox(width: 12),
                Expanded(child: _buildDateFilter()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent, width: 1.219),
          ),
          child: TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Nom, téléphone ou n° pièce...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF717182),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 10,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.search, size: 16, color: Color(0xFF717182)),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.filter_list, size: 16, color: Color(0xFF0A0A0A)),
            SizedBox(width: 8),
            Text(
              'Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent, width: 1.219),
          ),
          child: DropdownButtonFormField<TransactionType?>(
            initialValue: selectedTypeFilter,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text(
              'Tous les types',
              style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
            ),
            items: [
              const DropdownMenuItem<TransactionType?>(
                value: null,
                child: Text('Tous les types'),
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
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.calendar_today, size: 16, color: Color(0xFF0A0A0A)),
            SizedBox(width: 8),
            Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onDateSelected,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 1.219),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF717182),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF717182),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
