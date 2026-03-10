/// Barrel file exporting all providers for the Gaz module.
/// 
/// This file has been refactored from a single 1600+ line file into specialized 
/// files in the providers/ directory for better maintainability.

export 'providers/repository_providers.dart';
export 'providers/service_providers.dart';
export 'providers/controller_providers.dart';
export 'providers/data_providers.dart';
export 'providers/dashboard_providers.dart';
export 'providers/ui_providers.dart';
export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';

// Backward compatibility for common entities/types if needed
export '../domain/entities/gaz_treasury_synthesis.dart';
 export 'providers/dashboard_providers.dart' show GazDashboardViewType;
