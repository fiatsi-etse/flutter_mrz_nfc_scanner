

import 'package:scan/Formatter.dart';
import 'package:scan/class/mrz_infos.dart';

class PassportMrzParser {
  String mrzLine2;

  PassportMrzParser(this.mrzLine2);

  Formatter formatter = Formatter();

  MrzInfos mrzInfos = MrzInfos("", "", "", "", "", "", "");


  parseMrz() {
    print('parsing second line, $mrzLine2');
    String passportNumber = mrzLine2.substring(0, 9);
    String mrzBirthDate = mrzLine2.substring(13, 19);
    String mrzExpiryDate = mrzLine2.substring(21, 27);
    String birthDate = formatter.formatBirthDate(mrzBirthDate);
    String expiryDate = formatter.formatExpiryDate(mrzExpiryDate);
    mrzInfos.ExpiryDate = expiryDate;
    mrzInfos.passportNumber = passportNumber;
    mrzInfos.birthDate = birthDate;
    return mrzInfos;
  }

  parseFirstLine() {
    List<String> splited = mrzLine2.split("<");
    String documentType = splited[0];
    String country = splited[1].substring(0,3);
    String lastName = splited[1].substring(3);
    String firstName = splited[3];
    mrzInfos.firstName = firstName;
    mrzInfos.lastName = lastName;
    mrzInfos.documentType = documentType;
    mrzInfos.country = country;
    return mrzInfos;
  }
}
