/// Payment method enum.
enum PaymentMethod { cash, orangeMoney, both }

/// Service for payment splitting logic.
///
/// Extracts payment splitting logic from UI widgets to make it testable and reusable.
class PaymentSplitterService {
  /// Result of a payment split operation.
  static PaymentSplitResult splitPayment({
    required PaymentMethod method,
    required int totalAmount,
    int? cashAmount,
    int? orangeMoneyAmount,
  }) {
    switch (method) {
      case PaymentMethod.cash:
        return PaymentSplitResult(
          cashAmount: totalAmount,
          orangeMoneyAmount: 0,
        );
      case PaymentMethod.orangeMoney:
        return PaymentSplitResult(
          cashAmount: 0,
          orangeMoneyAmount: totalAmount,
        );
      case PaymentMethod.both:
        // If both, use provided amounts or default to 0
        return PaymentSplitResult(
          cashAmount: cashAmount ?? 0,
          orangeMoneyAmount: orangeMoneyAmount ?? 0,
        );
    }
  }

  /// Calculates payment split when amount paid changes.
  ///
  /// Returns the split result based on the payment method.
  static PaymentSplitResult calculateSplitOnAmountChange({
    required PaymentMethod method,
    required int amountPaid,
  }) {
    return splitPayment(method: method, totalAmount: amountPaid);
  }

  /// Validates that the split amounts are valid.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateSplit({
    required int cashAmount,
    required int orangeMoneyAmount,
    required int totalAmount,
  }) {
    if (cashAmount < 0) {
      return 'Le montant cash ne peut pas être négatif';
    }
    if (orangeMoneyAmount < 0) {
      return 'Le montant Orange Money ne peut pas être négatif';
    }
    final total = cashAmount + orangeMoneyAmount;
    if (total > totalAmount) {
      return 'La somme dépasse le montant total';
    }
    return null;
  }

  /// Validates a single amount in a split.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateSplitAmount({
    required int amount,
    required int otherAmount,
    required int totalAmount,
  }) {
    if (amount < 0) {
      return 'Montant invalide';
    }
    if (amount + otherAmount > totalAmount) {
      return 'Dépasse le total';
    }
    return null;
  }

  /// Calculates the remaining amount to be split.
  static int calculateRemainingAmount({
    required int cashAmount,
    required int orangeMoneyAmount,
    required int totalAmount,
  }) {
    final total = cashAmount + orangeMoneyAmount;
    final remaining = totalAmount - total;
    return remaining > 0 ? remaining : 0;
  }

  /// Checks if the split is complete (sum equals total).
  static bool isSplitComplete({
    required int cashAmount,
    required int orangeMoneyAmount,
    required int totalAmount,
  }) {
    return (cashAmount + orangeMoneyAmount) == totalAmount;
  }

  /// Gets initial split amounts based on payment method and total amount.
  static PaymentSplitResult getInitialSplit({
    required PaymentMethod method,
    required int totalAmount,
  }) {
    return splitPayment(method: method, totalAmount: totalAmount);
  }
}

/// Result of a payment split operation.
class PaymentSplitResult {
  const PaymentSplitResult({
    required this.cashAmount,
    required this.orangeMoneyAmount,
  });

  final int cashAmount;
  final int orangeMoneyAmount;

  int get total => cashAmount + orangeMoneyAmount;
}

// PaymentMethod enum is defined in sale_form.dart
// Import it from there or create a shared enum file
