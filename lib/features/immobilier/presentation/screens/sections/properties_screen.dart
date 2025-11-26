import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propriété supprimée avec succès'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propriétés'),
        actions: [
          PropertySortMenu(
            selectedSort: _sortOption,
            onSortChanged: (sort) {
              setState(() {
                _sortOption = sort;
              });
            },
          ),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          final filtered = _filterAndSort(properties);
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(propertiesProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IntrinsicWidth(
                        child: FilledButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const PropertyFormDialog(),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle Propriété'),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PropertySearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PropertyFilters(
                    selectedStatus: _selectedStatus,
                    selectedType: _selectedType,
                    onStatusChanged: (status) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    onTypeChanged: (type) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedType = null;
                      });
                    },
                  ),
                ),
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
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur: $error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(propertiesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
