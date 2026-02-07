import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart' show enterprisesProvider;

/// Filters bar widget for user section.
///
/// Handles search and enterprise/module filtering.
class UserFiltersBar extends ConsumerWidget {
  const UserFiltersBar({
    super.key,
    required this.searchController,
    this.selectedEnterpriseId,
    this.selectedModuleId,
    this.onEnterpriseChanged,
    this.onModuleChanged,
  });

  final TextEditingController searchController;
  final String? selectedEnterpriseId;
  final String? selectedModuleId;
  final ValueChanged<String?>? onEnterpriseChanged;
  final ValueChanged<String?>? onModuleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          enterprisesAsync.when(
            data: (enterprises) {
              if (enterprises.isEmpty) return const SizedBox.shrink();
              return Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedEnterpriseId,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Entreprise',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes'),
                    ),
                    ...enterprises.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.id,
                        child: Text(e.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    onEnterpriseChanged?.call(value);
                    onModuleChanged?.call(null);
                  },
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
