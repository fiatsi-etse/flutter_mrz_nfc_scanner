import 'package:scan/Formatter.dart';
import 'package:scan/mrzScanner.dart';

parseTD3SecondLine(String text) {
  Formatter formatter = Formatter();
  print('parsing second line, $text');
  String passportNumber = text.substring(0, 9);
  String mrzBirthDate = text.substring(13, 19);
  String mrzExpiryDate = text.substring(21, 27);
  String birthDate = formatter.formatBirthDate(mrzBirthDate);
  String expiryDate = formatter.formatExpiryDate(mrzExpiryDate);

  return {passportNumber, birthDate, expiryDate};
}

parseTD3FirstLine(String text) {
  print('Parsing first line');
  List<String> splited = text.split("<");
  print('splited = $splited');
  String documentType = splited[0];
  print("DocumentType = $documentType");
  String country = splited[1].substring(0, 3);
  print("country = $country");
  String lastName = splited[1].substring(3);
  print("lastName = $lastName");
  String firstName = splited[3];
  print("firstName = $firstName");
  // UserPersonnalInfos userPersonnalInfos = UserPersonnalInfos();
  // return userPersonnalInfos;
  return {firstName, lastName, country, documentType};
}

Map<String, dynamic> parseTD1MRZ(String line1, String line2, String line3) {

  Formatter formatter = Formatter();

  print(line3);

  // Parse line 1 details
  String documentType = line1.substring(0, 2).trim();
  String issuingCountry = line1.substring(2, 5);
  String passportNumber = line1.substring(5, 14).trim();
  String passportNumberCheckDigit = line1[14];
  String optionalData1 = line1.substring(15, 30).trim();

  // Parse line 2 details
  String dateOfBirth = formatter.formatBirthDate(line2.substring(0, 6));
  String gender = line2[7];
  String expiryDate = formatter.formatExpiryDate(line2.substring(8, 14));
  String nationality = line2.substring(15, 18);
  String optionalData2 = line2.substring(18, 29).trim();
  String line2CheckDigit = line2[29];

  // Parse line 3 details
  String nameField = line3.substring(0, 30).trim();
  List<String> nameParts = nameField.split('<<');
  String surname = nameParts[0].replaceAll('<', ' ').trim();
  String givenNames = nameParts.length > 1 ? nameParts[1].replaceAll('<', ' ').trim() : '';

  // Combine all parsed data into a single map
  return {
    'documentType': documentType.replaceAll("<", ""),
    'issuingCountry': issuingCountry.replaceAll("<", ""),
    'passportNumber': passportNumber.replaceAll("<", ""),
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'expiryDate': expiryDate,
    'nationality': nationality,
    'surname': surname,
    'givenNames': givenNames,
  };
}


Map<String, dynamic> parseTD3MRZ(String line1, String line2) {

  print('line 1 $line1\n line 2 $line2');
  
  Formatter formatter = Formatter();

  // Parse line 1 details
  String documentType = line1.substring(0, 2).trim();
  String issuingCountry = line1.substring(2, 5);
  String nameField = line1.substring(5, line1.length).trim();
  List<String> nameParts = nameField.split('<<');
  String surname = nameParts[0].replaceAll('<', ' ').trim();
  String givenNames = nameParts.length > 1 ? nameParts[1].replaceAll('<', ' ').trim() : '';

  // Parse line 2 details
  String passportNumber = line2.substring(0, 9).trim();
  String nationality = line2.substring(10, 13);
  String dateOfBirth = formatter.formatBirthDate(line2.substring(13, 19));
  String gender = line2[20];
  String expiryDate = formatter.formatExpiryDate(line2.substring(21, 27));

  // Combine all parsed data into a single map
  return {
    'documentType': documentType.replaceAll("<", ""),
    'issuingCountry': issuingCountry.replaceAll("<", ""),
    'surname': surname,
    'givenNames': givenNames,
    'passportNumber': passportNumber.replaceAll("<", ""),
    'nationality': nationality,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'expiryDate': expiryDate,
  };
}


bool isNumeric(String s) {
 if (s == null) {
   return false;
 }
 return double.tryParse(s) != null;
}