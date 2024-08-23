class MrzInfos {
  /// Permet de concerver les différentes informations recueillies grâce au MRZ
  FirstLineInfo firstLineInfo;
  SecondLineInfo secondLineInfo;

  MrzInfos(this.firstLineInfo, this.secondLineInfo);
}

class FirstLineInfo {
  String firstName;
  String lastName;
  String country;
  String documentType;

  FirstLineInfo(this.firstName, this.lastName, this.country, this.documentType);
}

class SecondLineInfo {
  String passportNumber;
  String birthDate;
  String expiryDate;

  SecondLineInfo(this.passportNumber, this.birthDate, this.expiryDate);
}
