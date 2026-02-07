import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/enterprise.dart';
import '../../../application/providers.dart';

/// Recursive tree view widget for displaying enterprise hierarchy
class EnterpriseTreeView extends ConsumerStatefulWidget {
  const EnterpriseTreeView({
    super.key,
    this.rootEnterpriseId,
    this.onEnterpriseSelected,
    this.selectedEnterpriseId,
    this.showActions = true,
  });

  /// Root enterprise ID to start the tree from. If null, shows all root enterprises.
  final String? rootEnterpriseId;

  /// Callback when an enterprise is selected
  final ValueChanged<Enterprise>? onEnterpriseSelected;

  /// Currently selected enterprise ID for highlighting
  final String? selectedEnterpriseId;

  /// Whether to show action buttons (edit, delete, etc.)
  final bool showActions;

  @override
  ConsumerState<EnterpriseTreeView> createState() => _EnterpriseTreeViewState();
}

class _EnterpriseTreeViewState extends ConsumerState<EnterpriseTreeView> {
  /// Set of expanded enterprise IDs
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return enterprisesAsync.when(
      data: (enterprises) {
        // Get root enterprises (those to display at top level)
        final List<Enterprise> rootEnterprises;
        
        if (widget.rootEnterpriseId != null) {
          // Start from specific root
          final root = enterprises.firstWhere(
            (e) => e.id == widget.rootEnterpriseId,
            orElse: () => throw Exception('Root enterprise not found'),
          );
          rootEnterprises = [root];
        } else {
          // Show all top-level enterprises (hierarchyLevel == 0)
          rootEnterprises = enterprises
              .where((e) => e.hierarchyLevel == 0)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
        }

        if (rootEnterprises.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          itemCount: rootEnterprises.length,
          itemBuilder: (context, index) {
            return _buildEnterpriseNode(
              context,
              rootEnterprises[index],
              enterprises,
              0,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune entreprise',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseNode(
    BuildContext context,
    Enterprise enterprise,
    List<Enterprise> allEnterprises,
    int depth,
  ) {
    final theme = Theme.of(context);
    final typeService = ref.read(enterpriseTypeServiceProvider);
    final isExpanded = _expandedIds.contains(enterprise.id);
    final isSelected = enterprise.id == widget.selectedEnterpriseId;

    // Get children
    final children = allEnterprises
        .where((e) => e.parentEnterpriseId == enterprise.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enterprise node
        InkWell(
          onTap: () => widget.onEnterpriseSelected?.call(enterprise),
          child: Container(
            margin: EdgeInsets.only(left: depth * 24.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : (enterprise.type.isMain ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : null),
              border: Border(
                left: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (enterprise.type.isMain ? theme.colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent),
                  width: isSelected ? 4 : (enterprise.type.isMain ? 3 : 0),
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Expand/collapse button
                  if (hasChildren)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIds.remove(enterprise.id);
                          } else {
                            _expandedIds.add(enterprise.id);
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    )
                  else
                    const SizedBox(width: 32),
                  
                  // Enterprise icon
                  Icon(
                    typeService.getTypeIcon(enterprise.type.id),
                    size: 20,
                    color: enterprise.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              title: Text(
                enterprise.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: (isSelected || enterprise.type.isMain) ? FontWeight.bold : FontWeight.normal,
                  color: enterprise.isActive
                      ? (enterprise.type.isMain ? theme.colorScheme.primary : null)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: enterprise.type.isMain ? 15 : 14,
                ),
              ),
              subtitle: Text(
                typeService.getTypeLabel(enterprise.type.id),
                style: theme.textTheme.bodySmall,
              ),
              trailing: widget.showActions
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: enterprise.isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Children count badge
                        if (hasChildren)
                          Chip(
                            label: Text(
                              '${children.length}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    )
                  : null,
            ),
          ),
        ),

        // Render children recursively if expanded
        if (hasChildren && isExpanded)
          ...children.map((child) => _buildEnterpriseNode(
                context,
                child,
                allEnterprises,
                depth + 1,
              )),
      ],
    );
  }
}
