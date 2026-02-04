import 'package:flutter/material.dart';

import '../../shared/providers/app_boot_status_provider.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'component_themes/button_theme.dart';
import 'component_themes/card_theme.dart';
import 'component_themes/input_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(AppBootStatus status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.bgLight,
      onSurface: AppColors.textDisplayLight,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      outline: AppColors.borderLight,
    );
    return _buildTheme(scheme, status);
  }

  static ThemeData dark(AppBootStatus status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.bgDark,
      onSurface: AppColors.textDisplayDark,
      primary: AppColors.primaryLight,
      secondary: AppColors.accentLight,
      outline: AppColors.borderDark,
    );
    return _buildTheme(scheme, status);
  }

  static ThemeData _buildTheme(ColorScheme colors, AppBootStatus status) {
    final textTheme = buildAppTextTheme(colors);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      cardTheme: buildCardTheme(colors),
      filledButtonTheme: buildFilledButtonTheme(colors),
      outlinedButtonTheme: buildOutlinedButtonTheme(colors),
      textButtonTheme: buildTextButtonTheme(colors),
      inputDecorationTheme: buildInputTheme(colors).copyWith(
        filled: true,
        fillColor: colors.brightness == Brightness.light
            ? colors.surfaceContainerLowest
            : colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline.withValues(alpha: 0.5),
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelLarge!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );

    return base.copyWith(
      extensions: [
        StatusColors(
          success: AppColors.success,
          danger: status == AppBootStatus.initializing
              ? AppColors.accent
              : AppColors.danger,
        ),
      ],
    );
  }
}

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.danger});

  final Color success;
  final Color danger;

  @override
  StatusColors copyWith({Color? success, Color? danger}) {
    return StatusColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}
