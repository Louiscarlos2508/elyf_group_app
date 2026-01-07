#!/usr/bin/env python3
"""
Script final pour migrer automatiquement les occurrences de ScaffoldMessenger.showSnackBar
vers NotificationService. Approche plus agressive pour gérer tous les cas.
"""

import re
from pathlib import Path

def calculate_import_path(file_path, project_root):
    """Calcule le chemin d'import relatif vers shared.dart."""
    file_path_obj = Path(file_path)
    relative_path = file_path_obj.relative_to(project_root / 'lib')
    depth = len(relative_path.parent.parts)
    return '../' * depth + 'shared.dart' if depth > 0 else 'shared.dart'

def extract_text_content(snackbar_block):
    """Extrait le contenu du Text() d'un bloc SnackBar."""
    # Chercher Text(...)
    text_match = re.search(r'Text\s*\(\s*([^)]+(?:\([^)]*\)[^)]*)*)\s*\)', snackbar_block, re.DOTALL)
    if text_match:
        text_content = text_match.group(1).strip()
        # Nettoyer les sauts de ligne et espaces multiples
        text_content = re.sub(r'\s+', ' ', text_content)
        return text_content
    return None

def determine_notification_type(snackbar_block):
    """Détermine le type de notification basé sur le bloc SnackBar."""
    block_lower = snackbar_block.lower()
    
    # Erreur
    if 'colors.red' in block_lower or 'colorScheme.error' in block_lower or "'erreur:" in block_lower or '"erreur:' in block_lower:
        return 'error'
    # Succès
    if 'colors.green' in block_lower:
        return 'success'
    # Info par défaut
    return 'info'

def migrate_snackbar_block(match):
    """Migre un bloc ScaffoldMessenger.showSnackBar complet."""
    full_block = match.group(0)
    text_content = extract_text_content(full_block)
    
    if not text_content:
        return full_block  # Ne pas modifier si on ne peut pas extraire le texte
    
    notification_type = determine_notification_type(full_block)
    
    # Nettoyer le texte (enlever 'Erreur: ' si présent)
    if notification_type == 'error' and ("'erreur:" in text_content.lower() or '"erreur:' in text_content.lower()):
        text_content = re.sub(r'[\'"]\s*erreur\s*:\s*[\'"]\s*\+\s*', '', text_content, flags=re.IGNORECASE)
        text_content = re.sub(r'[\'"]\s*Erreur\s*:\s*[\'"]\s*\+\s*', '', text_content)
    
    # Nettoyer .replaceAll('Exception: ', '') si présent
    text_content = re.sub(r'\.replaceAll\s*\(\s*[\'"]Exception:\s*[\'"]\s*,\s*[\'"]\s*[\'"]\s*\)', '', text_content)
    
    # Construire l'appel NotificationService
    method_name = f'show{notification_type.capitalize()}'
    return f'NotificationService.{method_name}(context, {text_content});'

def migrate_file(file_path, project_root):
    """Migre un fichier vers NotificationService."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Pattern très large pour capturer tout le bloc ScaffoldMessenger.showSnackBar
        # Cherche depuis ScaffoldMessenger jusqu'à la fin du SnackBar
        pattern = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\s*\(\s*SnackBar\s*\([^)]*(?:\([^)]*\)[^)]*)*\)\s*\);'
        
        # Remplacer tous les blocs trouvés
        new_content = re.sub(pattern, migrate_snackbar_block, content, flags=re.MULTILINE | re.DOTALL)
        
        # Si le contenu a changé
        if new_content != original_content:
            # Ajouter l'import si nécessaire
            if 'shared.dart' not in new_content:
                lines = new_content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.strip().startswith('import '):
                        last_import_idx = i
                
                if last_import_idx >= 0:
                    import_path = calculate_import_path(file_path, project_root)
                    import_line = f"import '{import_path}';"
                    if import_line not in new_content:
                        lines.insert(last_import_idx + 1, import_line)
                        new_content = '\n'.join(lines)
            
            # Écrire le fichier
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            return True
    
    except Exception as e:
        print(f"Erreur: {file_path}: {e}")
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
            error_msg = f"✗ Erreur: {dart_file.relative_to(project_root)}: {e}"
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

