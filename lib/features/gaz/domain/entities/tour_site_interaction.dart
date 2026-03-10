import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Type de site visité par le camion lors d'un tour.
enum SiteType {
  pos('Point de vente'),
  wholesaler('Grossiste'),
  supplier('Fournisseur'),
  other('Autre');

  const SiteType(this.label);
  final String label;
}

/// Représente un passage du camion sur un site (POS, Grossiste, etc.) lors d'un tour.
class TourSiteInteraction {
  const TourSiteInteraction({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.siteType,
    required this.emptyBottlesCollected,
    required this.fullBottlesDelivered,
    required this.timestamp,
    this.cashCollected = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.isProcessed = false,
    this.notes,
  });

  final String id;
  final String siteId;
  final String siteName;
  final SiteType siteType;
  final Map<int, int> emptyBottlesCollected;
  final Map<int, int> fullBottlesDelivered;
  final double cashCollected;
  final PaymentMethod paymentMethod;
  final bool isProcessed;
  final DateTime timestamp;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'siteName': siteName,
      'siteType': siteType.name,
      'emptyBottlesCollected': emptyBottlesCollected.map((k, v) => MapEntry(k.toString(), v)),
      'fullBottlesDelivered': fullBottlesDelivered.map((k, v) => MapEntry(k.toString(), v)),
      'cashCollected': cashCollected,
      'paymentMethod': paymentMethod.name,
      'isProcessed': isProcessed,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory TourSiteInteraction.fromMap(Map<String, dynamic> map) {
    return TourSiteInteraction(
      id: map['id'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      siteType: SiteType.values.firstWhere(
        (e) => e.name == map['siteType'],
        orElse: () => SiteType.other,
      ),
      emptyBottlesCollected: (map['emptyBottlesCollected'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
          ) ??
          const <int, int>{},
      fullBottlesDelivered: (map['fullBottlesDelivered'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
          ) ??
          const <int, int>{},
      cashCollected: (map['cashCollected'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.byName(map['paymentMethod'] as String)
          : PaymentMethod.cash,
      isProcessed: map['isProcessed'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  TourSiteInteraction copyWith({
    String? id,
    String? siteId,
    String? siteName,
    SiteType? siteType,
    Map<int, int>? emptyBottlesCollected,
    Map<int, int>? fullBottlesDelivered,
    double? cashCollected,
    PaymentMethod? paymentMethod,
    bool? isProcessed,
    DateTime? timestamp,
    String? notes,
  }) {
    return TourSiteInteraction(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      siteType: siteType ?? this.siteType,
      emptyBottlesCollected: emptyBottlesCollected ?? this.emptyBottlesCollected,
      fullBottlesDelivered: fullBottlesDelivered ?? this.fullBottlesDelivered,
      cashCollected: cashCollected ?? this.cashCollected,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isProcessed: isProcessed ?? this.isProcessed,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
  
  bool get isPos => siteType == SiteType.pos;
  bool get isWholesaler => siteType == SiteType.wholesaler;
}
