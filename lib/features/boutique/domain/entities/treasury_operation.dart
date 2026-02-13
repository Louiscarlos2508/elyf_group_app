import 'package:equatable/equatable.dart';
import 'sale.dart' show PaymentMethod;

/// Type of treasury operation.
enum TreasuryOperationType {
  supply, // Apport de fonds
  removal, // Retrait de fonds
  transfer, // Transfert entre comptes
  adjustment, // Ajustement de solde
}

/// Represents a cash flow operation (manual or internal).
class TreasuryOperation extends Equatable {
  const TreasuryOperation({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.amount,
    required this.type,
    this.fromAccount,
    this.toAccount,
    required this.date,
    this.reason,
    this.recipient,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.number,
  });

  final String id;
  final String enterpriseId;
  final String userId;
  final int amount;
  final TreasuryOperationType type;
  final PaymentMethod? fromAccount;
  final PaymentMethod? toAccount;
  final DateTime date;
  final String? reason; // e.g., 'Retrait Superviseur', 'Caution', 'Dépôt'
  final String? recipient; // Who took the money (e.g., name of supervisor)
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? number; // ex: TRE-20240213-001

  TreasuryOperation copyWith({
    String? id,
    String? enterpriseId,
    String? userId,
    int? amount,
    TreasuryOperationType? type,
    PaymentMethod? fromAccount,
    PaymentMethod? toAccount,
    DateTime? date,
    String? reason,
    String? recipient,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? number,
  }) {
    return TreasuryOperation(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      recipient: recipient ?? this.recipient,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      number: number ?? this.number,
    );
  }

  factory TreasuryOperation.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return TreasuryOperation(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num).toInt(),
      type: TreasuryOperationType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => TreasuryOperationType.adjustment,
      ),
      fromAccount: map['fromAccount'] != null 
          ? PaymentMethod.values.firstWhere((e) => e.name == map['fromAccount']) 
          : null,
      toAccount: map['toAccount'] != null 
          ? PaymentMethod.values.firstWhere((e) => e.name == map['toAccount']) 
          : null,
      date: DateTime.parse(map['date'] as String),
      reason: map['reason'] as String?,
      recipient: map['recipient'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      number: map['number'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'fromAccount': fromAccount?.name,
      'toAccount': toAccount?.name,
      'date': date.toIso8601String(),
      'reason': reason,
      'recipient': recipient,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'number': number,
    };
  }

  @override
  List<Object?> get props => [
        id,
        enterpriseId,
        userId,
        amount,
        type,
        fromAccount,
        toAccount,
        date,
        reason,
        recipient,
        notes,
        createdAt,
        updatedAt,
        number,
      ];
}
