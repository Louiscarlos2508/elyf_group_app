/// Represents a product sales summary in a report.
class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  final String productName;
  final int quantity;
  final int revenue;
}
