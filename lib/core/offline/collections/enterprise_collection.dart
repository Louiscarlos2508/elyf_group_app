import 'package:isar/isar.dart';

import '../../../features/administration/domain/entities/enterprise.dart';

part 'enterprise_collection.g.dart';

/// Isar collection for storing Enterprise entities offline.
@collection
class EnterpriseCollection {
  Id id = Isar.autoIncrement;

  /// Remote Firebase document ID.
  @Index(unique: true)
  late String remoteId;

  /// Enterprise name.
  @Index()
  late String name;

  /// Enterprise type (eau_minerale, gaz, orange_money, immobilier, boutique).
  @Index()
  late String type;

  /// Description of the enterprise.
  String? description;

  /// Physical address.
  String? address;

  /// Contact phone number.
  String? phone;

  /// Contact email.
  String? email;

  /// Whether the enterprise is active.
  @Index()
  bool isActive = true;

  /// Timestamp when created on the server.
  DateTime? createdAt;

  /// Timestamp when last updated on the server.
  @Index()
  DateTime? updatedAt;

  /// Local timestamp when this record was last modified.
  @Index()
  late DateTime localUpdatedAt;

  /// Creates an empty collection instance.
  EnterpriseCollection();

  /// Creates from a domain Enterprise entity.
  factory EnterpriseCollection.fromEntity(Enterprise entity) {
    return EnterpriseCollection()
      ..remoteId = entity.id
      ..name = entity.name
      ..type = entity.type
      ..description = entity.description
      ..address = entity.address
      ..phone = entity.phone
      ..email = entity.email
      ..isActive = entity.isActive
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..localUpdatedAt = DateTime.now();
  }

  /// Converts to a domain Enterprise entity.
  Enterprise toEntity() {
    return Enterprise(
      id: remoteId,
      name: name,
      type: type,
      description: description,
      address: address,
      phone: phone,
      email: email,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Updates this collection from an entity.
  void updateFromEntity(Enterprise entity) {
    name = entity.name;
    type = entity.type;
    description = entity.description;
    address = entity.address;
    phone = entity.phone;
    email = entity.email;
    isActive = entity.isActive;
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
    localUpdatedAt = DateTime.now();
  }
}
