import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/transaction.dart';

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
    return '$searchQuery|$typeStr|$startDateStr|$endDateStr';
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = _buildProviderKey();
    final transactionsAsync = ref.watch(
      filteredTransactionsProvider(providerKey),
    );

    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchAndFiltersCard(),
            const SizedBox(height: 24),
            transactionsAsync.when(
              data: (transactions) => transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsList(transactions),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Consultez vos dernières transactions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF4A5565),
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFFFD6A7),
          width: 1.219,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ de recherche
            Column(
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
                    border: Border.all(
                      color: Colors.transparent,
                      width: 1.219,
                    ),
                  ),
                  child: TextFormField(
                    controller: _searchController,
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
                        child: Icon(
                          Icons.search,
                          size: 16,
                          color: Color(0xFF717182),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filtres Type et Date
            Row(
              children: [
                Expanded(
                  child: _buildTypeFilter(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateFilter(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.filter_list,
              size: 16,
              color: Color(0xFF0A0A0A),
            ),
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
            border: Border.all(
              color: Colors.transparent,
              width: 1.219,
            ),
          ),
          child: DropdownButtonFormField<TransactionType?>(
            value: _selectedTypeFilter,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            hint: const Text(
              'Tous les types',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0A0A0A),
              ),
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
            onChanged: (value) {
              setState(() {
                _selectedTypeFilter = value;
              });
            },
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
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Color(0xFF0A0A0A),
            ),
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
          onTap: () => _selectDate(context),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.transparent,
                width: 1.219,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDate != null
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

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E5E5),
          width: 1.219,
        ),
      ),
      child: Container(
        height: 234,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: const Color(0xFF4A5565).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune transaction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF4A5565),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vos transactions apparaîtront ici',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6A7282),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount, bool isCashIn) {
    // Format: +5,500 F ou -5,500 F
    final sign = isCashIn ? '+' : '-';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$sign$formatted F';
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E5E5),
          width: 1.219,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E5E5),
                  width: 1.219,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Date & Heure', width: 124.683),
                _buildTableHeaderCell('Type', width: 95.065),
                _buildTableHeaderCell('Client', width: 259.976),
                _buildTableHeaderCell('Téléphone', width: 100.541),
                _buildTableHeaderCell("Pièce d'identité", width: 175.474),
                Expanded(
                  child: _buildTableHeaderCell('Montant', isRightAligned: true),
                ),
              ],
            ),
          ),
          // Table Rows
          ...transactions.map((transaction) => _buildTransactionRow(transaction)),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {double? width, bool isRightAligned = false}) {
    Widget cell = Container(
      width: width,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0A0A0A),
        ),
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
    
    if (width == null) {
      return cell;
    }
    return SizedBox(width: width, child: cell);
  }

  Widget _buildTransactionRow(Transaction transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1.219,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date & Heure
          SizedBox(
            width: 124.683,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF4A5565),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(transaction.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF101828),
                        ),
                      ),
                      Text(
                        timeFormat.format(transaction.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Type
          SizedBox(
            width: 95.065,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.isCashIn
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 1.219,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      transaction.isCashIn ? Icons.check : Icons.arrow_upward,
                      size: 12,
                      color: transaction.isCashIn
                          ? const Color(0xFF016630)
                          : const Color(0xFF991B1B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transaction.isCashIn ? 'Dépôt' : 'Retrait',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: transaction.isCashIn
                              ? const Color(0xFF016630)
                              : const Color(0xFF991B1B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Client
          SizedBox(
            width: 259.976,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                transaction.customerName ?? transaction.phoneNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF101828),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Téléphone
          SizedBox(
            width: 100.541,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                transaction.phoneNumber.replaceAll('+226', ''),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF4A5565),
                ),
              ),
            ),
          ),
          // Pièce d'identité (non disponible dans l'entité pour l'instant)
          SizedBox(
            width: 175.474,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.credit_card,
                    size: 16,
                    color: Color(0xFF4A5565),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CNI',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF101828),
                        ),
                      ),
                      Text(
                        '-', // Pas de données pour l'instant
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Montant
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _formatAmount(transaction.amount, transaction.isCashIn),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: transaction.isCashIn
                      ? const Color(0xFF008236)
                      : const Color(0xFFDC2626),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

