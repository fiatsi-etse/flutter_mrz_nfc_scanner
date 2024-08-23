// Exception personnalisée pour les erreurs de formatage de date
class DateFormatException implements Exception {
  String cause;
  DateFormatException(this.cause);
}

class Formatter {
  String formatBirthDate(String date) {
    try {
      // Validation de la longueur de la date
      if (date.length != 6) {
        throw DateFormatException('La date de naissance n\'est pas de longueur valide.');
      }

      DateTime dateToday = DateTime.now();
      String currentYearLast2Digits = dateToday.year.toString().substring(2, 4);
      String givenYearFirst2Digits = date.substring(0, 2);
      String givenYear = date.substring(0, 2);
      String givenMonth = date.substring(2, 4);
      String givenDay = date.substring(4, 6);

      // Validation de la date (mois et jour)
      if (int.parse(givenMonth) < 1 || int.parse(givenMonth) > 12) {
        throw DateFormatException('Mois invalide dans la date de naissance.');
      }

      if (int.parse(givenDay) < 1 || int.parse(givenDay) > 31) {
        throw DateFormatException('Jour invalide dans la date de naissance.');
      }

      late String birthDate;

      if (int.parse(currentYearLast2Digits) > int.parse(givenYearFirst2Digits)) {
        // birth year should be 2000 and above
        birthDate = "20$givenYear-$givenMonth-$givenDay";
      } else {
        // birth year should be 1999 and below
        birthDate = "19$givenYear-$givenMonth-$givenDay";
      }

      // Vérification que la date peut être parsée correctement
      DateTime.parse(birthDate); // Cette ligne génère une exception si la date n'est pas valide

      return birthDate;
    } catch (e) {
      throw DateFormatException('Erreur lors du formatage de la date de naissance: $e');
    }
  }

  String formatExpiryDate(String date) {
    try {
      // Validation de la longueur de la date
      if (date.length != 6) {
        throw DateFormatException('La date d\'expiration n\'est pas de longueur valide.');
      }

      String givenYear = date.substring(0, 2);
      String givenMonth = date.substring(2, 4);
      String givenDay = date.substring(4, 6);

      // Validation de la date (mois et jour)
      if (int.parse(givenMonth) < 1 || int.parse(givenMonth) > 12) {
        throw DateFormatException('Mois invalide dans la date d\'expiration.');
      }

      if (int.parse(givenDay) < 1 || int.parse(givenDay) > 31) {
        throw DateFormatException('Jour invalide dans la date d\'expiration.');
      }

      late String expiryYear;

      expiryYear = "20$givenYear-$givenMonth-$givenDay";

      // Vérification que la date peut être parsée correctement
      DateTime.parse(expiryYear); // Cette ligne génère une exception si la date n'est pas valide

      return expiryYear;
    } catch (e) {
      throw DateFormatException('Erreur lors du formatage de la date d\'expiration: $e');
    }
  }
}
