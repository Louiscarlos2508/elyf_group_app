# Formulaires avec champs dynamiques / listes infinies

Ce document liste tous les formulaires qui utilisent des champs dynamiques (listes qui peuvent être ajoutées/supprimées) ou des listes infinies.

## 📋 Formulaires avec champs dynamiques

### 1. **Production Session Form** (`production_session_form.dart`)
**Fichier :** `lib/features/eau_minerale/presentation/widgets/production_session_form.dart`

**Champs dynamiques :**
- **Bobines utilisées** (`BobineUsageFormField`)
  - Liste de bobines qui peut être ajoutée/supprimée indéfiniment
  - Utilise `...bobinesUtilisees.asMap().entries.map()` pour créer les éléments
  - Bouton "Ajouter bobine" pour ajouter une nouvelle bobine
  - Bouton "Supprimer" sur chaque bobine pour la retirer

**Code pertinent :**
```dart
BobineUsageFormField(
  bobinesUtilisees: _bobinesUtilisees,
  machinesDisponibles: _machinesSelectionnees,
  onBobinesChanged: (bobines) {
    setState(() => _bobinesUtilisees = bobines);
  },
)
```

---

### 2. **Bobine Usage Form Field** (`bobine_usage_form_field.dart`)
**Fichier :** `lib/features/eau_minerale/presentation/widgets/bobine_usage_form_field.dart`

**Type :** Widget de champ de formulaire avec liste dynamique

**Fonctionnalités :**
- Liste de bobines utilisées qui peut être étendue indéfiniment
- Utilise `...bobinesUtilisees.asMap().entries.map()` pour créer les cartes
- Chaque élément a un bouton de suppression
- Bouton "+" pour ajouter une nouvelle bobine (ouvre un dialogue)

**Code pertinent :**
```dart
...bobinesUtilisees.asMap().entries.map((entry) {
  final index = entry.key;
  final bobine = entry.value;
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(bobine.bobineType),
      subtitle: Text('Machine: ${bobine.machineName}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          final nouvellesBobines = List<BobineUsage>.from(bobinesUtilisees);
          nouvellesBobines.removeAt(index);
          onBobinesChanged(nouvellesBobines);
        },
      ),
    ),
  );
}),
```

---

### 3. **Production Payment Persons Section** (`production_payment_persons_section.dart`)
**Fichier :** `lib/features/eau_minerale/presentation/widgets/production_payment_persons_section.dart`

**Type :** Section de formulaire avec liste dynamique de personnes

**Fonctionnalités :**
- Liste de personnes (`ProductionPaymentPerson`) qui peut être ajoutée/supprimée
- Chaque personne a des champs (nom, nombre de jours, taux, etc.)
- Bouton pour ajouter une nouvelle personne
- Bouton pour supprimer une personne
- Possibilité de charger les personnes depuis les sessions de production

**Champs par personne :**
- Nom
- Nombre de jours
- Taux/jour
- Montant total (calculé)

---

### 4. **File Attachment Field** (`file_attachment_field.dart`)
**Fichier :** `lib/shared/presentation/widgets/file_attachment_field.dart`

**Type :** Widget partagé pour gérer les fichiers joints

