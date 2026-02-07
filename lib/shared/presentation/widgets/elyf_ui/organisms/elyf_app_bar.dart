import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium AppBar implementation for Elyf Group App.
/// Supports transparent/glassmorphic backgrounds, gradients, and custom action styling.
class ElyfAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ElyfAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.centerTitle = true,
    this.useGlassmorphism = false,
    this.useGradient = false,
    this.elevation = 0,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool centerTitle;
  
  /// If true, applies a blur effect behind the AppBar (requires scaffold extendBodyBehindAppBar: true)
  final bool useGlassmorphism;

  /// If true, uses the primary gradient as background
  final bool useGradient;

  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine background
    Color? bg = backgroundColor ?? theme.colorScheme.surface;
    if (useGlassmorphism) {
      bg = backgroundColor ?? theme.colorScheme.surface; // Solid background
    } else if (useGradient) {
      bg = Colors.transparent; // Handled by Container decoration
    }

    Widget appBar = AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: useGradient ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: useGradient ? Colors.transparent : bg,
      elevation: elevation,
      scrolledUnderElevation: useGlassmorphism ? 0 : 2,
      actions: actions,
      leading: leading,
      bottom: bottom,
      iconTheme: IconThemeData(
        color: useGradient ? Colors.white : theme.colorScheme.onSurface,
      ),
      systemOverlayStyle: useGradient ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    // Apply gradient if requested
    if (useGradient) {
      appBar = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: appBar,
      );
    }

    // Simplified: No more blur as requested by user
    return appBar;
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}


