class Validators {
  static String? requiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    final number = num.tryParse(value);
    if (number == null || number <= 0) {
      return 'Veuillez saisir un nombre positif';
    }
    return null;
  }
}
