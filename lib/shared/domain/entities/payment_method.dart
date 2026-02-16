/// Enum unifié pour les méthodes de paiement dans toute l'application.
///
/// Supporte les méthodes de paiement disponibles :
/// - cash : Paiement en espèces
/// - mobileMoney : Paiement mobile money (Orange Money, MTN, Moov, etc.)
/// - both : Les deux (cash + mobile money) - pour répartition
enum PaymentMethod {
  /// Paiement en espèces
  cash,

  /// Paiement mobile money (Orange Money, MTN, Moov, etc.)
  mobileMoney,

  /// Les deux méthodes (cash + mobile money) - pour répartition
  both,

  /// Paiement par carte bancaire
  card,

  /// Vente à crédit
  credit,
}

/// Extension pour obtenir les labels des méthodes de paiement
extension PaymentMethodExtension on PaymentMethod {
  /// Retourne le label affiché pour la méthode de paiement
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.both:
        return 'Les deux';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.credit:
        return 'Crédit';
    }
  }

  /// Retourne l'icône associée à la méthode de paiement
  String get iconName {
    switch (this) {
      case PaymentMethod.cash:
        return 'money';
      case PaymentMethod.mobileMoney:
        return 'account_balance_wallet';
      case PaymentMethod.both:
        return 'payment';
      case PaymentMethod.card:
        return 'credit_card';
      case PaymentMethod.credit:
        return 'timer_outlined';
    }
  }

  /// Retourne si cette méthode nécessite une répartition (split)
  bool get requiresSplit => this == PaymentMethod.both;
}

/// Configuration pour les méthodes de paiement disponibles par module
class PaymentMethodConfig {
  /// Liste des méthodes de paiement disponibles
  final List<PaymentMethod> availableMethods;

  /// Si true, permet la sélection de "Les deux" (both)
  final bool allowBoth;

  /// Label personnalisé pour mobile money (ex: "Orange Money" au lieu de "Mobile Money")
  final String? mobileMoneyLabel;

  const PaymentMethodConfig({
    required this.availableMethods,
    this.allowBoth = false,
    this.mobileMoneyLabel,
  });

  /// Configuration pour Eau Minérale (cash, orange money, both)
  factory PaymentMethodConfig.eauMinerale() {
    return const PaymentMethodConfig(
      availableMethods: [
        PaymentMethod.cash,
        PaymentMethod.mobileMoney,
        PaymentMethod.both,
      ],
      allowBoth: true,
      mobileMoneyLabel: 'Orange Money',
    );
  }

  /// Configuration pour Boutique (cash, mobile money)
  factory PaymentMethodConfig.boutique() {
    return const PaymentMethodConfig(
      availableMethods: [PaymentMethod.cash, PaymentMethod.mobileMoney],
      allowBoth: false,
    );
  }

  /// Configuration pour Immobilier (cash, mobile money, both)
  factory PaymentMethodConfig.immobilier() {
    return const PaymentMethodConfig(
      availableMethods: [
        PaymentMethod.cash,
        PaymentMethod.mobileMoney,
        PaymentMethod.both,
      ],
      allowBoth: true,
    );
  }

  /// Configuration personnalisée
  factory PaymentMethodConfig.custom({
    required List<PaymentMethod> methods,
    bool allowBoth = false,
    String? mobileMoneyLabel,
  }) {
    return PaymentMethodConfig(
      availableMethods: methods,
      allowBoth: allowBoth,
      mobileMoneyLabel: mobileMoneyLabel,
    );
  }
}
