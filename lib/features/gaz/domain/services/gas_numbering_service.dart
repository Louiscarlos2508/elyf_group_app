import 'package:intl/intl.dart';

/// Service to generate professional reference numbers for gas transactions.
/// 
/// Format: VGAZ-YYYYMMDD-XXXX
/// e.g. VGAZ-20240311-0001
class GasNumberingService {
  static const String prefixSale = 'VGAZ';
  static const String prefixReplenishment = 'ACHG';
  static const String prefixExpense = 'DEPG';
  static const String prefixTour = 'TOUR';

  /// Generates a professional number based on prefix, date and daily sequence.
  /// 
  /// [prefix] The transaction type prefix.
  /// [date] The transaction date.
  /// [dailySequence] The zero-based sequence number for that day.
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
