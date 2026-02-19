/// Barrel file for all providers in the eau_minerale module.
///
/// This file exports all providers organized by category:
/// - Repository providers
/// - Service providers
/// - Controller providers
/// - State providers (FutureProvider, etc.)
/// - Permission providers
library;

export 'providers/controller_providers.dart';
export 'controllers/stock_controller.dart' show StockState;
export 'controllers/finances_controller.dart' show FinancesState;
export 'controllers/sales_controller.dart' show SalesState;
export 'providers/permission_providers.dart';
export 'providers/repository_providers.dart';
export 'providers/service_providers.dart';
export 'providers/state_providers.dart';

// Re-export entity types used by providers
export '../domain/entities/electricity_meter_type.dart';
export '../domain/entities/expense_record.dart';
export '../domain/entities/closing.dart';
export '../../../core/errors/app_exceptions.dart';
export '../domain/entities/eau_minerale_section.dart';
export '../domain/entities/stock_movement.dart';

// Re-export StockMovementFiltersParams from state_providers
export 'providers/state_providers.dart' show StockMovementFiltersParams;
