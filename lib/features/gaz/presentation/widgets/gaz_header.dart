import 'package:flutter/material.dart';
import '../../../../shared.dart';
import '../../../administration/domain/entities/enterprise.dart';
import 'gaz_view_type_toggle.dart';

class GazHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color>? gradientColors;
  final Color? shadowColor;
  final List<Widget>? additionalActions;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool asSliver;
  final bool showViewToggle;

  const GazHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientColors,
    this.shadowColor,
    this.additionalActions,
    this.actions,
    this.bottom,
    this.asSliver = true,
    this.showViewToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElyfModuleHeader(
      title: title,
      subtitle: subtitle,
      module: EnterpriseModule.gaz,
      actions: [
        if (showViewToggle) const GazViewTypeToggle(),
        ...?actions ?? additionalActions,
      ],
      bottom: bottom,
      asSliver: asSliver,
    );
  }
}
