import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/admin_module.dart';
import '../admin_modules_section.dart';
import 'widgets/module_details_header.dart';
import 'widgets/module_details_content.dart';

/// Dialogue pour afficher les détails d'un module
class ModuleDetailsDialog extends ConsumerWidget {
  const ModuleDetailsDialog({super.key, required this.module});

  final AdminModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(moduleStatsProvider(module.id));
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);
    final usersAsync = ref.watch(usersProvider);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModuleDetailsHeader(
              module: module,
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: statsAsync.when(
                data: (stats) => enterpriseModuleUsersAsync.when(
                  data: (assignments) => usersAsync.when(
                    data: (users) => enterprisesAsync.when(
                      data: (enterprises) => ModuleDetailsContent(
                        module: module,
                        stats: stats,
                        assignments: assignments
                            .where((a) => a.moduleId == module.id)
                            .toList(),
                        users: users,
                        enterprises: enterprises,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Erreur: $error')),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Erreur: $error')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('Erreur: $error')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Erreur: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
