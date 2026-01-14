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
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                hintText: 'Nom, prénom, username...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 16),
          enterprisesAsync.when(
            data: (enterprises) {
              if (enterprises.isEmpty) {
                return const SizedBox.shrink();
              }
              return Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 180,
                    maxWidth: 250,
                  ),
                  child: DropdownButtonFormField<String?>(
                    initialValue: selectedEnterpriseId,
                    decoration: const InputDecoration(
                      labelText: 'Entreprise',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                  ),
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
