/// Represents a gas depot.
class Depot {
  const Depot({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.managerName,
    this.totalCylinders = 0,
    this.availableCylinders = 0,
  });

  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? managerName;
  final int totalCylinders;
  final int availableCylinders;
}

