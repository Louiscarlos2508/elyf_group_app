# Plan de Travail Révisé - Issue #1 : Module Production selon Spécifications Finales

## 📋 Vue d'ensemble

**Issue GitHub :** #1 - Terminer et corriger du module de gestion eau minerale

**Spécifications :** Document "MODULE DE PRODUCTION – SPÉCIFICATIONS FINALES"

**Date de création :** 10 décembre 2025

---

## 🎯 Concept Central : Production = Phase Continue

Une production est une **phase de travail continue** qui :
- Commence au clic sur "Lancer une production"
- Se termine **uniquement** quand toutes les boubines sont complètement finies
- Peut durer un ou plusieurs jours
- Une semaine peut contenir plusieurs productions

---

## 📝 Tâches Détaillées par Phase

### Phase 1 : Modèle de Données et Entités (Priorité Critique)

#### Tâche 1.1 : Mettre à jour ProductionSessionStatus
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/production_session_status.dart`

**Actions :**
- ✅ Ajouter le statut `suspended` (Suspendue) pour pannes/coupures
- ✅ Mettre à jour les labels et extensions
- ✅ Ajouter la logique de reprise après suspension

**Critères de complétion :**
- Le statut `suspended` existe et fonctionne
- Les transitions de statut sont logiques

---

#### Tâche 1.2 : Enrichir ProductionSession
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/production_session.dart`

**Actions :**
- ✅ Ajouter `indexCompteurDebut` (kWh) - déjà présent
- ✅ Ajouter `indexCompteurFin` (kWh) - déjà présent
- ✅ Ajouter `consommationCourant` (kWh) - déjà présent
- ✅ Ajouter gestion des événements (pannes, coupures, arrêts)
- ✅ Ajouter liste des jours de production avec personnel
- ✅ S'assurer que la production ne se termine que quand toutes les boubines sont finies

**Nouvelles propriétés nécessaires :**
```dart
final List<ProductionEvent> events; // Pannes, coupures, arrêts
final List<ProductionDay> productionDays; // Jours avec personnel
final bool toutesBoubinesFinies; // Vérification automatique
```

**Critères de complétion :**
- Toutes les propriétés nécessaires sont présentes
- La logique de fin de production est correcte

---

#### Tâche 1.3 : Créer entité ProductionEvent
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/production_event.dart` (nouveau)

**Actions :**
- ✅ Créer l'entité `ProductionEvent`
- ✅ Types : panne, coupure, arrêt forcé
- ✅ Propriétés : type, date, heure, motif, durée

**Structure :**
```dart
enum ProductionEventType { panne, coupure, arretForce }
class ProductionEvent {
  final String id;
  final ProductionEventType type;
  final DateTime date;
  final DateTime heure;
  final String motif;
  final Duration? duree; // Si l'événement est terminé
}
```

**Critères de complétion :**
- L'entité est créée et testée
- Tous les types d'événements sont couverts

---

#### Tâche 1.4 : Créer entité ProductionDay
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/production_day.dart` (nouveau)

**Actions :**
- ✅ Créer l'entité `ProductionDay`
- ✅ Lier à une production
- ✅ Enregistrer le personnel présent
- ✅ Enregistrer le nombre de personnes
- ✅ Lier aux salaires journaliers

**Structure :**
```dart
class ProductionDay {
  final String id;
  final String productionId;
  final DateTime date;
  final List<String> personnelIds; // IDs des personnes présentes
  final int nombrePersonnes;
  final int salaireJournalierParPersonne;
}
```

**Critères de complétion :**
- L'entité est créée
- La liaison avec les salaires fonctionne

---

#### Tâche 1.5 : Améliorer BobineUsage pour installation obligatoire
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/bobine_usage.dart`

**Actions :**
- ✅ S'assurer que `poidsInitial` = pesée avant installation (obligatoire)
- ✅ Ajouter `dateInstallation` et `heureInstallation`
- ✅ Ajouter `estInstallee` et `estFinie`
- ✅ Validation : boubine neuve obligatoire

**Critères de complétion :**
- L'installation est tracée complètement
- La validation des boubines neuves fonctionne

---

#### Tâche 1.6 : Créer entité DailyWorker (Ouvrier Journalier)
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/daily_worker.dart` (nouveau)

**Actions :**
- ✅ Créer l'entité pour les ouvriers journaliers/temporaires
- ✅ Propriétés : nom, téléphone, salaire journalier
- ✅ Historique des jours travaillés
- ✅ Calcul salaire hebdomadaire

