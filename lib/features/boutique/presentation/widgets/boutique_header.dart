import 'package:flutter/material.dart';
import '../../../../shared.dart';
import '../../../administration/domain/entities/enterprise.dart';

class BoutiqueHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? additionalActions;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBackButton;
  final List<Color>? gradientColors;
  final Color? shadowColor;

  const BoutiqueHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.additionalActions,
    this.actions,
    this.bottom,
    this.showBackButton = false,
    this.gradientColors,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElyfModuleHeader(
      title: title,
      subtitle: subtitle,
      module: EnterpriseModule.boutique,
      actions: actions ?? additionalActions,
      bottom: bottom,
      showBackButton: showBackButton,
    );
  }
}
