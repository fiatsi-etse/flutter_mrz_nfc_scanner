import 'package:scan/Formatter.dart';
import 'package:scan/class/mrz_infos.dart';

class PassportMrzParser {
  String mrzLine2;

  PassportMrzParser(this.mrzLine2);

  Formatter formatter = Formatter();


  parseMrz() {
    print('parsing second line, $mrzLine2');
    String passportNumber = mrzLine2.substring(0, 9);
    String mrzBirthDate = mrzLine2.substring(13, 19);
    String mrzExpiryDate = mrzLine2.substring(21, 27);
    
    try {
      String birthDate = formatter.formatBirthDate(mrzBirthDate);
      String expiryDate = formatter.formatExpiryDate(mrzExpiryDate);

      SecondLineInfo secondLineInfo = SecondLineInfo(passportNumber, birthDate, expiryDate);

      return secondLineInfo;
    } catch (e) {
      // Gérer l'exception ici (par exemple, logger l'erreur ou afficher un message d'erreur)
      print('Erreur lors de l\'analyse MRZ : $e');
    }
  }

  parseFirstLine() {
    List<String> splited = mrzLine2.split("<");
    String documentType = splited[0];
    print('splited $splited');
    String country = splited[1].substring(0, 3);
    String lastName = splited[1].substring(3);
    String firstName = splited[3];
    FirstLineInfo firstLineInfo = FirstLineInfo(firstName, lastName, country, documentType);
    return firstLineInfo;
  }
}
