/// Represents an employee (fixed or production-based).
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.monthlySalary,
    this.position,
    this.hireDate,
  });

  final String id;
  final String name;
  final String phone;
  final EmployeeType type;
  final int monthlySalary;
  final String? position;
  final DateTime? hireDate;

  factory Employee.sample(int index) {
    return Employee(
      id: 'employee-$index',
      name: 'Employé ${index + 1}',
      phone: '+22177000${100 + index}',
      type: index.isEven ? EmployeeType.fixed : EmployeeType.production,
      monthlySalary: 50000 + (index * 10000),
      position: index.isEven ? 'Opérateur' : 'Superviseur',
      hireDate: DateTime.now().subtract(Duration(days: 30 * (index + 1))),
    );
  }
}

enum EmployeeType { fixed, production }

