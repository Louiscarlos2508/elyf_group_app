import 'package:drift/drift.dart';
// ignore: deprecated_member_use - WebDatabase still required for web; wasm migration deferred
import 'package:drift/web.dart';

/// Opens a database connection for Web.
/// 
/// Since offline mode is not required for Web, we use WebDatabase
/// which is compliant with Web platforms and uses IndexedDB (or memory).
QueryExecutor openDriftConnection({String filename = 'elyf_offline.sqlite'}) {
  // WebDatabase is the standard way to support Drift on the web without FFI.
  return WebDatabase(filename, logStatements: false);
}
