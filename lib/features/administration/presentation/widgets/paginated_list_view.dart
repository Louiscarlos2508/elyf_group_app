import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic paginated list view with virtual scrolling.
///
/// Uses Drift-level pagination (LIMIT/OFFSET) for efficient loading of large datasets.
/// Automatically loads more items as user scrolls.
class PaginatedListView<T> extends ConsumerStatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    required this.dataLoader,
    this.emptyStateBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.pageSize = 50,
    this.scrollController,
    this.padding,
  });

  /// Builder for each list item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Function to load paginated data
  /// Returns (items, totalCount, hasMore)
  final Future<({List<T> items, int totalCount, bool hasMore})> Function(
    int page,
    int limit,
  )
  dataLoader;

  /// Builder for empty state
  final Widget Function(BuildContext context)? emptyStateBuilder;

  /// Builder for loading indicator
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Number of items per page
  final int pageSize;

  /// Optional scroll controller
  final ScrollController? scrollController;

  /// Padding around the list
  final EdgeInsets? padding;

  @override
  ConsumerState<PaginatedListView<T>> createState() =>
      _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends ConsumerState<PaginatedListView<T>> {
  final ScrollController _internalScrollController = ScrollController();
  ScrollController get _scrollController =>
      widget.scrollController ?? _internalScrollController;

  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _internalScrollController.addListener(_onScroll);
    } else {
      widget.scrollController!.addListener(_onScroll);
    }
    _loadPage(0);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _internalScrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadPage(_currentPage + 1);
    }
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.dataLoader(page, widget.pageSize);
      setState(() {
        if (page == 0) {
          _items = result.items;
        } else {
          _items.addAll(result.items);
        }
        _currentPage = page;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() async {
    setState(() {
      _items = [];
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyStateBuilder?.call(context) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun élément',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            // Loading indicator at bottom
            return widget.loadingBuilder?.call(context) ??
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
