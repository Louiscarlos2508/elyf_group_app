import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class OrangeMoneyHomeScreen extends StatelessWidget {
  const OrangeMoneyHomeScreen({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  Widget build(BuildContext context) {
    return ModuleHomeScaffold(
      title: 'Orange Money • Agent mobile',
      enterpriseId: enterpriseId,
    );
  }
}
