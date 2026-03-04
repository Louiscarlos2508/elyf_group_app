import 'package:equatable/equatable.dart';

class GazEmployee extends Equatable {
  final String id;
  final String enterpriseId;
  final String name;
  final String phone;
  final String role;
  final double baseSalary;
  final bool isActive;
  final DateTime createdAt;

  const GazEmployee({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.phone,
    required this.role,
    required this.baseSalary,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    enterpriseId,
    name,
    phone,
    role,
    baseSalary,
    isActive,
    createdAt,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'phone': phone,
      'role': role,
      'baseSalary': baseSalary,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GazEmployee.fromJson(Map<String, dynamic> json) {
    return GazEmployee(
      id: json['id'] as String,
      enterpriseId: json['enterpriseId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  GazEmployee copyWith({
    String? name,
    String? phone,
    String? role,
    double? baseSalary,
    bool? isActive,
  }) {
    return GazEmployee(
      id: id,
      enterpriseId: enterpriseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      baseSalary: baseSalary ?? this.baseSalary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
