#!/usr/bin/env python3
"""
Script pour migrer automatiquement les occurrences de ScaffoldMessenger.showSnackBar
vers NotificationService.

Usage: python3 scripts/migrate_to_notification_service.py
"""

import re
import os
from pathlib import Path

def calculate_import_path(file_path, project_root):
    """Calcule le chemin d'import relatif vers shared.dart."""
    file_path_obj = Path(file_path)
    relative_path = file_path_obj.relative_to(project_root / 'lib')
    
    # Compter la profondeur depuis lib/
    depth = len(relative_path.parent.parts)
    if depth == 0:
        return 'shared.dart'
    else:
        return '../' * depth + 'shared.dart'

def migrate_file(file_path, project_root):
    """Migre un fichier vers NotificationService."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Pattern 1: Succès avec backgroundColor: Colors.green (multi-ligne)
        pattern1 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: Colors\.green,\s*\),\s*\);'
        replacement1 = r'NotificationService.showSuccess(context, \1);'
        content = re.sub(pattern1, replacement1, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 2: Erreur avec backgroundColor: Colors.red (multi-ligne)
        pattern2 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: Colors\.red,\s*\),\s*\);'
        replacement2 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern2, replacement2, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 3: Erreur avec 'Erreur: ' prefix et backgroundColor: Colors.red
        pattern3 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(\'Erreur: \'\s*\+\s*([^)]+)\),\s*backgroundColor: Colors\.red,\s*\),\s*\);'
        replacement3 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern3, replacement3, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 4: Erreur avec replaceAll('Exception: ', '')
        pattern4 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(\'Erreur: \'\s*\+\s*([^)]+\.replaceAll\(\'Exception: \', \'\'\))\),\s*backgroundColor: Colors\.red,\s*\),\s*\);'
        replacement4 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern4, replacement4, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 5: const SnackBar avec backgroundColor: Colors.red
        pattern5 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: Colors\.red,\s*\),\s*\);'
        replacement5 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern5, replacement5, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 6: SnackBar avec backgroundColor: Colors.red (sans const)
        pattern6 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: Colors\.red,\s*\),\s*\);'
        replacement6 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern6, replacement6, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 7: SnackBar avec backgroundColor: Theme.of(context).colorScheme.error
        pattern7 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: Theme\.of\(context\)\.colorScheme\.error,\s*\),\s*\);'
        replacement7 = r'NotificationService.showError(context, \1);'
        content = re.sub(pattern7, replacement7, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 8: const SnackBar simple (sans backgroundColor) - généralement info
        pattern8 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content: Text\(([^)]+)\),\s*\),\s*\);'
        replacement8 = r'NotificationService.showInfo(context, \1);'
        content = re.sub(pattern8, replacement8, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 9: SnackBar simple (sans backgroundColor) - généralement info
        pattern9 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*\),\s*\);'
        replacement9 = r'NotificationService.showInfo(context, \1);'
        content = re.sub(pattern9, replacement9, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 10: SnackBar avec backgroundColor conditionnel (success ? green : red)
        pattern10 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(([^)]+)\),\s*backgroundColor: ([^)]+)\s*\?\s*Colors\.green\s*:\s*Colors\.red,\s*\),\s*\);'
        def replacement10_func(match):
            content_text = match.group(1)
            condition = match.group(2)
            return f'if ({condition}) {{\n        NotificationService.showSuccess(context, {content_text});\n      }} else {{\n        NotificationService.showError(context, {content_text});\n      }}'
        content = re.sub(pattern10, replacement10_func, content, flags=re.MULTILINE | re.DOTALL)
        
        # Vérifier si le fichier a été modifié
        if content != original_content:
            # Vérifier si shared.dart est importé
            if 'shared.dart' not in content:
                # Trouver la dernière ligne d'import
                lines = content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.strip().startswith('import '):
                        last_import_idx = i
                
                if last_import_idx >= 0:
                    # Calculer le chemin d'import
                    import_path = calculate_import_path(file_path, project_root)
                    # Vérifier si l'import n'existe pas déjà
                    import_line = f"import '{import_path}';"
                    if import_line not in content:
                        lines.insert(last_import_idx + 1, import_line)
                        content = '\n'.join(lines)
            
            # Écrire le fichier modifié
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True
    
    except Exception as e:
        print(f"Erreur lors de la migration de {file_path}: {e}")
        return False
    
    return False

def main():
    """Fonction principale."""
    # Trouver tous les fichiers Dart dans lib/features
    project_root = Path(__file__).parent.parent
    features_dir = project_root / 'lib' / 'features'
    
    dart_files = list(features_dir.rglob('*.dart'))
    
    migrated_count = 0
    total_with_snackbar = 0
    errors = []
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'ScaffoldMessenger.of(context).showSnackBar' in content:
                total_with_snackbar += 1
                if migrate_file(str(dart_file), project_root):
                    migrated_count += 1
                    print(f"✓ Migré: {dart_file.relative_to(project_root)}")
        except Exception as e:
            error_msg = f"✗ Erreur avec {dart_file.relative_to(project_root)}: {e}"
            errors.append(error_msg)
            print(error_msg)
    
    print(f"\n{'='*60}")
    print(f"Résumé:")
    print(f"  Fichiers avec ScaffoldMessenger: {total_with_snackbar}")
    print(f"  Fichiers migrés: {migrated_count}")
    print(f"  Fichiers restants: {total_with_snackbar - migrated_count}")
    if errors:
        print(f"  Erreurs: {len(errors)}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
