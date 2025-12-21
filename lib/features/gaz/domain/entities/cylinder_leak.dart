/// Statut d'une bouteille avec fuite.
enum LeakStatus {
  reported('Signalée'),
  sentForExchange('Envoyée pour échange'),
  exchanged('Échangée');

  const LeakStatus(this.label);
  final String label;
}

/// Représente une bouteille avec fuite (échange standard fournisseur).
class CylinderLeak {
  const CylinderLeak({
    required this.id,
    required this.cylinderId,
    required this.weight,
    required this.reportedDate,
    required this.status,
    this.exchangeDate,
    this.notes,
  });

  final String id;
  final String cylinderId;
  final int weight; // 3, 6, 10, 12
  final DateTime reportedDate;
  final LeakStatus status;
  final DateTime? exchangeDate;
  final String? notes;

  CylinderLeak copyWith({
    String? id,
    String? cylinderId,
    int? weight,
    DateTime? reportedDate,
    LeakStatus? status,
    DateTime? exchangeDate,
    String? notes,
  }) {
    return CylinderLeak(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      weight: weight ?? this.weight,
      reportedDate: reportedDate ?? this.reportedDate,
      status: status ?? this.status,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      notes: notes ?? this.notes,
    );
  }
}