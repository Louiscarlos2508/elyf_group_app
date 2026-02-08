import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium icon button with animations and haptic feedback.
///
/// Supports glass, filled, and transparent variants.
class ElyfIconButton extends StatefulWidget {
  const ElyfIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
    this.useGlassEffect = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool useGlassEffect;

  @override
  State<ElyfIconButton> createState() => _ElyfIconButtonState();
}

class _ElyfIconButtonState extends State<ElyfIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        if (_isBusy || widget.onPressed == null) return;
        
        setState(() => _isBusy = true);
        widget.onPressed!();
        
        // Reset busy state after delay to allow next tap if needed,
        // but prevents immediate double-tap
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _isBusy = false);
            }
          });
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                (widget.useGlassEffect
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
