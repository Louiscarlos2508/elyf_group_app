import 'package:flutter/material.dart';

/// Helper pour gérer les différentes tailles d'écran (mobile, tablette, desktop)
class ResponsiveHelper {
  // Breakpoints standards
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Détermine si l'écran est mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Détermine si l'écran est une tablette (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Détermine si l'écran est desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Détermine si l'écran est large (>= 600px) - inclut tablette et desktop
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  /// Détermine si l'écran est très large (>= 800px) - pour NavigationRail extended
  static bool isExtendedScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }

  /// Retourne la largeur de l'écran
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retourne la hauteur de l'écran
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Retourne le padding adaptatif selon la taille d'écran
  static EdgeInsets adaptivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Retourne le padding horizontal adaptatif
  static EdgeInsets adaptiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  /// Retourne le nombre de colonnes pour une grille selon la taille d'écran
  static int adaptiveGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }
}

