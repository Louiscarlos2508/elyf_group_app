import 'package:flutter/material.dart';

/// Service for enterprise type mappings.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class EnterpriseTypeService {
  EnterpriseTypeService();

  /// Gets the icon for an enterprise type.
  IconData getTypeIcon(String type) {
    switch (type) {
      case 'eau_minerale':
        return Icons.water_drop_outlined;
      case 'gaz':
        return Icons.local_fire_department_outlined;
      case 'orange_money':
        return Icons.account_balance_wallet_outlined;
      case 'immobilier':
        return Icons.home_work_outlined;
      case 'boutique':
        return Icons.storefront_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  /// Gets the label for an enterprise type.
  String getTypeLabel(String type) {
    switch (type) {
      case 'eau_minerale':
        return 'Eau Minérale';
      case 'gaz':
        return 'Gaz';
      case 'orange_money':
        return 'Orange Money';
      case 'immobilier':
        return 'Immobilier';
      case 'boutique':
        return 'Boutique';
      default:
        return type;
    }
  }
}
