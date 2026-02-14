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

enum ArchiveFilter {
  active,
  archived,
  all;

  bool? get asBool {
    switch (this) {
      case ArchiveFilter.active: return false;
      case ArchiveFilter.archived: return true;
      case ArchiveFilter.all: return null;
    }
  }
}

class ArchiveFilterNotifier extends Notifier<ArchiveFilter> {
  @override
  ArchiveFilter build() => ArchiveFilter.active;
  void set(ArchiveFilter filter) => state = filter;
}

final archiveFilterProvider = NotifierProvider<ArchiveFilterNotifier, ArchiveFilter>(ArchiveFilterNotifier.new);
