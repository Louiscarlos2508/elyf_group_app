import 'package:elyf_groupe_app/shared/domain/services/filtering/generic_list_filter_service.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../entities/payment.dart';

/// Service for filtering and sorting payments in Immobilier module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class PaymentFilterService {
  PaymentFilterService();

  final _genericFilter = GenericListFilterService<Payment>();

  /// Filters and sorts payments.
  List<Payment> filterAndSort({
    required List<Payment> payments,
    String? searchQuery,
    PaymentStatus? status,
    PaymentMethod? method,
  }) {
    var filtered = payments;

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = _genericFilter.filterBySearch(
        items: filtered,
        searchQuery: searchQuery,
        getSearchableFields: (payment) => [
          payment.id,
          payment.receiptNumber ?? '',
          payment.contract?.property?.address ?? '',
          payment.contract?.tenant?.fullName ?? '',
        ],
      );
    }

    // Filter by status
    if (status != null) {
      filtered = filtered.where((p) => p.status == status).toList();
    }

    // Filter by method
    if (method != null) {
      filtered = filtered.where((p) => p.paymentMethod == method).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return filtered;
  }
}
