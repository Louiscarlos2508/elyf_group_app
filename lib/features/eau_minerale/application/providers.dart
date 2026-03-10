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
export 'controllers/salary_controller.dart' show SalaryState;
export 'providers/stock_state_providers.dart';
export 'providers/dashboard_state_providers.dart';
export 'providers/production_state_providers.dart';
export 'providers/credit_state_providers.dart';
export 'providers/treasury_state_providers.dart';
export 'providers/navigation_state_providers.dart';
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
export '../domain/entities/production_session.dart';
export '../domain/entities/production_session_status.dart';
export '../domain/entities/production_event.dart';
export '../domain/entities/production_day.dart';
export '../domain/entities/employee.dart';
export '../domain/entities/salary_payment.dart';
export '../domain/entities/production_payment.dart';
export '../domain/repositories/customer_repository.dart' show CustomerSummary;
export '../domain/entities/customer_credit.dart';
export '../domain/entities/sale.dart';
export '../domain/entities/machine.dart';

// Re-export StockMovementFiltersParams from state_providers
export 'providers/state_providers.dart' show StockMovementFiltersParams;