**Structure :**
```dart
class DailyWorker {
  final String id;
  final String name;
  final String phone;
  final int salaireJournalier;
  final List<WorkDay> joursTravailles; // Par semaine
}
```

**Critères de complétion :**
- L'entité est créée
- Le calcul hebdomadaire fonctionne

---

#### Tâche 1.7 : Mettre à jour Employee pour permanents
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/employee.dart`

**Actions :**
- ✅ S'assurer que `monthlySalary` est bien géré
- ✅ Ajouter historique des paiements mensuels
- ✅ Distinction claire entre journaliers et permanents

**Critères de complétion :**
- La distinction est claire
- L'historique est géré

---

### Phase 2 : Lancement et Installation (Priorité Haute)

#### Tâche 2.1 : Formulaire de lancement de production
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/screens/sections/production_session_form_screen.dart`

**Actions :**
- ✅ Champ date de début (obligatoire)
- ✅ Champ heure de début (obligatoire)
- ✅ Sélection nombre de machines (obligatoire)
- ✅ Liste des machines sélectionnées (obligatoire)
- ✅ Validation : au moins une machine

**Critères de complétion :**
- Tous les champs obligatoires sont présents
- La validation fonctionne
- L'interface est intuitive

---

#### Tâche 2.2 : Installation et pesée des boubines
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/bobine_installation_form.dart` (nouveau)

**Actions :**
- ✅ Pour chaque machine : sélection boubine neuve (obligatoire)
- ✅ Pesée avant installation (obligatoire)
- ✅ Enregistrement : ID boubine, poids initial, machine, date+heure
- ✅ Validation : nombre de boubines = nombre de machines

**Critères de complétion :**
- L'installation est complète
- Toutes les validations fonctionnent
- Les données sont enregistrées

---

#### Tâche 2.3 : Index compteur au démarrage
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/production_start_form.dart` (nouveau ou existant)

**Actions :**
- ✅ Champ index compteur initial (kWh) - obligatoire
- ✅ Validation du format
- ✅ Enregistrement avec la production

**Critères de complétion :**
- L'index est enregistré
- La validation fonctionne

---

### Phase 3 : Fonctionnement et Gestion des Événements (Priorité Haute)

#### Tâche 3.1 : Suivi en temps réel de la production
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/screens/sections/production_tracking_screen.dart`

**Actions :**
- ✅ Afficher l'état des boubines (en cours, finies)
- ✅ Afficher les machines actives
- ✅ Afficher la durée de production
- ✅ Vérifier si toutes les boubines sont finies

**Critères de complétion :**
- Le suivi est en temps réel
- L'état est clair
- La vérification fonctionne

---

#### Tâche 3.2 : Gestion des pannes/coupures/arrêts
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/production_event_dialog.dart` (nouveau)

**Actions :**
- ✅ Bouton "Enregistrer événement" (panne, coupure, arrêt)
- ✅ Formulaire : type, date, heure, motif
- ✅ Mise à jour statut production → "Suspendue"
- ✅ Les boubines restent dans les machines (sécurité)

**Critères de complétion :**
- Les événements sont enregistrés
- Le statut est mis à jour
- Les boubines ne sont pas retirées

---

#### Tâche 3.3 : Reprise après événement
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/production_resume_dialog.dart` (nouveau)

**Actions :**
- ✅ Bouton "Reprendre la production"
- ✅ Validation : mêmes boubines
- ✅ Mise à jour statut → "En cours"
- ✅ Enregistrement heure de reprise

**Critères de complétion :**
- La reprise fonctionne
- Les boubines sont vérifiées
- Le statut est correct

---

### Phase 4 : Fin de Production (Priorité Haute)

#### Tâche 4.1 : Vérification fin des boubines
**Fichiers concernés :**
- `lib/features/eau_minerale/application/controllers/production_session_controller.dart`

**Actions :**
- ✅ Vérifier que toutes les boubines sont finies
- ✅ Empêcher la finalisation si boubines non finies
- ✅ Message d'erreur clair si tentative prématurée

**Critères de complétion :**
- La vérification est automatique
- Les messages sont clairs
- La sécurité est assurée

---

#### Tâche 4.2 : Finalisation de production
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/screens/sections/production_session_detail_screen.dart`

**Actions :**
- ✅ Champ date de fin (obligatoire)
- ✅ Champ heure de fin (obligatoire)
- ✅ Champ index compteur final (kWh) - obligatoire
- ✅ Calcul automatique consommation = index final - index initial
- ✅ Validation : toutes les boubines finies
- ✅ Mise à jour statut → "Terminée"

