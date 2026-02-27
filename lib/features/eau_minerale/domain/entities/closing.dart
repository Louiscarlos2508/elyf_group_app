import 'package:equatable/equatable.dart';

/// Status of a financial session in Eau Minerale.
enum ClosingStatus {
  open,
  closed,
}

/// Represents a financial session (Z-Report) for the Eau Minerale module.
class Closing extends Equatable {
  const Closing({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.date,
    this.openingDate,
    required this.digitalRevenue, // Total theoretical revenue (Total Collections)
    required this.digitalExpenses, // Total expenses (Total Charges)
    this.cashRevenue = 0,
    this.mmRevenue = 0,
    this.cashExpenses = 0,
    this.mmExpenses = 0,
    required this.openingCashAmount, // Fond de caisse
    required this.physicalCashAmount, // Actual cash counted at closing
    this.physicalMmAmount = 0, // Actual MM balance counted at closing
    this.status = ClosingStatus.closed,
    this.notes,
    this.openingNotes,
    this.number, // Session number (ex: SES-EAU-20240217-001)
  });

  final String id;
  final String enterpriseId;
  final String userId;
  final DateTime date;
  final DateTime? openingDate;
  
  final int digitalRevenue;
  final int digitalExpenses;
  final int cashRevenue;
  final int mmRevenue;
  final int cashExpenses;
  final int mmExpenses;
  
  final int openingCashAmount;
  final int physicalCashAmount;
  final int physicalMmAmount;

  final ClosingStatus status;
  final String? notes;
  final String? openingNotes;
  final String? number;

  /// Expected cash in hand (Physical + Digital for the platform, but here mainly focused on cash ledger)
  /// Solde théorique total: Opening + Total Collections - Total Expenses
  int get expectedTotalBalance => openingCashAmount + digitalRevenue - digitalExpenses;

  /// Theoretical cash only: Opening + Cash Collections - Cash Expenses
  int get expectedCash => openingCashAmount + cashRevenue - cashExpenses;

  /// Theoretical Mobile Money: MM Collections - MM Expenses
  int get expectedMM => mmRevenue - mmExpenses;
  
  /// Cash discrepancy: Physical Cash - Expected Cash
  int get cashDiscrepancy => physicalCashAmount - expectedCash;

  /// MM discrepancy: Physical MM - Expected MM
  int get mmDiscrepancy => physicalMmAmount - expectedMM;

  /// Total discrepancy
  int get totalDiscrepancy => cashDiscrepancy + mmDiscrepancy;

  Closing copyWith({
    String? id,
    String? enterpriseId,
    String? userId,
    DateTime? date,
    DateTime? openingDate,
    int? digitalRevenue,
    int? digitalExpenses,
    int? cashRevenue,
    int? mmRevenue,
    int? cashExpenses,
    int? mmExpenses,
    int? openingCashAmount,
    int? physicalCashAmount,
    int? physicalMmAmount,
    ClosingStatus? status,
    String? notes,
    String? openingNotes,
    String? number,
  }) {
    return Closing(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      openingDate: openingDate ?? this.openingDate,
      digitalRevenue: digitalRevenue ?? this.digitalRevenue,
      digitalExpenses: digitalExpenses ?? this.digitalExpenses,
      cashRevenue: cashRevenue ?? this.cashRevenue,
      mmRevenue: mmRevenue ?? this.mmRevenue,
      cashExpenses: cashExpenses ?? this.cashExpenses,
      mmExpenses: mmExpenses ?? this.mmExpenses,
      openingCashAmount: openingCashAmount ?? this.openingCashAmount,
      physicalCashAmount: physicalCashAmount ?? this.physicalCashAmount,
      physicalMmAmount: physicalMmAmount ?? this.physicalMmAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      openingNotes: openingNotes ?? this.openingNotes,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'userId': userId,
      'date': date.toIso8601String(),
      'openingDate': openingDate?.toIso8601String(),
      'digitalRevenue': digitalRevenue,
      'digitalExpenses': digitalExpenses,
      'cashRevenue': cashRevenue,
      'mmRevenue': mmRevenue,
      'cashExpenses': cashExpenses,
      'mmExpenses': mmExpenses,
      'openingCashAmount': openingCashAmount,
      'physicalCashAmount': physicalCashAmount,
      'physicalMmAmount': physicalMmAmount,
      'status': status.name,
      'notes': notes,
      'openingNotes': openingNotes,
      'number': number,
    };
  }

  factory Closing.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Closing(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      userId: map['userId'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      openingDate: map['openingDate'] != null ? DateTime.parse(map['openingDate'] as String) : null,
      digitalRevenue: (map['digitalRevenue'] as num?)?.toInt() ?? 0,
      digitalExpenses: (map['digitalExpenses'] as num?)?.toInt() ?? 0,
      cashRevenue: (map['cashRevenue'] as num?)?.toInt() ?? 0,
      mmRevenue: (map['mmRevenue'] as num?)?.toInt() ?? 0,
      cashExpenses: (map['cashExpenses'] as num?)?.toInt() ?? 0,
      mmExpenses: (map['mmExpenses'] as num?)?.toInt() ?? 0,
      openingCashAmount: (map['openingCashAmount'] as num?)?.toInt() ?? 0,
      physicalCashAmount: (map['physicalCashAmount'] as num?)?.toInt() ?? 0,
      physicalMmAmount: (map['physicalMmAmount'] as num?)?.toInt() ?? 0,
      status: ClosingStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'closed'),
        orElse: () => ClosingStatus.closed,
      ),
      notes: map['notes'] as String?,
      openingNotes: map['openingNotes'] as String?,
      number: map['number'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        enterpriseId,
        userId,
        date,
        openingDate,
        digitalRevenue,
        digitalExpenses,
        cashRevenue,
        mmRevenue,
        cashExpenses,
        mmExpenses,
        openingCashAmount,
        physicalCashAmount,
        physicalMmAmount,
        status,
        notes,
        openingNotes,
        number,
      ];
}
