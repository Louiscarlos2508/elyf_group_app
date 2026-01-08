import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/transaction.dart';
import '../../widgets/transactions_history/transactions_history_header.dart';
import '../../widgets/transactions_history/transactions_history_filters.dart';
import '../../widgets/transactions_history/transactions_history_empty_state.dart';
import '../../widgets/transactions_history/transactions_history_table.dart';
import '../../widgets/transactions_history/transactions_history_helpers.dart';

/// Écran d'historique des transactions avec recherche et filtres.
class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState
    extends ConsumerState<TransactionsHistoryScreen> {
  final _searchController = TextEditingController();
  TransactionType? _selectedTypeFilter;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _buildProviderKey() {
    final searchQuery = _searchController.text.trim();
    final typeStr = _selectedTypeFilter?.name ?? '';
    final startDateStr = _selectedDate != null
        ? _selectedDate!.millisecondsSinceEpoch.toString()
        : '';
    final endDateStr = _selectedDate != null
        ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                23,
                59,
                59)
            .millisecondsSinceEpoch
            .toString()
        : '';
    return TransactionsHistoryHelpers.buildProviderKey(
      searchQuery: searchQuery,
      typeStr: typeStr,
      startDateStr: startDateStr,
      endDateStr: endDateStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = _buildProviderKey();
    final transactionsAsync = ref.watch(
      filteredTransactionsProvider((providerKey)),
    );

    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TransactionsHistoryHeader(),
            const SizedBox(height: 24),
            TransactionsHistoryFilters(
              searchController: _searchController,
              selectedTypeFilter: _selectedTypeFilter,
              selectedDate: _selectedDate,
              onTypeChanged: (value) {
                setState(() {
                  _selectedTypeFilter = value;
                });
              },
              onDateSelected: () => _selectDate(context),
            ),
            const SizedBox(height: 24),
            transactionsAsync.when(
              data: (transactions) => transactions.isEmpty
                  ? const TransactionsHistoryEmptyState()
                  : TransactionsHistoryTable(transactions: transactions),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erreur: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
