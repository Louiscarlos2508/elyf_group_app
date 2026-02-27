/// Represents a Mobile Money customer.
class Customer {
  const Customer({
    required this.id,
    required this.enterpriseId,
    required this.phoneNumber,
    required this.name,
    this.email,
    this.totalTransactions = 0,
    this.totalAmount = 0,
    this.lastTransactionDate,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final String phoneNumber;
  final String name;
  final String? email;
  final int totalTransactions;
  final int totalAmount; // Total in FCFA
  final DateTime? lastTransactionDate;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  Customer copyWith({
    String? id,
    String? enterpriseId,
    String? phoneNumber,
    String? name,
    String? email,
    int? totalTransactions,
    int? totalAmount,
    DateTime? lastTransactionDate,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalAmount: totalAmount ?? this.totalAmount,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return Customer(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      phoneNumber: map['phoneNumber'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      totalTransactions: (map['totalTransactions'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      lastTransactionDate: map['lastTransactionDate'] != null
          ? DateTime.parse(map['lastTransactionDate'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'totalTransactions': totalTransactions,
      'totalAmount': totalAmount,
      'lastTransactionDate': lastTransactionDate?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
