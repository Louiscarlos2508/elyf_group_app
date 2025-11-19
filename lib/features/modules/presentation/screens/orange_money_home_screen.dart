import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class OrangeMoneyHomeScreen extends StatelessWidget {
  const OrangeMoneyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHomeScaffold(
      title: 'Orange Money • Agent mobile',
      enterpriseId: 'orange_money',
    );
  }
}
