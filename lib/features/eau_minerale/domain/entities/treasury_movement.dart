import 'package:equatable/equatable.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Represents a generic financial movement in the Eau Minerale module.
/// Used to unify different transaction types (Sales, Expenses, etc.) in a single view.
class TreasuryMovement extends Equatable {
  const TreasuryMovement({
    required this.id,
    required this.date,
    required this.amount,
    required this.label,
    required this.category,
    required this.method,
    required this.isIncome,
    this.originalEntity,
  });

  final String id;
  final DateTime date;
  final int amount;
  final String label;
  final String category;
  final PaymentMethod method;
  final bool isIncome;
  
  /// The actual entity (Sale, ExpenseRecord, etc.) behind this movement.
  final dynamic originalEntity;

  @override
  List<Object?> get props => [id, date, amount, label, category, method, isIncome];
}
