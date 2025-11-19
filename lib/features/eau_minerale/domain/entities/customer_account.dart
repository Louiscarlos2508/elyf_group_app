/// Basic representation of a B2B customer buying sachets of water.
class CustomerAccount {
  const CustomerAccount({
    required this.id,
    required this.name,
    required this.outstandingCredit,
    required this.lastOrderDate,
    required this.phone,
  });

  final String id;
  final String name;
  final int outstandingCredit;
  final DateTime lastOrderDate;
  final String phone;

  bool get hasCredit => outstandingCredit > 0;

  factory CustomerAccount.sample(int index) {
    return CustomerAccount(
      id: 'client-$index',
      name: 'Client dépôt #$index',
      outstandingCredit: index.isEven ? 0 : 48000,
      lastOrderDate: DateTime.now().subtract(Duration(days: index)),
      phone: '+22177000${400 + index}',
    );
  }
}
