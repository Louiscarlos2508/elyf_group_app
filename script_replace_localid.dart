import 'dart:io';

void main() {
  final dir = Directory('lib/features');
  final files = dir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.contains('/domain/entities/') && f.path.endsWith('.dart'))
      .toList();

  final regex1 = RegExp(r"id:\s*map\['id'\]\s*as\s*String\?\s*\?\?\s*map\['localId'\]\s*as\s*String,\s*");
  final regex2 = RegExp(r"id:\s*map\['id'\]\s*as\s*String,\s*");
  final regex3 = RegExp(r"id:\s*map\['id'\]\s*\?\?\s*'',\s*");
  final regex4 = RegExp(r"id:\s*map\['id'\]\s*as\s*String\?\s*\?\?\s*'',\s*");
  final regex5 = RegExp(r"id:\s*map\['id'\]\s*as\s*String\?\s*\?\?\s*map\['localId'\],\s*");
  final regex6 = RegExp(r"id:\s*map\['id'\]\s*as\s*String\?\s*\?\?\s*map\['localId'\]\s*as\s*String\?\s*\?\?\s*'',\s*");

  final replaceStr = '''id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      ''';

  int modified = 0;
  for (var file in files) {
    if (file.path.contains('/gaz/domain/entities/')) continue; // already manually modified these
    if (file.path.contains('production_session.dart') || file.path.contains('production_day.dart')) {
        // Just let regex handle it if it matches
    }
    
    var content = file.readAsStringSync();
    var originalContent = content;
    
    content = content.replaceAll(regex1, replaceStr);
    content = content.replaceAll(regex2, replaceStr);
    content = content.replaceAll(regex3, replaceStr);
    content = content.replaceAll(regex4, replaceStr);
    content = content.replaceAll(regex5, replaceStr);
    content = content.replaceAll(regex6, replaceStr);
        
    if (originalContent != content) {
      file.writeAsStringSync(content);
      modified++;
      print('Modified: \${file.path}');
    }
  }
  print('Total files modified: \$modified');
}
