
import 'package:equatable/equatable.dart';

/// Status of a financial session.
enum ClosingStatus {
  open,
  closed,
}

/// Represents a financial session (opening and closing/reconciliation).
class Closing extends Equatable {
  const Closing({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.date,
    this.openingDate,
    required this.digitalRevenue, // Total theoretical revenue during session
    required this.digitalExpenses, // Total expenses during session
    required this.digitalNet, // Theoretical net amount (revenue - expenses)
    
    // Physical counts
    required this.physicalCashAmount, // Actual cash in hand at closing
    required this.physicalMobileMoneyAmount, // Actual MM balance at closing
    
    // Opening balances (Fonds de caisse)
    required this.openingCashAmount,
    required this.openingMobileMoneyAmount,
    
    // Discrepancies (Final Physical - (Opening + Digital Net))
    required this.discrepancy, // General discrepancy (total)
    required this.mobileMoneyDiscrepancy,
    
    // Split revenue for audit
    required this.digitalCashRevenue,
    required this.digitalMobileMoneyRevenue,
    
    this.status = ClosingStatus.closed,
    this.notes,
    this.openingNotes,
    this.number, // Numéro de session (ex: SES-20240212-001)
    this.isSynced = false,
  });

  final String id;
  final String enterpriseId;
  final String userId;
  final DateTime date; // Closing date
  final DateTime? openingDate;
  
  final int digitalRevenue;
  final int digitalExpenses;
  final int digitalNet;
  
  final int physicalCashAmount;
  final int physicalMobileMoneyAmount;
  
  final int openingCashAmount;
  final int openingMobileMoneyAmount;
  
  final int discrepancy;
  final int mobileMoneyDiscrepancy;
  
  final int digitalCashRevenue;
  final int digitalMobileMoneyRevenue;

  final ClosingStatus status;
  final String? notes; // Closing notes
  final String? openingNotes;
  final String? number;
  final bool isSynced;

  /// Theoretical cash that should be in hand: Opening Cash + Cash Revenue - Expenses
  int get expectedCash => openingCashAmount + (digitalCashRevenue - digitalExpenses);
  
  /// Theoretical MM that should be in account: Opening MM + MM Revenue
  int get expectedMobileMoney => openingMobileMoneyAmount + digitalMobileMoneyRevenue;

  /// Cash discrepancy: Physical Cash - Expected Cash
  int get cashDiscrepancy => physicalCashAmount - expectedCash;

  Closing copyWith({
    String? id,
    String? enterpriseId,
    String? userId,
    DateTime? date,
    DateTime? openingDate,
    int? digitalRevenue,
    int? digitalExpenses,
    int? digitalNet,
    int? physicalCashAmount,
    int? physicalMobileMoneyAmount,
    int? openingCashAmount,
    int? openingMobileMoneyAmount,
    int? discrepancy,
    int? mobileMoneyDiscrepancy,
    int? digitalCashRevenue,
    int? digitalMobileMoneyRevenue,
    ClosingStatus? status,
    String? notes,
    String? openingNotes,
    String? number,
    bool? isSynced,
  }) {
    return Closing(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      openingDate: openingDate ?? this.openingDate,
      digitalRevenue: digitalRevenue ?? this.digitalRevenue,
      digitalExpenses: digitalExpenses ?? this.digitalExpenses,
      digitalNet: digitalNet ?? this.digitalNet,
      physicalCashAmount: physicalCashAmount ?? this.physicalCashAmount,
      physicalMobileMoneyAmount: physicalMobileMoneyAmount ?? this.physicalMobileMoneyAmount,
      openingCashAmount: openingCashAmount ?? this.openingCashAmount,
      openingMobileMoneyAmount: openingMobileMoneyAmount ?? this.openingMobileMoneyAmount,
      discrepancy: discrepancy ?? this.discrepancy,
      mobileMoneyDiscrepancy: mobileMoneyDiscrepancy ?? this.mobileMoneyDiscrepancy,
      digitalCashRevenue: digitalCashRevenue ?? this.digitalCashRevenue,
      digitalMobileMoneyRevenue: digitalMobileMoneyRevenue ?? this.digitalMobileMoneyRevenue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      openingNotes: openingNotes ?? this.openingNotes,
      number: number ?? this.number,
      isSynced: isSynced ?? this.isSynced,
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
      'digitalNet': digitalNet,
      'physicalCashAmount': physicalCashAmount,
      'physicalMobileMoneyAmount': physicalMobileMoneyAmount,
      'openingCashAmount': openingCashAmount,
      'openingMobileMoneyAmount': openingMobileMoneyAmount,
      'discrepancy': discrepancy,
      'mobileMoneyDiscrepancy': mobileMoneyDiscrepancy,
      'digitalCashRevenue': digitalCashRevenue,
      'digitalMobileMoneyRevenue': digitalMobileMoneyRevenue,
      'status': status.name,
      'notes': notes,
      'openingNotes': openingNotes,
      'number': number,
      'isSynced': isSynced,
    };
  }

  factory Closing.fromMap(Map<String, dynamic> map, String enterpriseId) {
    return Closing(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: enterpriseId,
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      openingDate: map['openingDate'] != null ? DateTime.parse(map['openingDate']) : null,
      digitalRevenue: map['digitalRevenue'] ?? 0,
      digitalExpenses: map['digitalExpenses'] ?? 0,
      digitalNet: map['digitalNet'] ?? 0,
      physicalCashAmount: map['physicalCashAmount'] ?? 0,
      physicalMobileMoneyAmount: map['physicalMobileMoneyAmount'] ?? 0,
      openingCashAmount: map['openingCashAmount'] ?? 0,
      openingMobileMoneyAmount: map['openingMobileMoneyAmount'] ?? 0,
      discrepancy: map['discrepancy'] ?? 0,
      mobileMoneyDiscrepancy: map['mobileMoneyDiscrepancy'] ?? 0,
      digitalCashRevenue: map['digitalCashRevenue'] ?? 0,
      digitalMobileMoneyRevenue: map['digitalMobileMoneyRevenue'] ?? 0,
      status: ClosingStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'closed'),
        orElse: () => ClosingStatus.closed,
      ),
      notes: map['notes'],
      openingNotes: map['openingNotes'],
      number: map['number'],
      isSynced: map['isSynced'] ?? false,
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
        digitalNet,
        physicalCashAmount,
        physicalMobileMoneyAmount,
        openingCashAmount,
        openingMobileMoneyAmount,
        discrepancy,
        mobileMoneyDiscrepancy,
        digitalCashRevenue,
        digitalMobileMoneyRevenue,
        status,
        notes,
        openingNotes,
        number,
        isSynced,
      ];
}
