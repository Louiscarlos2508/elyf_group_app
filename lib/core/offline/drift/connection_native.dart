import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens a SQLite connection for Drift on native platforms (Mobile/Desktop).
QueryExecutor openDriftConnection({String filename = 'elyf_offline.sqlite'}) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    return NativeDatabase.createInBackground(file);
  });
}
