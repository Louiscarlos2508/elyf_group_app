# Module Gaz - ELYF Group App

Ce module gère le cycle complet de distribution du butane, optimisé pour une structure à deux niveaux : l'**Entreprise Parent (Administrative)** et les **Points de Vente (Autonomes)**.

## 1. Points de Vente (POS) : Autonomie & Vente
Les POS gèrent leurs opérations quotidiennes de manière indépendante.

- **Gestion des Prix** : Chaque POS définit ses propres prix de vente (Détail et Gros) dans ses paramètres locaux.
- **Vente Flexible** : Support des ventes au détail et en gros avec possibilité de **forcer manuellement le prix unitaire** lors de la transaction.
- **Mouvements de Stock** : 
    - **Entrées** : Bouteilles Pleines (après recharge) ou Vides (retours clients).
    - **Sorties** : Bouteilles Vides (envoi pour recharge).
- **Gestion des Fuites** : Signalement d'une fuite transforme la bouteille en "Vide" et l'enregistre comme une perte financière tracée.
- **Trésorerie & Rapports** : Toutes les ventes alimentent la trésorerie locale du POS avec des rapports détaillés.

## 2. Entreprise Parent : Supervision & Logistique
Le Parent agit comme un coordinateur administratif et logistique.

- **Suivi des Stocks** : La vue stock du Parent est un tableau de bord de supervision des stocks de tous ses POS.
- **Paramétrage** : Définit les prix d'achat/recharge du gaz auprès des fournisseurs.
- **Gestion des Tours (Administrative)** : Workflow complet pour enregistrer :
    - Les mouvements de bouteilles par POS.
    - Les recharges chez les grossistes.
    - Les dépenses logistiques (carburant, main-d'œuvre, route).
    - La collecte des fonds auprès des grossistes.
- **Ressources Humaines** : Gestion des paiements de salaires des employés du groupe.
- **Trésorerie Centrale** : Suivi des flux financiers liés aux tournées et aux remontées des POS.

## 3. Architecture Data
- **Isolation** : Utilisation de `siteId` pour isoler les inventaires physiques de chaque POS sous un même Parent.
- **Sync** : Synchronisation temps réel entre le mobile et Firestore pour une supervision instantanée par le Parent.

