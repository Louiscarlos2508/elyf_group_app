import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/admin_module.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/module_sections_info.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import '../../admin_modules_section.dart' show ModuleStats;
import 'module_sections_tab.dart';
import 'module_users_tab.dart';
import 'module_enterprises_tab.dart';

/// Content widget for module details with tabs
class ModuleDetailsContent extends StatelessWidget {
  const ModuleDetailsContent({
    super.key,
    required this.module,
    required this.stats,
    required this.assignments,
    required this.users,
    required this.enterprises,
  });

  final AdminModule module;
  final ModuleStats stats;
  final List<EnterpriseModuleUser> assignments;
  final List<dynamic> users;
  final List<dynamic> enterprises;

  @override
  Widget build(BuildContext context) {
    final sections = ModuleSectionsRegistry.getSectionsForModule(module.id);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Sections', icon: Icon(Icons.apps_outlined)),
              const Tab(text: 'Utilisateurs', icon: Icon(Icons.people_outline)),
              const Tab(
                text: 'Entreprises',
                icon: Icon(Icons.business_outlined),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ModuleSectionsTab(sections: sections),
                ModuleUsersTab(
                  assignments: assignments,
                  users: users,
                  enterprises: enterprises,
                ),
                ModuleEnterprisesTab(enterprises: stats.enterprises),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
