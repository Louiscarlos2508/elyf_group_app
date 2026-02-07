import 'package:flutter/material.dart';
import '../entities/enterprise.dart';

/// Service for enterprise type mappings.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class EnterpriseTypeService {
  EnterpriseTypeService();

  /// Gets the icon for an enterprise type.
  /// Gets the icon for an enterprise type ID.
  IconData getTypeIcon(String typeId) {
    final type = EnterpriseType.fromId(typeId);
    
    switch (type.module) {
      case EnterpriseModule.eau:
        return Icons.water_drop_outlined;
      case EnterpriseModule.gaz:
        return Icons.local_fire_department_outlined;
      case EnterpriseModule.mobileMoney:
        return Icons.account_balance_wallet_outlined;
      case EnterpriseModule.immobilier:
        return Icons.home_work_outlined;
      case EnterpriseModule.boutique:
        return Icons.storefront_outlined;
      case EnterpriseModule.group:
        return Icons.corporate_fare;
    }
  }

  /// Gets the label for an enterprise type ID.
  String getTypeLabel(String typeId) {
    final type = EnterpriseType.fromId(typeId);
    return type.label;
  }
}
