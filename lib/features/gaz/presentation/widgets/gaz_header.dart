import 'package:flutter/material.dart';
import '../../../../shared.dart';
import '../../../administration/domain/entities/enterprise.dart';

class GazHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color>? gradientColors;
  final Color? shadowColor;
  final List<Widget>? additionalActions;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool asSliver;

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
  });

  @override
  Widget build(BuildContext context) {
    return ElyfModuleHeader(
      title: title,
      subtitle: subtitle,
      module: EnterpriseModule.gaz,
      actions: actions ?? additionalActions,
      bottom: bottom,
      asSliver: asSliver,
    );
  }
}
