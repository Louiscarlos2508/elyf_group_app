import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String enterpriseId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? category;
  final int balance; // Positive if we owe money to the supplier (debt)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.enterpriseId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.category,
    this.balance = 0,
    this.createdAt,
    this.updatedAt,
  });

  Supplier copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? category,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      category: category ?? this.category,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'category': category,
      'balance': balance,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Supplier(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      category: map['category'] as String?,
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        enterpriseId,
        name,
        phone,
        email,
        address,
        category,
        balance,
        createdAt,
        updatedAt,
      ];
}
