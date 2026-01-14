import '../entities/transaction.dart';

/// Service pour la logique métier des transactions Orange Money.
class TransactionService {
  TransactionService._();

  /// Valide un numéro de téléphone.
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Veuillez entrer un numéro de téléphone';
    }
    final trimmed = phoneNumber.trim();
    if (trimmed.length < 8) {
      return 'Numéro de téléphone invalide';
    }
    return null;
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
  static Transaction createTransaction({
    required TransactionType type,
    required int amount,
    required String phoneNumber,
    String? customerName,
    String? createdBy,
  }) {
    return Transaction(
      id: _generateTransactionId(),
      type: type,
      amount: amount,
      phoneNumber: phoneNumber.trim(),
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

  /// Normalise un numéro de téléphone pour la comparaison.
  /// Retire les espaces, tirets et ajoute le préfixe +226 si nécessaire.
  static String normalizePhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.startsWith('+226')) {
      return cleaned;
    }
    if (cleaned.startsWith('226')) {
      return '+$cleaned';
    }
    return '+226$cleaned';
  }

  /// Compare deux numéros de téléphone en les normalisant d'abord.
  static bool comparePhoneNumbers(String phone1, String phone2) {
    final normalized1 = normalizePhoneNumber(phone1);
    final normalized2 = normalizePhoneNumber(phone2);
    return normalized1 == normalized2;
  }
}
