import 'package:isar/isar.dart';

part 'expense_collection.g.dart';

/// Isar collection for storing Expense entities offline.
///
/// This is a unified expense collection that can store expenses from
/// multiple modules (boutique, eau_minerale, gaz, immobilier, etc.).
@collection
class ExpenseCollection {
  Id id = Isar.autoIncrement;

  /// Remote Firebase document ID.
  @Index()
  String? remoteId;

  /// Local unique identifier (UUID).
  @Index(unique: true)
  late String localId;

  /// Enterprise this expense belongs to.
  @Index()
  late String enterpriseId;

  /// Module type (boutique, eau_minerale, gaz, immobilier).
  @Index()
  late String moduleType;

  /// Expense date.
  @Index()
  late DateTime expenseDate;

  /// Expense amount.
  late double amount;

  /// Category of expense.
  @Index()
  late String category;

  /// Description of the expense.
  String? description;

  /// Who made the expense.
  String? paidBy;

  /// Payment method.
  String? paymentMethod;

  /// Reference number (receipt, invoice).
  String? reference;

  /// Related entity ID (property, tour, etc.).
  String? relatedEntityId;

  /// Type of related entity.
  String? relatedEntityType;

  /// Whether the expense is approved.
  bool isApproved = true;

  /// Timestamp when created on the server.
  DateTime? createdAt;

  /// Timestamp when last updated on the server.
  DateTime? updatedAt;

  /// Local timestamp when this record was last modified.
  @Index()
  late DateTime localUpdatedAt;

  /// Creates an empty collection instance.
  ExpenseCollection();

  /// Creates an expense from a map.
  factory ExpenseCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    return ExpenseCollection()
      ..remoteId = map['id'] as String?
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..expenseDate = map['expenseDate'] != null
          ? DateTime.parse(map['expenseDate'] as String)
          : (map['date'] != null
              ? DateTime.parse(map['date'] as String)
              : DateTime.now())
      ..amount = (map['amount'] as num?)?.toDouble() ?? 0
      ..category = map['category'] as String? ?? 'Autre'
      ..description = map['description'] as String?
      ..paidBy = map['paidBy'] as String?
      ..paymentMethod = map['paymentMethod'] as String?
      ..reference = map['reference'] as String?
      ..relatedEntityId = map['relatedEntityId'] as String?
      ..relatedEntityType = map['relatedEntityType'] as String?
      ..isApproved = map['isApproved'] as bool? ?? true
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null
      ..localUpdatedAt = DateTime.now();
  }

  /// Converts to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': remoteId,
      'localId': localId,
      'enterpriseId': enterpriseId,
      'expenseDate': expenseDate.toIso8601String(),
      'amount': amount,
      'category': category,
      'description': description,
      'paidBy': paidBy,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'isApproved': isApproved,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Common expense categories across modules.
class ExpenseCategories {
  ExpenseCategories._();

  static const String transport = 'Transport';
  static const String salary = 'Salaire';
  static const String utilities = 'Utilities';
  static const String maintenance = 'Maintenance';
  static const String supplies = 'Fournitures';
  static const String rent = 'Loyer';
  static const String taxes = 'Taxes';
  static const String other = 'Autre';

  static const List<String> all = [
    transport,
    salary,
    utilities,
    maintenance,
    supplies,
    rent,
    taxes,
    other,
  ];
}
