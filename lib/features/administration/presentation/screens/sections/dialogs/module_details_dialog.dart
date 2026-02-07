import 'dart:ui';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final statsAsync = ref.watch(moduleStatsProvider(module.id));
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);
    final usersAsync = ref.watch(usersProvider);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey[900] : Colors.white)!.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
        ),
      ),
    );
  }
}
