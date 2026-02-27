import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String enterpriseId;
  final String name;
  final int? colorValue; // ARGB
  final String? iconName;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.enterpriseId,
    required this.name,
    this.colorValue,
    this.iconName,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    int? colorValue,
    String? iconName,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Category(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int?,
      iconName: map['iconName'] as String?,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'colorValue': colorValue,
      'iconName': iconName,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, enterpriseId, name, colorValue, iconName, deletedAt];
}
