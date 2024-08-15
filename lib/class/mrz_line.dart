class MrzLine {

  /// Chaque line des mrz sera parsé par le reconnaisseur d'image
  /// Cette classe représente donc les différentes lignes 

  String text;
  bool isDetected;

  MrzLine(this.text, this.isDetected);
}