**Critères de complétion :**
- La finalisation est sécurisée
- Les calculs sont corrects
- Le statut est mis à jour

---

#### Tâche 4.3 : Pesée finale des boubines
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/bobine_final_weighing_form.dart` (nouveau)

**Actions :**
- ✅ Pour chaque boubine : pesée finale (obligatoire)
- ✅ Vérification : poids final ≤ poids initial
- ✅ Calcul poids utilisé
- ✅ Mise à jour stock de boubines

**Critères de complétion :**
- Les pesées sont enregistrées
- Le stock est mis à jour
- Les calculs sont corrects

---

### Phase 5 : Gestion du Personnel Journalier (Priorité Haute)

#### Tâche 5.1 : Enregistrement personnel par jour
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/daily_personnel_form.dart` (nouveau)

**Actions :**
- ✅ Pour chaque jour de production : formulaire personnel
- ✅ Sélection des personnes présentes
- ✅ Enregistrement nombre de personnes
- ✅ Liaison avec la production

**Critères de complétion :**
- L'enregistrement fonctionne
- La liaison est correcte
- L'interface est intuitive

---

#### Tâche 5.2 : Calcul salaires journaliers hebdomadaires
**Fichiers concernés :**
- `lib/features/eau_minerale/application/controllers/salary_controller.dart`

**Actions :**
- ✅ Calculer jours travaillés par ouvrier (par semaine)
- ✅ Calculer : salaire = jours × salaire journalier
- ✅ Afficher dans l'écran salaires
- ✅ Permettre paiement groupé

**Critères de complétion :**
- Les calculs sont corrects
- L'affichage est clair
- Le paiement fonctionne

---

#### Tâche 5.3 : Signature numérique après paiement
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/payment_signature_dialog.dart` (nouveau)

**Actions :**
- ✅ Après paiement : demande signature
- ✅ Enregistrement signature numérique
- ✅ Association avec le paiement

**Critères de complétion :**
- La signature fonctionne
- L'enregistrement est sécurisé

---

### Phase 6 : Gestion des Salaires Permanents (Priorité Moyenne)

#### Tâche 6.1 : Calcul salaires mensuels
**Fichiers concernés :**
- `lib/features/eau_minerale/application/controllers/salary_controller.dart`

**Actions :**
- ✅ Calculer salaire mensuel fixe
- ✅ Afficher dans l'écran salaires
- ✅ Historique des paiements mensuels

**Critères de complétion :**
- Les calculs sont corrects
- L'historique est complet

---

#### Tâche 6.2 : Paiement des permanents
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/fixed_employee_form.dart`

**Actions :**
- ✅ Permettre paiement mensuel
- ✅ Enregistrement dans l'historique
- ✅ Génération reçu

**Critères de complétion :**
- Le paiement fonctionne
- L'historique est mis à jour

---

### Phase 7 : Gestion du Stock (Priorité Moyenne)

#### Tâche 7.1 : Stock des boubines
**Fichiers concernés :**
- `lib/features/eau_minerale/application/controllers/stock_controller.dart`

**Actions :**
- ✅ Entrées : lors des livraisons
- ✅ Sorties : lors des installations en production
- ✅ Mise à jour automatique lors installation/retrait

**Critères de complétion :**
- Le stock est mis à jour automatiquement
- Les mouvements sont tracés

---

#### Tâche 7.2 : Stock des emballages
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/stock_item.dart`

**Actions :**
- ✅ Enregistrer quantité utilisée à la fin de chaque production
- ✅ Mise à jour automatique du stock
- ✅ Alertes stock faible

**Critères de complétion :**
- Le stock est mis à jour
- Les alertes fonctionnent

---

### Phase 8 : Gestion des Dépenses (Priorité Moyenne)

#### Tâche 8.1 : Dépenses générales
**Fichiers concernés :**
- `lib/features/eau_minerale/domain/entities/expense.dart`

**Actions :**
- ✅ Types : carburant, réparations, achats divers, autres
- ✅ Propriétés : montant, date, motif
- ✅ Option : lier à une production ou indépendant

**Critères de complétion :**
- Tous les types sont gérés
- La liaison fonctionne

---

#### Tâche 8.2 : Formulaire dépenses
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/expense_form.dart` (existant ou nouveau)

**Actions :**
- ✅ Sélection type dépense
- ✅ Champ montant, date, motif
- ✅ Option : lier à une production
- ✅ Validation complète

**Critères de complétion :**
- Le formulaire est complet
- La validation fonctionne

