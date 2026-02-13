import 'package:intl/intl.dart';

/// Service to generate professional reference numbers for transactions.
/// 
/// Format: PREFIX-YYYYMMDD-XXXX
/// e.g. FAC-20240212-001
class BoutiqueNumberingService {
  static const String prefixSale = 'FAC';
  static const String prefixPurchase = 'ACH';
  static const String prefixExpense = 'DEP';
  static const String prefixSession = 'SES';
  static const String prefixTreasury = 'TRE';
  static const String prefixSettlement = 'REG';

  /// Generates a professional number based on prefix, date and daily sequence.
  /// 
  /// [prefix] The transaction type prefix.
  /// [date] The transaction date.
  /// [dailySequence] The zero-based sequence number for that day (e.g. 0 for the first sale).
  static String generate({
    required String prefix,
    required DateTime date,
    required int dailySequence,
  }) {
    final datePart = DateFormat('yyyyMMdd').format(date);
    final sequencePart = (dailySequence + 1).toString().padLeft(4, '0');
    return '$prefix-$datePart-$sequencePart';
  }
}
