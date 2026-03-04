/// Type de collecte.
enum CollectionType {
  wholesaler('Grossiste'),
  pointOfSale('Point de vente');

  const CollectionType(this.label);
  final String label;
}

/// Représente une collecte de bouteilles vides.
class Collection {
  const Collection({
    required this.id,
    required this.type,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.emptyBottles,
    required this.unitPrice,
    this.clientAddress,
    this.leaks = const {},
    this.amountPaid = 0.0,
    this.paymentDate,
    this.unitPricesByWeight, // poids -> prix unitaire (pour prix en gros par poids)
    this.sessionId,
    this.tourId,
    this.fullBottlesReceived = const {}, 
    this.receptionDate,
    this.receptionUserId,
  });

  final String id;
  final CollectionType type;
  final String clientId; // ID du grossiste ou point de vente
  final String clientName;
  final String clientPhone;
  final String? clientAddress;
  final Map<int, int> emptyBottles; // poids -> quantité
  final Map<int, int> leaks; // poids -> quantité de fuites
  final double unitPrice; // Prix unitaire par défaut (pour compatibilité)
  final Map<int, double>?
  unitPricesByWeight; // poids -> prix unitaire (prioritaire si défini)
  final double amountPaid;
  final DateTime? paymentDate;
  final String? sessionId;
  final String? tourId;
  final Map<int, int> fullBottlesReceived;
  final DateTime? receptionDate;
  final String? receptionUserId;

  Collection copyWith({
    String? id,
    CollectionType? type,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientAddress,
    Map<int, int>? emptyBottles,
    Map<int, int>? leaks,
    double? unitPrice,
    Map<int, double>? unitPricesByWeight,
    double? amountPaid,
    DateTime? paymentDate,
    String? sessionId,
    String? tourId,
    Map<int, int>? fullBottlesReceived,
  }) {
    return Collection(
      id: id ?? this.id,
      type: type ?? this.type,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      emptyBottles: emptyBottles ?? this.emptyBottles,
      leaks: leaks ?? this.leaks,
      unitPrice: unitPrice ?? this.unitPrice,
      unitPricesByWeight: unitPricesByWeight ?? this.unitPricesByWeight,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      sessionId: sessionId ?? this.sessionId,
      tourId: tourId ?? this.tourId,
      fullBottlesReceived: fullBottlesReceived ?? this.fullBottlesReceived,
      receptionDate: receptionDate ?? this.receptionDate,
      receptionUserId: receptionUserId ?? this.receptionUserId,
    );
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    // Convert cylinderQuantities/pointOfSaleId to new structure
    final cylinderQuantities =
        (map['cylinderQuantities'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
            ) ??
            (map['emptyBottles'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
            ) ??
            {};

    // Récupérer unitPricesByWeight si disponible (pour prix en gros par poids)
    final unitPricesByWeightRaw =
        map['unitPricesByWeight'] as Map<String, dynamic>?;
    final unitPricesByWeight = unitPricesByWeightRaw?.map(
      (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
    );

    // Récupérer les fuites si disponibles
    final leaksRaw = map['leaks'] as Map<String, dynamic>?;
    final leaks = leaksRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        <int, int>{};

    final fullBottlesReceivedRaw = map['fullBottlesReceived'] as Map<String, dynamic>?;
    final fullBottlesReceived = fullBottlesReceivedRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        <int, int>{};

    return Collection(
      id: map['id'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      type: CollectionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => CollectionType.pointOfSale,
      ),
      clientId:
          map['clientId'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      clientName:
          map['clientName'] as String? ??
          map['pointOfSaleName'] as String? ??
          '',
      clientPhone: map['clientPhone'] as String? ?? '',
      clientAddress: map['clientAddress'] as String?,
      emptyBottles: cylinderQuantities,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ??
          (map['amountDue'] as num?)?.toDouble() ??
          0.0,
      unitPricesByWeight: unitPricesByWeight,
      leaks: leaks,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
      sessionId: map['sessionId'] as String?,
      tourId: map['tourId'] as String?,
      fullBottlesReceived: fullBottlesReceived,
      receptionDate: map['receptionDate'] != null
          ? DateTime.parse(map['receptionDate'] as String)
          : null,
      receptionUserId: map['receptionUserId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'emptyBottles': emptyBottles.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'unitPrice': unitPrice,
      'unitPricesByWeight': unitPricesByWeight?.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'leaks': leaks.map((k, v) => MapEntry(k.toString(), v)),
      'amountPaid': amountPaid,
      'paymentDate': paymentDate?.toIso8601String(),
      'sessionId': sessionId,
      'tourId': tourId,
      'fullBottlesReceived': fullBottlesReceived.map((k, v) => MapEntry(k.toString(), v)),
      'receptionDate': receptionDate?.toIso8601String(),
      'receptionUserId': receptionUserId,
    };
  }

  /// Calcule le total des bouteilles collectées.
  int get totalBottles {
    return emptyBottles.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Alias pour compatibilité
  int get totalEmptyBottles => totalBottles;

  /// Calcule le total des bouteilles pleines reçues.
  int get totalFullBottlesReceived {
    return fullBottlesReceived.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Calcule le total des fuites.
  int get totalLeaks {
    return leaks.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Récupère le prix unitaire pour un poids donné.
  double getUnitPriceForWeight(int weight) {
    // Utiliser le prix spécifique au poids si disponible, sinon le prix par défaut
    // Gérer le cas où unitPricesByWeight pourrait être null (collections existantes)
    if (unitPricesByWeight == null || unitPricesByWeight!.isEmpty) {
      return unitPrice;
    }
    return unitPricesByWeight![weight] ?? unitPrice;
  }

  /// Calcule le montant dû.
  /// Pour les grossistes liés à un tour, on base le calcul sur fullBottlesReceived si non vide.
  double get amountDue {
    double total = 0.0;
    
    // Si c'est un grossiste et qu'on a des bouteilles pleines attribuées (via tour)
    if (type == CollectionType.wholesaler && fullBottlesReceived.isNotEmpty) {
      for (final entry in fullBottlesReceived.entries) {
        final weight = entry.key;
        final qty = entry.value;
        final price = getUnitPriceForWeight(weight);
        total += qty * price;
      }
      return total;
    }

    // Sinon (POS ou grossiste hors tour), on base sur les vides collectés moins les fuites
    for (final entry in emptyBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      final leakQty = leaks[weight] ?? 0;
      final validBottles = qty - leakQty;
      final price = getUnitPriceForWeight(weight);
      total += validBottles * price;
    }
    return total;
  }

  /// Calcule le montant après déduction des fuites.
  double get amountAfterLeaks {
    return amountDue;
  }

  /// Calcule le reste à payer.
  double get remainingAmount {
    return (amountDue - amountPaid).clamp(0.0, double.infinity);
  }

  /// Vérifie si le paiement est complet.
  bool get isPaymentComplete {
    return amountPaid >= amountDue;
  }
}