---

### Phase 9 : Rapports (Priorité Moyenne)

#### Tâche 9.1 : Rapport par production
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/screens/sections/reports_screen.dart`

**Actions :**
- ✅ Détails complets d'une production
- ✅ Boubines utilisées, machines, personnel
- ✅ Consommation électrique, dépenses
- ✅ Marges et rentabilité

**Critères de complétion :**
- Le rapport est complet
- Les données sont précises

---

#### Tâche 9.2 : Rapports hebdomadaires/mensuels
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/widgets/reports_content.dart`

**Actions :**
- ✅ Rapport par semaine
- ✅ Rapport par mois
- ✅ Détails dépenses, salaires, consommation
- ✅ Graphiques et statistiques

**Critères de complétion :**
- Les rapports sont complets
- Les visualisations sont claires

---

### Phase 10 : Paramètres Généraux (Priorité Basse)

#### Tâche 10.1 : Écran paramètres
**Fichiers concernés :**
- `lib/features/eau_minerale/presentation/screens/sections/settings_screen.dart`

**Actions :**
- ✅ Salaire journalier par défaut
- ✅ Salaire mensuel des permanents
- ✅ Prix du kWh
- ✅ Types de boubines
- ✅ Types d'emballages

**Critères de complétion :**
- Tous les paramètres sont configurables
- Les valeurs par défaut sont définies

---

## 🧪 Tests et Validation

### Scénarios de test :

1. ✅ **Lancement production**
   - Créer production avec date/heure/machines
   - Installer boubines avec pesée
   - Enregistrer index compteur

2. ✅ **Production normale**
   - Suivre production en temps réel
   - Vérifier état des boubines
   - Enregistrer personnel journalier

3. ✅ **Gestion événements**
   - Enregistrer panne → statut suspendu
   - Reprendre production → statut en cours
   - Vérifier boubines toujours en place

4. ✅ **Fin de production**
   - Vérifier toutes boubines finies
   - Enregistrer index final
   - Calculer consommation
   - Finaliser production

5. ✅ **Salaires**
   - Calculer salaires journaliers hebdomadaires
   - Payer avec signature
   - Calculer salaires permanents mensuels

6. ✅ **Stock et dépenses**
   - Mise à jour stock automatique
   - Enregistrer dépenses
   - Lier dépenses à production

---

## 📊 Estimation Révisée

- **Phase 1 (Modèle) :** 8-10 heures
- **Phase 2 (Lancement) :** 6-8 heures
- **Phase 3 (Fonctionnement) :** 8-10 heures
- **Phase 4 (Fin) :** 6-8 heures
- **Phase 5 (Personnel journalier) :** 8-10 heures
- **Phase 6 (Salaires permanents) :** 4-6 heures
- **Phase 7 (Stock) :** 4-6 heures
- **Phase 8 (Dépenses) :** 4-6 heures
- **Phase 9 (Rapports) :** 6-8 heures
- **Phase 10 (Paramètres) :** 2-4 heures
- **Tests et validation :** 8-10 heures

**Total estimé :** 64-86 heures

---

## 🚀 Ordre d'exécution recommandé

1. **Phase 1** (Modèle) - Base de données et logique métier
2. **Phase 2** (Lancement) - Permettre de créer des productions
3. **Phase 3** (Fonctionnement) - Gérer le cycle de vie
4. **Phase 4** (Fin) - Finaliser correctement
5. **Phase 5** (Personnel journalier) - Fonctionnalité critique
6. **Phase 6** (Salaires permanents) - Compléter la gestion salaires
7. **Phase 7** (Stock) - Automatisation importante
8. **Phase 8** (Dépenses) - Compléter la gestion financière
9. **Phase 9** (Rapports) - Visualisation et analyse
10. **Phase 10** (Paramètres) - Configuration

---

## 📝 Notes Importantes

- ⚠️ **Sécurité** : Les boubines ne peuvent pas être retirées tant qu'elles ne sont pas finies
- ⚠️ **Validation** : Une production ne peut se terminer que si toutes les boubines sont finies
- ⚠️ **Continuité** : Une production fonctionne en continu jusqu'à fin des boubines
- ⚠️ **Suspension** : En cas de panne/coupure, la production reprend sur les mêmes boubines
- ✅ Respecter la limite de 200 lignes par fichier
- ✅ Utiliser Riverpod pour le state management
- ✅ Suivre les règles de design UI/UX du projet

---

**Dernière mise à jour :** 10 décembre 2025
**Basé sur :** Spécifications finales du module Production