**Fonctionnalités :**
- Liste de fichiers qui peut être ajoutée (jusqu'à `maxFiles`, par défaut 10)
- Utilise `Wrap` avec `attachedFiles.asMap().entries.map()` pour créer les éléments
- Bouton pour ajouter un fichier (jusqu'à la limite)
- Bouton pour supprimer chaque fichier

**Limite :** Maximum 10 fichiers (configurable via `maxFiles`)

**Code pertinent :**
```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: attachedFiles.asMap().entries.map((entry) {
    final index = entry.key;
    final file = entry.value;
    return AttachedFileItem(
      file: file,
      onDelete: () {
        final newFiles = List<AttachedFile>.from(attachedFiles);
        newFiles.removeAt(index);
        onFilesChanged(newFiles);
      },
    );
  }).toList(),
),
```

---

## 🔍 Formulaires avec ListView.builder (listes potentiellement longues)

### 5. **Module Details Dialog** (`module_details_dialog.dart`)
**Fichier :** `lib/features/administration/presentation/screens/sections/dialogs/module_details_dialog.dart`

**Onglets avec ListView.builder :**
- **Onglet Sections** : Liste des sections développées
- **Onglet Utilisateurs** : Liste des utilisateurs assignés
- **Onglet Entreprises** : Liste des entreprises

**Code pertinent :**
```dart
ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: sections.length,
  itemBuilder: (context, index) {
    // ...
  },
)
```

---

### 6. **Sale Product Selector** (`sale_product_selector.dart`)
**Fichier :** `lib/features/eau_minerale/presentation/widgets/sale_product_selector.dart`

**Type :** Dialogue de sélection avec liste de produits

**Fonctionnalités :**
- Liste de produits avec ListView (potentiellement longue)
- Filtrage par stock disponible
- Recherche possible

---

## ⚠️ Points d'attention

### Performance
1. **`.map().toList()` vs `ListView.builder`**
   - Les formulaires utilisant `.map().toList()` créent tous les widgets en mémoire
   - Pour les listes longues (>50 éléments), préférer `ListView.builder`
   - Les listes actuelles sont généralement courtes (<20 éléments)

2. **État des formulaires**
   - Les listes dynamiques utilisent `setState()` pour mettre à jour l'état
   - Cela reconstruit tous les widgets enfants
   - Pour de très longues listes, considérer l'utilisation d'un `ListController` ou d'un `ValueNotifier`

### Bonnes pratiques observées
✅ **BobineUsageFormField** : Utilise `List.from()` pour créer une copie avant modification  
✅ **FileAttachmentField** : Limite le nombre d'éléments (maxFiles)  
✅ **ProductionPaymentPersonsSection** : Permet de charger depuis les données existantes  

### Améliorations possibles
1. **Limiter le nombre d'éléments** : Ajouter une limite max pour les listes dynamiques très longues
2. **Utiliser ListView.builder** : Pour les listes qui pourraient dépasser 20-30 éléments
3. **Pagination** : Pour les listes très longues dans les dialogues
4. **Validation** : S'assurer que les listes ne sont pas vides avant la soumission

---

## 📊 Résumé

| Formulaire | Type | Limite | Performance | Statut |
|------------|------|--------|-------------|--------|
| BobineUsageFormField | ListView.builder | 20 bobines | ✅ Bon | ✅ Amélioré |
| ProductionPaymentPersonsSection | ListView.builder | Aucune (limite via UI) | ✅ Bon | ✅ Amélioré |
| FileAttachmentField | Wrap + .map() | 10 fichiers (configurable) | ✅ Bon (limité) | ✅ OK |
| Module Details Dialog | ListView.builder | N/A | ✅ Bon | ✅ OK |
| Sale Product Selector | ListView | N/A | ✅ Bon | ✅ OK |

---

## ✅ Améliorations Appliquées

### 1. **BobineUsageFormField**
- ✅ Converti de `.map()` vers `ListView.builder` pour meilleure performance
- ✅ Ajout d'une limite de 20 bobines maximum
- ✅ Ajout d'un compteur visuel (nombre de bobines)
- ✅ Contrainte de hauteur max (300px) avec scroll si nécessaire
- ✅ Message d'erreur si limite atteinte
- ✅ Dialogue responsive avec largeur adaptative (90% écran, min 400px, max 600px)

### 2. **ProductionPaymentPersonsSection**
- ✅ Converti de `List.generate()` vers `ListView.builder` pour meilleure performance
- ✅ Contrainte de hauteur max (500px) avec scroll si nécessaire
- ✅ Ajout d'un compteur visuel (nombre de personnes)
- ✅ Meilleure gestion de l'espace pour les listes longues

### 3. **FormDialog (base)**
- ✅ Largeur responsive : 90% de l'écran, min 320px, max 600px
- ✅ Padding horizontal adaptatif selon la largeur d'écran
- ✅ Gestion améliorée des petits écrans (< 600px)

---

## 🎯 Recommandations Futures

1. ✅ **Ajouter des limites** - FAIT pour BobineUsageFormField
2. ✅ **Convertir en ListView.builder** - FAIT pour les deux principaux formulaires
3. ✅ **Ajouter des indicateurs visuels** - FAIT (compteurs ajoutés)
4. ⚠️ **Valider les listes** - À faire : validation avant soumission (ex: au moins 1 élément requis)
5. ⚠️ **Contraintes de largeur** - FAIT pour FormDialog, à vérifier pour autres dialogues

