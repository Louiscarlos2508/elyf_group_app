import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Un bouton premium avec animations et retour haptique.
///
/// Supporte les variantes: filled, outlined, text.
class ElyfButton extends StatefulWidget {
  const ElyfButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ElyfButtonVariant.filled,
    this.size = ElyfButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ElyfButtonVariant variant;
  final ElyfButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<ElyfButton> createState() => _ElyfButtonState();
}

class _ElyfButtonState extends State<ElyfButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
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
    final bool isDark = theme.brightness == Brightness.dark;

    final double effectiveHeight = widget.height ?? _getHeight();
    final double? effectiveWidth = widget.width;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed != null && !widget.isLoading
          ? () {
              if (_isBusy) return;
              
              setState(() => _isBusy = true);
              widget.onPressed!();
              
              if (mounted) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _isBusy = false);
                  }
                });
              }
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: _buildButtonBody(theme, isDark),
        ),
      ),
    );
  }

  double _getHeight() {
    switch (widget.size) {
      case ElyfButtonSize.small:
        return 36;
      case ElyfButtonSize.medium:
        return 48;
      case ElyfButtonSize.large:
        return 56;
    }
  }

  Widget _buildButtonBody(ThemeData theme, bool isDark) {
    final Color primaryColor = theme.colorScheme.primary;
    final Color onPrimaryColor = theme.colorScheme.onPrimary;

    BoxDecoration decoration;
    Color color;

    switch (widget.variant) {
      case ElyfButtonVariant.filled:
        decoration = BoxDecoration(
          color: widget.onPressed == null ? theme.disabledColor : primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
        color = onPrimaryColor;
        break;
      case ElyfButtonVariant.outlined:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.onPressed == null
                ? theme.disabledColor
                : theme.colorScheme.outline,
            width: 1.5,
          ),
        );
        color = primaryColor;
        break;
      case ElyfButtonVariant.text:
        decoration = const BoxDecoration();
        color = primaryColor;
        break;
    }

    if (widget.backgroundColor != null) {
      if (widget.variant == ElyfButtonVariant.outlined) {
         decoration = decoration.copyWith(
           color: widget.backgroundColor,
           border: Border.all(color: widget.backgroundColor!),
         );
      } else {
         decoration = decoration.copyWith(color: widget.backgroundColor);
      }
    }
    
    if (widget.textColor != null) {
      color = widget.textColor!;
    }

    return Container(
      decoration: decoration,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: widget.isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: color),
                  const SizedBox(width: 8),
                ],
                widget.child,
              ],
            ),
    );
  }
}

enum ElyfButtonVariant { filled, outlined, text }

enum ElyfButtonSize { small, medium, large }
