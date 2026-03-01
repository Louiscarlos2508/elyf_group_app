import 'package:flutter/material.dart';
import '../../../../shared.dart';
import '../../../administration/domain/entities/enterprise.dart';

class OrangeMoneyHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? additionalActions;
  final Widget? bottom;
  final bool showBackButton;

  const OrangeMoneyHeader({
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
      module: EnterpriseModule.mobileMoney,
      actions: actions ?? additionalActions,
      bottom: bottom,
      showBackButton: showBackButton,
    );
  }
}
