import 'package:flutter/material.dart';

class ScanResultPage extends StatefulWidget {
  final result;

  ScanResultPage(this.result, {super.key});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  String formatPassportData(Map<String, dynamic> data) {
    return '''
Document Type: ${data['documentType']}
Issuing Country: ${data['issuingCountry']}
Passport Number: ${data['passportNumber']}
Date of Birth: ${data['dateOfBirth']}
Gender: ${data['gender']}
Expiry Date: ${data['expiryDate']}
Nationality: ${data['nationality']}
Surname: ${data['surname']}
Given Names: ${data['givenNames']}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passport Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(formatPassportData(widget.result)),
      ),
    );
  }
}
