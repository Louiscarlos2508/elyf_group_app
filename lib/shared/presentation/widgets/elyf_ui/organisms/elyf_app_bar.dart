import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// A premium AppBar implementation for Elyf Group App.
/// Supports transparent/glassmorphic backgrounds, gradients, and custom action styling.
class ElyfAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ElyfAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.module,
    this.moduleId,
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
  final String? subtitle;
  final EnterpriseModule? module;
  final String? moduleId;
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
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine background
    final Color bg = backgroundColor ?? theme.colorScheme.surface;
    
    // In this premium version, the AppBar uses the surface color to stay clean
    // but we can force a gradient if useGradient is true.
    final bool applyGradient = useGradient;

    final textColor = applyGradient 
        ? Colors.white 
        : theme.colorScheme.onSurface;

    Widget appBar = AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
      centerTitle: centerTitle,
      backgroundColor: applyGradient ? Colors.transparent : bg,
      elevation: elevation,
      scrolledUnderElevation: useGlassmorphism ? 0 : 2,
      actions: actions,
      leading: leading,
      bottom: bottom,
      iconTheme: IconThemeData(
        color: textColor,
      ),
      systemOverlayStyle: applyGradient || isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    // Apply gradient ONLY if explicitly requested
    if (applyGradient) {
      appBar = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.mainGradient,
          ),
        ),
        child: appBar,
      );
    }

    return appBar;
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}


