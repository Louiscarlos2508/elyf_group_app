import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Helpers pour le formatage des données des agents.
///
/// Utilise le CurrencyFormatter partagé pour la cohérence.
class AgentsFormatHelpers {
  /// Formate un montant en devise avec espaces (format court "F").
  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatShort(amount);
  }

  /// Formate un montant en devise compact.
  static String formatCurrencyCompact(int amount) {
    return '$amount F';
  }
}
