import 'package:flutter/material.dart';
import '../../../../shared.dart';
import '../../../administration/domain/entities/enterprise.dart';

class ImmobilierHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? additionalActions;
  final Widget? bottom;
  final bool showBackButton;

  const ImmobilierHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.additionalActions,
    this.bottom,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElyfModuleHeader(
      title: title,
      subtitle: subtitle,
      module: EnterpriseModule.immobilier,
      actions: actions ?? additionalActions,
      bottom: bottom,
      showBackButton: showBackButton,
    );
  }
}
