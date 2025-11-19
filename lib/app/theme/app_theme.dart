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
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    return _buildTheme(scheme, status);
  }

  static ThemeData dark(AppBootStatus status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return _buildTheme(scheme, status);
  }

  static ThemeData _buildTheme(ColorScheme colors, AppBootStatus status) {
    final textTheme = buildAppTextTheme(colors);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      textTheme: textTheme,
      cardTheme: buildCardTheme(colors),
      filledButtonTheme: buildFilledButtonTheme(colors),
      outlinedButtonTheme: buildOutlinedButtonTheme(colors),
      textButtonTheme: buildTextButtonTheme(colors),
      inputDecorationTheme: buildInputTheme(colors),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelLarge!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
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
