import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Helpers pour l'historique des transactions.
///
/// Utilise les formatters partagés pour éviter la duplication.
class TransactionsHistoryHelpers {
  TransactionsHistoryHelpers._();

  /// Formate un montant avec signe.
  static String formatAmount(int amount, bool isCashIn) {
    // Format: +5 500 F ou -5 500 F
    final sign = isCashIn ? '+' : '-';
    return '$sign${CurrencyFormatter.formatShort(amount)}';
  }

  /// Construit la clé du provider basée sur les filtres.
  static String buildProviderKey({
    required String searchQuery,
    String? typeStr,
    String? startDateStr,
    String? endDateStr,
  }) {
    return '$searchQuery|${typeStr ?? ''}|${startDateStr ?? ''}|${endDateStr ?? ''}';
  }
}
