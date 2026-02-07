import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/property.dart';

class PaymentListFilterNotifier extends Notifier<PaymentStatus?> {
  @override
  PaymentStatus? build() => null;
  void set(PaymentStatus? status) => state = status;
}

final paymentListFilterProvider = NotifierProvider<PaymentListFilterNotifier, PaymentStatus?>(PaymentListFilterNotifier.new);

class ExpenseListFilterNotifier extends Notifier<ExpenseCategory?> {
  @override
  ExpenseCategory? build() => null;
  void set(ExpenseCategory? category) => state = category;
}

final expenseListFilterProvider = NotifierProvider<ExpenseListFilterNotifier, ExpenseCategory?>(ExpenseListFilterNotifier.new);

class PropertyListFilterNotifier extends Notifier<PropertyStatus?> {
  @override
  PropertyStatus? build() => null;
  void set(PropertyStatus? status) => state = status;
}

final propertyListFilterProvider = NotifierProvider<PropertyListFilterNotifier, PropertyStatus?>(PropertyListFilterNotifier.new);
