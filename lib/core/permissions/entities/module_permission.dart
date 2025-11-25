/// Base permission type that can be extended by modules.
abstract class ModulePermission {
  const ModulePermission();
  
  /// Unique identifier for the permission
  String get id;
  
  /// Human-readable name
  String get name;
  
  /// Module this permission belongs to
  String get module;
  
  /// Description of what this permission allows
  String get description;
}

/// Permission for a specific module action.
class ActionPermission extends ModulePermission {
  const ActionPermission({
    required this.id,
    required this.name,
    required this.module,
    required this.description,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String module;
  @override
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPermission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          module == other.module;

  @override
  int get hashCode => id.hashCode ^ module.hashCode;
}

