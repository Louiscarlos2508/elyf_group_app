/// Type de compteur électrique utilisé dans l'entreprise.
enum ElectricityMeterType {
  /// Compteur Cash Power : consommation en kWh, valeur diminue avec l'utilisation
  /// Exemple: début = 100 kWh, fin = 80 kWh, consommation = 20 kWh
  cashPower,

  /// Compteur classique : consommation en index, valeur augmente avec l'utilisation
  /// Exemple: début = 1000 index, fin = 1200 index, consommation = 200 index
  classic,
}

extension ElectricityMeterTypeExtension on ElectricityMeterType {
  /// Libellé du type de compteur
  String get label {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Cash Power';
      case ElectricityMeterType.classic:
        return 'Classique';
    }
  }

  /// Description du type de compteur
  String get description {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Compteur prépayé : la valeur diminue avec la consommation (unité: kWh)';
      case ElectricityMeterType.classic:
        return 'Compteur classique : la valeur augmente avec la consommation (unité: index)';
    }
  }

  /// Unité de mesure
  String get unit {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'kWh';
      case ElectricityMeterType.classic:
        return 'index';
    }
  }

  /// Libellé pour l'index initial
  String get initialLabel {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Solde initial (kWh)';
      case ElectricityMeterType.classic:
        return 'Index initial';
    }
  }

  /// Libellé pour l'index final
  String get finalLabel {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Solde final (kWh)';
      case ElectricityMeterType.classic:
        return 'Index final';
    }
  }

  /// Helper text pour l'index initial
  String get initialHelperText {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Solde disponible au démarrage de la production';
      case ElectricityMeterType.classic:
        return 'Index du compteur au démarrage de la production';
    }
  }

  /// Helper text pour l'index final
  String get finalHelperText {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Solde restant à la fin de la production (doit être < solde initial)';
      case ElectricityMeterType.classic:
        return 'Index du compteur à la fin de la production (doit être > index initial)';
    }
  }

  /// Calcule la consommation à partir des index initial et final
  double calculateConsumption(double initial, double finalValue) {
    switch (this) {
      case ElectricityMeterType.cashPower:
        // Pour Cash Power : consommation = initial - final (car la valeur diminue)
        return initial - finalValue;
      case ElectricityMeterType.classic:
        // Pour classique : consommation = final - initial (car la valeur augmente)
        return finalValue - initial;
    }
  }

  /// Valide que les valeurs sont cohérentes avec le type de compteur
  bool isValidRange(double initial, double finalValue) {
    switch (this) {
      case ElectricityMeterType.cashPower:
        // Pour Cash Power : final doit être < initial
        return finalValue < initial;
      case ElectricityMeterType.classic:
        // Pour classique : final doit être > initial
        return finalValue > initial;
    }
  }

  /// Message d'erreur si la validation échoue
  String get validationErrorMessage {
    switch (this) {
      case ElectricityMeterType.cashPower:
        return 'Le solde final doit être inférieur au solde initial';
      case ElectricityMeterType.classic:
        return 'L\'index final doit être supérieur à l\'index initial';
    }
  }
}
