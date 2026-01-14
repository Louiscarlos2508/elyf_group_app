import 'package:flutter/material.dart';

/// Wrapper widget that keeps its child alive when scrolled out of view.
///
/// Useful for caching critical data and maintaining state in scrollable lists.
/// Prevents expensive rebuilds when navigating back to the widget.
class KeepAliveWrapper extends StatefulWidget {
  const KeepAliveWrapper({
    super.key,
    required this.child,
    this.keepAlive = true,
  });

  final Widget child;
  final bool keepAlive;

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return widget.child;
  }
}

/// Extension to easily wrap widgets with keepAlive.
extension KeepAliveExtension on Widget {
  /// Wraps this widget with KeepAliveWrapper to maintain state.
  Widget withKeepAlive({bool keepAlive = true}) {
    return KeepAliveWrapper(keepAlive: keepAlive, child: this);
  }
}
