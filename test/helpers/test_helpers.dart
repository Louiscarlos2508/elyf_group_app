/// Helpers pour faciliter l'écriture de tests.
library;

import 'package:elyf_groupe_app/core/offline/drift/app_database.dart';
import 'package:elyf_groupe_app/core/offline/drift/offline_record_dao.dart';
import 'package:elyf_groupe_app/core/offline/drift/sync_operation_dao.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/contract.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/tenant.dart';

/// Crée une base de données Drift en mémoire pour les tests.
///
/// Note: Cette fonction est principalement pour les tests d'intégration.
/// Pour les tests unitaires, il est recommandé de mocker DriftService
/// plutôt que d'utiliser une vraie base de données.
AppDatabase createTestDatabase() {
  // AppDatabase() appelle super(openDriftConnection()) qui nécessite path_provider.
  // Pour les tests, on devrait mocker DriftService ou utiliser une base en mémoire.
  // Cette fonction retourne une instance normale qui devra être mockée dans les tests unitaires.
  // Pour les tests d'intégration, on peut utiliser une vraie base de données.
  return AppDatabase();
}

/// Setup pour un test avec Drift.
///
/// Retourne un tuple avec la base de données, le DAO des records et le DAO des sync operations.
///
/// Note: Pour les tests unitaires, il est recommandé de mocker DriftService
/// plutôt que d'utiliser une vraie base de données. Cette fonction est utile
/// pour les tests d'intégration.
Future<(AppDatabase, OfflineRecordDao, SyncOperationDao)> setupDriftTest() async {
  // Pour les tests, on peut utiliser une base en mémoire
  // mais AppDatabase utilise openDriftConnection() qui nécessite path_provider.
  // Pour les tests unitaires, on devrait mocker DriftService.
  // Cette fonction est principalement pour les tests d'intégration.
  final db = createTestDatabase();
  await db.customStatement('PRAGMA foreign_keys = ON');
  final records = OfflineRecordDao(db);
  final syncOperations = SyncOperationDao(db);
  return (db, records, syncOperations);
}

/// Teardown pour un test avec Drift.
Future<void> teardownDriftTest(AppDatabase db) async {
  await db.close();
}

/// Crée un Cylinder de test.
Cylinder createTestCylinder({
  String? id,
  int? weight,
  double? buyPrice,
  double? sellPrice,
  String? enterpriseId,
  String? moduleId,
  int? stock,
}) {
  return Cylinder(
    id: id ?? 'cylinder-1',
    weight: weight ?? 12,
    buyPrice: buyPrice ?? 5000.0,
    sellPrice: sellPrice ?? 6000.0,
    enterpriseId: enterpriseId ?? 'enterprise-1',
    moduleId: moduleId ?? 'gaz',
    stock: stock ?? 100,
  );
}

/// Crée une GasSale de test.
GasSale createTestGasSale({
  String? id,
  String? cylinderId,
  int? quantity,
  double? unitPrice,
  double? totalAmount,
  DateTime? saleDate,
  SaleType? saleType,
  String? customerName,
  String? customerPhone,
  String? notes,
}) {
  return GasSale(
    id: id ?? 'sale-1',
    cylinderId: cylinderId ?? 'cylinder-1',
    quantity: quantity ?? 1,
    unitPrice: unitPrice ?? 6000.0,
    totalAmount: totalAmount ?? 6000.0,
    saleDate: saleDate ?? DateTime(2026, 1, 1),
    saleType: saleType ?? SaleType.retail,
    customerName: customerName,
    customerPhone: customerPhone,
    notes: notes,
  );
}

/// Crée une GazExpense de test.
GazExpense createTestGazExpense({
  String? id,
  ExpenseCategory? category,
  double? amount,
  String? description,
  DateTime? date,
  String? enterpriseId,
  bool? isFixed,
  String? notes,
}) {
  return GazExpense(
    id: id ?? 'expense-1',
    category: category ?? ExpenseCategory.maintenance,
    amount: amount ?? 10000.0,
    description: description ?? 'Test expense',
    date: date ?? DateTime(2026, 1, 1),
    enterpriseId: enterpriseId ?? 'enterprise-1',
    isFixed: isFixed ?? false,
    notes: notes,
  );
}

/// Crée une Property de test.
Property createTestProperty({
  String? id,
  String? address,
  String? city,
  PropertyType? propertyType,
  int? rooms,
  int? area,
  int? price,
  PropertyStatus? status,
  String? description,
  List<String>? images,
  List<String>? amenities,
}) {
  return Property(
    id: id ?? 'property-1',
    address: address ?? '123 Test Street',
    city: city ?? 'Test City',
    propertyType: propertyType ?? PropertyType.house,
    rooms: rooms ?? 3,
    area: area ?? 100,
    price: price ?? 50000,
    status: status ?? PropertyStatus.available,
    description: description,
    images: images,
    amenities: amenities,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// Crée un Tenant de test.
Tenant createTestTenant({
  String? id,
  String? fullName,
  String? phone,
  String? email,
  String? address,
  String? idNumber,
  String? emergencyContact,
  String? notes,
}) {
  return Tenant(
    id: id ?? 'tenant-1',
    fullName: fullName ?? 'John Doe',
    phone: phone ?? '+226 70 12 34 56',
    email: email ?? 'john.doe@example.com',
    address: address,
    idNumber: idNumber,
    emergencyContact: emergencyContact,
    notes: notes,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// Crée un Contract de test.
Contract createTestContract({
  String? id,
  String? propertyId,
  String? tenantId,
  DateTime? startDate,
  DateTime? endDate,
  int? monthlyRent,
  int? deposit,
  ContractStatus? status,
  Property? property,
  Tenant? tenant,
  int? paymentDay,
  String? notes,
  int? depositInMonths,
}) {
  return Contract(
    id: id ?? 'contract-1',
    propertyId: propertyId ?? 'property-1',
    tenantId: tenantId ?? 'tenant-1',
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: endDate ?? DateTime(2026, 12, 31),
    monthlyRent: monthlyRent ?? 50000,
    deposit: deposit ?? 100000,
    status: status ?? ContractStatus.active,
    property: property,
    tenant: tenant,
    paymentDay: paymentDay ?? 1,
    notes: notes,
    depositInMonths: depositInMonths,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// IDs de test constants.
class TestIds {
  static const String enterprise1 = 'enterprise-1';
  static const String enterprise2 = 'enterprise-2';
  static const String moduleGaz = 'gaz';
  static const String moduleImmobilier = 'immobilier';
  static const String userId1 = 'user-1';
  static const String userId2 = 'user-2';
}
