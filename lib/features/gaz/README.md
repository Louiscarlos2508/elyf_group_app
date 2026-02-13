# Module Gaz - ELYF Group App

Le module gaz de l'application est conçu pour gérer l'intégralité du cycle de distribution du butane, de l'approvisionnement à la vente finale, en distinguant deux modes principaux : les grossistes et les détaillants.

### 1. Gestion de l'Inventaire et des Formats
Le système doit suivre les stocks pour différents formats de bouteilles, notamment les bouteilles de **3 kg, 6 kg, 10 kg et 12 kg**, etc. L'application permet d'enregistrer le nombre de bouteilles reçues lors de l'approvisionnement et de décompter les sorties au fur et à mesure des ventes. Ce niveau concerne également l'approvisionnement des points de vente au détail.

### 2. Le Cycle des Grossistes
Le fonctionnement avec les grossistes suit un processus spécifique de dépôt et de recharge :
*   **Réception des vides** : Le gestionnaire enregistre le nombre de bouteilles vides déposées par le grossiste.
*   **Recharge** : L'entreprise utilise ses propres fonds pour envoyer ces bouteilles au centre de remplissage (Ouaga).
*   **Vente et Paiement** : Une fois les bouteilles pleines revenues, le grossiste les récupère et paie à ce moment-là.
*   **Vérification** : Le module permet de comparer le montant total encaissé avec le nombre de bouteilles sorties (ex: 133 bouteilles de 6 kg) pour s'assurer qu'il n'y a pas d'erreur de calcul.

### 3. Vente au Détail et Gestion
*   **Interface simplifiée** : Pour les ventes unitaires (1 ou 2 bouteilles), l'agent doit simplement cliquer sur le format (6 kg ou 12 kg) pour enregistrer la sortie et le paiement.
*   **Réconciliation des stocks** : Pour résoudre le problème des agents qui envoient de la liquidité globale sans détails, l'application doit obliger l'agent à lier l'argent envoyé au nombre exact de bouteilles vendues. Cela permet de savoir précisément combien de bouteilles il reste en stock sur place. Le manager gère ainsi les points de vente à distance.

### 4. Gestion des Fuites (Bouteilles Défectueuses)
Le module inclut une gestion rigoureuse des fuites pour éviter les écarts financiers :
*   Les bouteilles qui fuient sont notées à part et ne sont pas comptabilisées comme des ventes car le client/grossiste ne les paie pas.
*   Elles sont renvoyées au centre de chargement pour un échange gratuit au prochain approvisionnement. Le système doit tracer ces échanges pour que le stock soit mis à jour sans mouvement de fonds.

### 5. Suivi des Frais Logistiques pendant tour d'appro
L'application intègre les dépenses liées au mouvement du gaz :
*   **Frais de route** : Forfait (ex: 30 000 CFA par trajet).
*   **Carburant** : Saisie des montants de plein (ex: 230 000 à 260 000 CFA).
*   **Main-d'œuvre** : Frais de déchargement et de recharge par personne.
*   **Maintenance** : Révisions du véhicule, pneus et huile.

---

**En résumé**, ce module transforme un suivi manuel complexe sur papier en un système numérique permettant un bilan annuel automatique et une preuve de chaque transaction grâce à l'intégration de captures d'écran des paiements vers la trésorerie principale chez Groupe Admin.
