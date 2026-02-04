import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'lib/core/offline/drift/app_database.dart';

void main() async {
  final db = AppDatabase(NativeDatabase.memory());
  final count = await db
      .customSelect(
        'SELECT COUNT(*) as c, enterpriseId, moduleType, collectionName FROM offline_records GROUP BY enterpriseId, moduleType, collectionName',
      )
      .get();
  debugPrint(count.map((e) => e.data).toList().toString());
}
