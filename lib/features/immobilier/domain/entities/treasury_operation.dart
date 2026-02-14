import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/payment_method.dart';

/// Type of treasury operation.
enum TreasuryOperationType {
  supply, // Apport de fonds (ex: Loyer)
  removal, // Retrait de fonds (ex: Dépense)
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
    this.referenceEntityId,
    this.referenceEntityType,
  });

  final String id;
  final String enterpriseId;
  final String userId;
  final int amount;
  final TreasuryOperationType type;
  final PaymentMethod? fromAccount;
  final PaymentMethod? toAccount;
  final DateTime date;
  final String? reason; // e.g., 'Retrait Superviseur', 'Paiement Loyer'
  final String? recipient;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? number; // ex: TRE-IMMO-20240213-001
  
  // Link to other entities (e.g. Payment ID, Expense ID)
  final String? referenceEntityId;
  final String? referenceEntityType; // 'payment', 'expense'

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
    String? referenceEntityId,
    String? referenceEntityType,
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
      referenceEntityId: referenceEntityId ?? this.referenceEntityId,
      referenceEntityType: referenceEntityType ?? this.referenceEntityType,
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
      referenceEntityId: map['referenceEntityId'] as String?,
      referenceEntityType: map['referenceEntityType'] as String?,
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
      'referenceEntityId': referenceEntityId,
      'referenceEntityType': referenceEntityType,
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
        referenceEntityId,
        referenceEntityType,
      ];
}
