import 'package:elyf_groupe_app/shared.dart';

import '../entities/transaction.dart';

/// Service pour la logique métier des transactions Orange Money.
class TransactionService {
  TransactionService._();

  /// Valide un numéro de téléphone (Burkina +226).
  static String? validatePhoneNumber(String? phoneNumber) {
    return PhoneUtils.validateBurkina(
      phoneNumber,
      customMessage: 'Veuillez entrer un numéro Burkina (+226)',
    );
  }

  /// Valide un montant.
  static String? validateAmount(String? amountStr) {
    if (amountStr == null || amountStr.trim().isEmpty) {
      return 'Veuillez entrer un montant';
    }
    final amount = int.tryParse(amountStr.trim());
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    return null;
  }

  /// Crée une nouvelle transaction avec les données fournies.
  /// Le numéro est normalisé au format +226.
  static Transaction createTransaction({
    required String enterpriseId,
    required TransactionType type,
    required int amount,
    required String phoneNumber,
    String? customerName,
    String? createdBy,
  }) {
    final normalized =
        PhoneUtils.normalizeBurkina(phoneNumber.trim()) ?? phoneNumber.trim();
    return Transaction(
      id: _generateTransactionId(),
      enterpriseId: enterpriseId,
      type: type,
      amount: amount,
      phoneNumber: normalized,
      date: DateTime.now(),
      status: TransactionStatus.pending,
      customerName: customerName?.trim(),
      createdBy: createdBy,
    );
  }

  /// Génère un ID unique pour une transaction.
  static String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Normalise un numéro pour la comparaison (Burkina +226).
  static String normalizePhoneNumber(String phoneNumber) {
    return PhoneUtils.normalizeBurkina(phoneNumber.trim()) ??
        phoneNumber.trim();
  }

  /// Compare deux numéros en les normalisant d'abord.
  static bool comparePhoneNumbers(String phone1, String phone2) {
    final n1 = normalizePhoneNumber(phone1);
    final n2 = normalizePhoneNumber(phone2);
    return n1 == n2;
  }
}
