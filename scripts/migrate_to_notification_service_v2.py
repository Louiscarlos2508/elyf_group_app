#!/usr/bin/env python3
"""
Script amélioré pour migrer automatiquement les occurrences de ScaffoldMessenger.showSnackBar
vers NotificationService. Gère les patterns multi-lignes et complexes.
"""

import re
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
        modified = False
        
        # Pattern 1: Succès avec backgroundColor: Colors.green (multi-ligne avec DOTALL)
        pattern1 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*Colors\.green[^)]*\),\s*\);'
        def repl1(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showSuccess(context, {m.group(1)});'
        content = re.sub(pattern1, repl1, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 2: Erreur avec backgroundColor: Colors.red
        pattern2 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*Colors\.red[^)]*\),\s*\);'
        def repl2(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showError(context, {m.group(1)});'
        content = re.sub(pattern2, repl2, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 3: Erreur avec 'Erreur: ' + variable
        pattern3 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(\'Erreur:\s*\'[^)]*\+\s*([^)]+)\),\s*backgroundColor:\s*Colors\.red[^)]*\),\s*\);'
        def repl3(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showError(context, {m.group(1)});'
        content = re.sub(pattern3, repl3, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 4: const SnackBar avec backgroundColor: Colors.red
        pattern4 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*Colors\.red[^)]*\),\s*\);'
        def repl4(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showError(context, {m.group(1)});'
        content = re.sub(pattern4, repl4, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 5: SnackBar avec backgroundColor: Theme.of(context).colorScheme.error
        pattern5 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*Theme\.of\(context\)\.colorScheme\.error[^)]*\),\s*\);'
        def repl5(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showError(context, {m.group(1)});'
        content = re.sub(pattern5, repl5, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 6: const SnackBar simple (info)
        pattern6 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*\),\s*\);'
        def repl6(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showInfo(context, {m.group(1)});'
        content = re.sub(pattern6, repl6, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 7: SnackBar simple sans backgroundColor (info)
        pattern7 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*\),\s*\);'
        def repl7(m):
            nonlocal modified
            modified = True
            return f'NotificationService.showInfo(context, {m.group(1)});'
        content = re.sub(pattern7, repl7, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 8: SnackBar avec backgroundColor conditionnel (success ? green : red)
        pattern8 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*([^?]+)\s*\?\s*Colors\.green\s*:\s*Colors\.red[^)]*\),\s*\);'
        def repl8(m):
            nonlocal modified
            modified = True
            content_text = m.group(1)
            condition = m.group(2).strip()
            return f'''if ({condition}) {{
        NotificationService.showSuccess(context, {content_text});
      }} else {{
        NotificationService.showError(context, {content_text});
      }}'''
        content = re.sub(pattern8, repl8, content, flags=re.MULTILINE | re.DOTALL)
        
        # Pattern 9: Patterns multi-lignes complexes avec Text() sur plusieurs lignes
        # On cherche les blocs complets de ScaffoldMessenger...showSnackBar
        pattern9 = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\([^)]*\),\s*backgroundColor:\s*Colors\.(green|red)[^)]*\),\s*\);'
        def repl9(m):
            nonlocal modified
            modified = True
            color = m.group(1)
            if color == 'green':
                # Extraire le texte du Text()
                text_match = re.search(r'Text\(([^)]+)\)', m.group(0))
                if text_match:
                    return f'NotificationService.showSuccess(context, {text_match.group(1)});'
            else:
                text_match = re.search(r'Text\(([^)]+)\)', m.group(0))
                if text_match:
                    return f'NotificationService.showError(context, {text_match.group(1)});'
            return m.group(0)  # Fallback
        content = re.sub(pattern9, repl9, content, flags=re.MULTILINE | re.DOTALL)
        
        # Vérifier si le fichier a été modifié
        if modified and content != original_content:
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

