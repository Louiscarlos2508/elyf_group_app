import 'package:elyf_groupe_app/core/permissions/entities/user_role.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Résultat de validation
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
  });

  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;

  factory ValidationResult.success({String? warning}) {
    return ValidationResult._(isValid: true, warningMessage: warning);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }

  bool get hasWarning => warningMessage != null;
}

/// Service de validation pour l'assignation de rôles
class RoleAssignmentValidator {
  const RoleAssignmentValidator._();

  /// Valide qu'un rôle peut être assigné à une entreprise donnée
  static ValidationResult validateAssignment({
    required UserRole role,
    required Enterprise enterprise,
  }) {
    // Vérifier si le rôle a des restrictions de type
    if (role.allowedEnterpriseTypes.isEmpty) {
      // Pas de restriction, mais avertir si c'est un rôle générique sur un POS
      if (enterprise.type.isPointOfSale && !role.isSystemRole) {
        return ValidationResult.success(
          warning:
              'Ce rôle générique sera assigné à un point de vente. '
              'Vérifiez que les permissions sont appropriées.',
        );
      }
      return ValidationResult.success();
    }

    // Vérifier si le type d'entreprise est autorisé
    if (!role.canBeAssignedTo(enterprise.type)) {
      final allowedTypes = role.allowedEnterpriseTypes
          .map((t) => t.label)
          .join(', ');

      return ValidationResult.error(
        'Le rôle "${role.name}" ne peut être assigné qu\'à : $allowedTypes.\n'
        'Entreprise sélectionnée : ${enterprise.type.label}',
      );
    }

    return ValidationResult.success();
  }

  /// Obtient des suggestions de rôles pour un type d'entreprise
  static String getSuggestionMessage(EnterpriseType type) {
    switch (type) {
      case EnterpriseType.gasCompany:
        return 'Pour une société Gaz, utilisez "Directeur Régional" ou "Gestionnaire Logistique"';
      case EnterpriseType.gasPointOfSale:
        return 'Pour un point de vente Gaz, utilisez "Gérant POS" ou "Vendeur"';
      case EnterpriseType.waterEntity:
        return 'Pour une entité Eau, utilisez "Directeur Eau Minérale"';
      case EnterpriseType.waterFactory:
        return 'Pour une usine Eau, utilisez "Responsable Production"';
      case EnterpriseType.waterPointOfSale:
        return 'Pour un point de vente Eau, utilisez "Gérant POS Eau" ou "Vendeur Eau"';
      case EnterpriseType.shop:
      case EnterpriseType.shopBranch:
        return 'Pour une boutique, utilisez "Gérant Boutique" ou "Vendeur Boutique"';
      case EnterpriseType.mobileMoneyAgent:
        return 'Pour un agent Mobile Money, utilisez "Agent Principal"';
      case EnterpriseType.mobileMoneySubAgent:
        return 'Pour un sous-agent, utilisez "Sous-Agent"';
      default:
        return 'Sélectionnez un rôle approprié pour ce type d\'entreprise';
    }
  }

  /// Vérifie si les permissions d'un rôle sont cohérentes avec le niveau
  static ValidationResult validateRolePermissions({
    required UserRole role,
    required Set<String> selectedPermissions,
  }) {
    // Permissions typiquement opérationnelles (niveau POS)
    const operationalPermissions = {
      'create_sale',
      'manage_local_stock',
      'create_expense',
    };

    // Permissions typiquement stratégiques (niveau Société)
    const strategicPermissions = {
      'manage_tours',
      'view_all_pos',
      'compare_pos_performance',
      'manage_suppliers',
    };

    // Si le rôle est pour POS uniquement
    if (role.allowedEnterpriseTypes.isNotEmpty &&
        role.allowedEnterpriseTypes.every((t) => t.isPointOfSale)) {
      final hasStrategic = selectedPermissions.any(
        (p) => strategicPermissions.contains(p),
      );

      if (hasStrategic) {
        return ValidationResult.success(
          warning:
              'Ce rôle POS contient des permissions stratégiques. '
              'Vérifiez que c\'est intentionnel.',
        );
      }
    }

    // Si le rôle est pour Société uniquement
    if (role.allowedEnterpriseTypes.isNotEmpty &&
        role.allowedEnterpriseTypes.every((t) => t.isMain)) {
      final hasOperational = selectedPermissions.any(
        (p) => operationalPermissions.contains(p),
      );

      if (hasOperational) {
        return ValidationResult.success(
          warning:
              'Ce rôle Société contient des permissions opérationnelles. '
              'Les directeurs ne gèrent généralement pas les opérations locales.',
        );
      }
    }

    return ValidationResult.success();
  }
}
