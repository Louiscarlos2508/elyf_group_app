
import 'package:equatable/equatable.dart';

/// Représente un grossiste (Client B2B) dans le module Gaz.
class Wholesaler extends Equatable {
  const Wholesaler({
    required this.id,
    required this.enterpriseId,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.tier = 'default',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final String tier; // 'default', 'bronze', 'silver', 'gold'
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Wholesaler copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    String? phone,
    String? address,
    String? email,
    String? tier,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wholesaler(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Wholesaler.fromMap(Map<String, dynamic> map) {
    // Prioritize embedded localId to maintain offline relations on new devices
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    return Wholesaler(
      id: objectId,
      enterpriseId: map['enterpriseId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      tier: map['tier'] as String? ?? 'default',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'tier': tier,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        enterpriseId,
        name,
        phone,
        address,
        email,
        tier,
        isActive,
        createdAt,
        updatedAt,
      ];
}
