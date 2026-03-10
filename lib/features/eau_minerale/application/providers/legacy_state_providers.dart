import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/repository_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_period.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product_sales_summary.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/adapters/expense_balance_adapter.dart';
import 'package:elyf_groupe_app/core/domain/entities/expense_balance_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/sales_controller.dart' show SalesState;
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/finances_controller.dart' show FinancesState;

// Providers moved to dashboard_state_providers.dart or other specialized files
// but kept commented or removed if redundant.
// Removed: allMachinesProvider, activityStateProvider, salesStateProvider, financesStateProvider, eauMineraleExpenseBalanceProvider

// Removed duplicate: allDailyWorkersProvider

// Moved to specific providers

final clientsStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(clientsControllerProvider).fetchCustomers(),
);

// Moved

// Moved

// Moved to production_state_providers.dart

// Moved to specific providers

// Moved to production_state_providers.dart

// All providers either moved or redundant. 
// This file can eventually be deleted after ensuring no other module relies on it directly.
