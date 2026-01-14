import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/core/pdf/immobilier_stock_report_pdf_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/property.dart';
import '../../widgets/property_detail_dialog.dart';
import '../../widgets/property_filters.dart';
import '../../widgets/property_form_dialog.dart';
import '../../widgets/property_list_empty_state.dart';
import '../../widgets/property_list_helpers.dart';
import '../../widgets/property_list_sliver.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/property_sort_menu.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  final _searchController = TextEditingController();
  PropertyStatus? _selectedStatus;
  PropertyType? _selectedType;
  PropertySortOption _sortOption = PropertySortOption.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Property> _filterAndSort(List<Property> properties) {
    return PropertyListHelpers.filterAndSort(
      properties: properties,
      searchQuery: _searchController.text,
      selectedStatus: _selectedStatus,
      selectedType: _selectedType,
      sortOption: _sortOption,
    );
  }

  Future<void> _deleteProperty(Property property) async {
    try {
      final controller = ref.read(propertyControllerProvider);
      await controller.deleteProperty(property.id);
      if (mounted) {
        ref.invalidate(propertiesProvider);
        NotificationService.showSuccess(
          context,
          'Propriété supprimée avec succès',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  void _showPropertyDetails(Property property) {
    showDialog(
      context: context,
      builder: (context) => PropertyDetailDialog(
        property: property,
        onEdit: () {
          Navigator.of(context).pop();
          _showPropertyForm(property: property);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _deleteProperty(property);
        },
      ),
    );
  }

  void _showPropertyForm({Property? property}) {
    showDialog(
      context: context,
      builder: (context) => PropertyFormDialog(property: property),
    );
  }

  Future<void> _downloadStockReport(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final controller = ref.read(propertyControllerProvider);
      final properties = await controller.fetchProperties();

      final pdfService = ImmobilierStockReportPdfService();
      final file = await pdfService.generateReport(properties: properties);

      if (context.mounted) {
        Navigator.of(context).pop();
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && context.mounted) {
          NotificationService.showInfo(context, 'PDF généré: ${file.path}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        NotificationService.showError(
          context,
          'Erreur lors de la génération PDF: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      body: propertiesAsync.when(
        data: (properties) {
          final filtered = _filterAndSort(properties);
          final availableCount = properties
              .where((p) => p.status == PropertyStatus.available)
              .length;
          final rentedCount = properties
              .where((p) => p.status == PropertyStatus.rented)
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        isWide ? 24 : 16,
                      ),
                      child: isWide
                          ? Row(
                              children: [
                                Text(
                                  'Propriétés',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                RefreshButton(
                                  onRefresh: () =>
                                      ref.invalidate(propertiesProvider),
                                  tooltip: 'Actualiser',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () =>
                                      _downloadStockReport(context),
                                  tooltip: 'Télécharger rapport PDF',
                                ),
                                PropertySortMenu(
                                  selectedSort: _sortOption,
                                  onSortChanged: (sort) =>
                                      setState(() => _sortOption = sort),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () => _showPropertyForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouvelle Propriété'),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Propriétés',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    RefreshButton(
                                      onRefresh: () =>
                                          ref.invalidate(propertiesProvider),
                                      tooltip: 'Actualiser',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () =>
                                          _downloadStockReport(context),
                                      tooltip: 'Télécharger rapport PDF',
                                    ),
                                    PropertySortMenu(
                                      selectedSort: _sortOption,
                                      onSortChanged: (sort) =>
                                          setState(() => _sortOption = sort),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _showPropertyForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouvelle Propriété'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // KPI Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildKpiCards(
                        theme,
                        properties.length,
                        availableCount,
                        rentedCount,
                      ),
                    ),
                  ),

                  // Search and Filters Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        'LISTE DES PROPRIÉTÉS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: PropertySearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),

                  // Filters
                  SliverToBoxAdapter(
                    child: PropertyFilters(
                      selectedStatus: _selectedStatus,
                      selectedType: _selectedType,
                      onStatusChanged: (status) =>
                          setState(() => _selectedStatus = status),
                      onTypeChanged: (type) =>
                          setState(() => _selectedType = type),
                      onClear: () => setState(() {
                        _selectedStatus = null;
                        _selectedType = null;
                      }),
                    ),
                  ),

                  // Properties List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PropertyListEmptyState(
                        isEmpty: properties.isEmpty,
                        onResetFilters: () {
                          setState(() {
                            _searchController.clear();
                            _selectedStatus = null;
                            _selectedType = null;
                          });
                        },
                      ),
                    )
                  else
                    PropertyListSliver(
                      properties: filtered,
                      onPropertyTap: _showPropertyDetails,
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, error),
      ),
    );
  }

  Widget _buildKpiCards(ThemeData theme, int total, int available, int rented) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total',
            value: '$total',
            icon: Icons.home,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'Disponibles',
            value: '$available',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'Louées',
            value: '$rented',
            icon: Icons.people,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(propertiesProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
