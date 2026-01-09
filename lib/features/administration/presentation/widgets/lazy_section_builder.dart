import 'package:flutter/material.dart';

/// Lazy builder for sections in IndexedStack.
/// 
/// Only builds the widget when the section becomes visible,
/// reducing initial build time and memory usage.
class LazySectionBuilder extends StatefulWidget {
  const LazySectionBuilder({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.builder,
  });

  final int index;
  final int currentIndex;
  final WidgetBuilder builder;

  @override
  State<LazySectionBuilder> createState() => _LazySectionBuilderState();
}

class _LazySectionBuilderState extends State<LazySectionBuilder> {
  Widget? _cachedWidget;
  bool _hasBeenBuilt = false;

  @override
  Widget build(BuildContext context) {
    // Only build if this section is visible or has been built before
    final isVisible = widget.index == widget.currentIndex;
    
    if (isVisible || _hasBeenBuilt) {
      _hasBeenBuilt = true;
      _cachedWidget ??= widget.builder(context);
      return _cachedWidget!;
    }

    // Return empty container for non-visible sections to maintain IndexedStack structure
    return const SizedBox.shrink();
  }
}

