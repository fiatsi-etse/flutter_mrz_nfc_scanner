// ignore_for_file: non_constant_identifier_names

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:scan/PassportMrzParser.dart';
import 'package:scan/nfcInfo.dart';
import 'main.dart';

class MrzScan extends StatefulWidget {
  const MrzScan({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MrzScanState createState() => _MrzScanState();
}

class _MrzScanState extends State<MrzScan> {
  MrzLine mrzLine2 = MrzLine("Mrz line 2", false, "", "", "", 0);
  MrzLine mrzLine1 = MrzLine("Mrz line 1", false, "", "", "", 0);

  MrzLine customMrzLine = MrzLine("Mrz line 1", false, "", "", "", 0);

  ChipAuthenticationData chipAuthenticationData =
      ChipAuthenticationData("", "", "");
  UserPersonnalInfos userPersonnalInfos = UserPersonnalInfos("", "", "", "");

  double linearValue = 0;

  int passeportType = 0;

  bool _isBusy = false;
  bool initialized = false;
  late CameraController controller;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: !initialized
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(
                    controller,
                  ),
                ),
                Positioned(
                    top: 200, // Ajustez la position verticale si nécessaire
                    left: 20, // Ajustez la position horizontale si nécessaire
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person, // Icône à gauche
                          size: 100, // Taille de l'icône
                          color: Colors.white
                              .withOpacity(0.8), // Couleur de l'icône
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: const Text(
                              ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: LinearProgressIndicator(
                              value: linearValue,
                              semanticsLabel: 'Linear progress indicator',
                            ),
                          ),
                        ),
                      ],
                    )),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7), BlendMode.srcOut),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.green,
                            backgroundBlendMode: BlendMode.dstOut),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: EdgeInsets.only(top: size.height * 0.2),
                          height: size.height * 0.30,
                          width: size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void initState() {
    initController();
    super.initState();
  }

  Future<void> initController() async {
    controller = CameraController(cameras[0], ResolutionPreset.max);
    await controller.initialize().then((_) {
      setState(() {
        initialized = true;
        _startImageStream();
      });
      if (!mounted) {
        return;
      }
    });
  }

  Future<void> _startImageStream() async {
    if (!controller.value.isInitialized) {
      if (kDebugMode) {
        print('controller not initialized');
      }
      return;
    }
    await controller.startImageStream((image) async {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(cameras[0].sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
      _processImage(inputImage);
    });
  }

  void _processImage(InputImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    final recognizedText = await _textRecognizer.processImage(image);

    if (mounted && !customMrzLine.isDetected) {
      // print(recognizedText.blocks[0].lines[0].);

      List<String> textList =
          recognizedText.blocks.map((line) => line.text).toList();
      // print("Affichage de la liste : $textList");
      List<String> stringsWithAngleBrackets = textList
          .where((str) => str.replaceAll(" ", "").contains('<<<'))
          .toList();
      stringsWithAngleBrackets =
          stringsWithAngleBrackets.map((e) => e.replaceAll(" ", "")).toList();
      print('avec les mrz : $stringsWithAngleBrackets, ${stringsWithAngleBrackets.length}');

      if(stringsWithAngleBrackets.isNotEmpty) {
        for (var element in stringsWithAngleBrackets) {
          _detectFirstLines((element));
        }
      }
      
      if(customMrzLine.type<3 && customMrzLine.type!=0 && customMrzLine.lineOne.isNotEmpty && customMrzLine.lineTwo.isNotEmpty) {
        if(customMrzLine.type==1) {
          customMrzLine.isDetected = true;
          // TYPE 1
          // parse type 1
          // navigate to detail page
        } else {
          customMrzLine.isDetected = true;
          // TYPE 2
          // parse type 2
          // navigate to detail page          
        }
      } else if (customMrzLine.type==3 && customMrzLine.lineOne.isNotEmpty && customMrzLine.lineTwo.isNotEmpty && customMrzLine.lineThree.isNotEmpty) {
        customMrzLine.isDetected = true;
        // TYPE 3
        // parse type 3
          // navigate to detail page
      }

      // for (var element in recognizedText.blocks) {
      //   print("affichage de la liste : ${element.text}");
      //   // for (var line in element.lines) {

      //   //   if (kDebugMode) {
      //   //     print(line.text);
      //   //   }

      //   //   if(!line.text.contains("<")) return;

      //   //   if (!mrzLine1.isDetected) {
      //   //     await _detectLines(line.text);
      //   //     return;
      //   //     // if (mrzLine1.isDetected) {
      //   //     //   setState(() {
      //   //     //     print("=============================================++++++++++++++++++++++++++++++++++++++++++++++++");
      //   //     //   userPersonnalInfos = _parseMrzFirstLine(mrzLine1);
      //   //     //     linearValue += 0.5;
      //   //     //   });
      //   //     // }
      //   //   }

      //   //   // if (mrzLine1.isDetected && mrzLine2.isDetected) {
      //   //   //   Navigator.pushReplacement(
      //   //   //       context,
      //   //   //       MaterialPageRoute(
      //   //   //           builder: (context) => NfcInfo(
      //   //   //                 chipAuthenticationData,
      //   //   //                 userPersonnalInfos: userPersonnalInfos,
      //   //   //               )));

      //   //   //   return;
      //   //   // }
      //   // }
      // }
    }
    _isBusy = false;
  }

  //TODO improve mrz detecting
  // _detectMrz(String text) async {
  //   RegExp passportTD3Line2RegExp = RegExp(
  //       r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{14})([0-9]{1})([0-9]{1})");
  //   RegExp passportTD3Line2CustomRegExp = RegExp(
  //       r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{15})([0-9]{1})"); // some international passports uses this format
  //   if (passportTD3Line2RegExp.hasMatch(text.replaceAll(" ", "")) ||
  //       passportTD3Line2CustomRegExp.hasMatch(text.replaceAll(" ", ""))) {
  //     print(
  //         "------------------------DETECTED 2222222222222222-----------------------");
  //     mrzLine2.text = text.replaceAll(" ", "");
  //     mrzLine2.isDetected = true;
  //   }
  // }

  // _detectMrzFirstLine(String text) async {
  //   RegExp passportTD3Line2RegExp = RegExp(r'^P<[A-Z]{3}[A-Z< ]{1,39}$');
  //   if (passportTD3Line2RegExp.hasMatch(text.replaceAll(" ", ""))) {
  //     print(
  //         "------------------------DETECTED 11111111111-----------------------");
  //     mrzLine1.text = text.replaceAll(" ", "");
  //     mrzLine1.isDetected = true;
  //   }
  // }

  _detectFirstLines(String text) {
    print("---------------------detecting-------------- $text");

    // line 3
    final RegExp passportTD3Line1RegExp = RegExp(r'^P<[A-Z]{3}[A-Z< ]{1,39}$');
    final RegExp passportTD1Line1RegExp = RegExp(
        r'^([ACI][A-Z0-9<]{1})([A-Z]{3})([A-Z0-9<]{9})([0-9]{1})([A-Z0-9<]{15})$');
    final RegExp passportTD2Line1RegExp =
        RegExp(r'^([ACI][A-Z0-9<]{1})([A-Z]{3})([A-Z0-9<]{31})$');

    // line 2
    final RegExp passportTD3Line2RegExp = RegExp(
        r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{14})([0-9]{1})([0-9]{1})");
    final RegExp passportTD3Line2CustomRegExp = RegExp(
        r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{15})([0-9]{1})"); // some international passports uses this format
    final RegExp passportTD1Line2RegExp = RegExp(
        r'^([0-9]{6})([0-9]{1})([MFX<]{1})([0-9]{6})([0-9]{1})([A-Z]{3})([A-Z0-9<]{11})([0-9]{1})$');
    final RegExp passportTD2Line2RegExp = RegExp(
        r'^([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([MFX<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{7})([0-9]{1})$');


    final RegExp passportTD1Line3RegExp = RegExp(r'^([A-Z0-9<]{30})$');

    // les premières lignes de tous les types de passeport
    if (customMrzLine.lineOne.isEmpty) {
      if (passportTD1Line1RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD1 FIRST LINE IS DETECTED");
        customMrzLine.lineOne = text.replaceAll(" ", "");
        customMrzLine.type = 1;
      } else if (passportTD2Line1RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD2 FIRST LINE IS DETECTED");
        customMrzLine.lineOne = text.replaceAll(" ", "");
        customMrzLine.type = 2;
      } else if (passportTD3Line1RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD3 FIRST LINE IS DETECTED");
        customMrzLine.lineOne = text.replaceAll(" ", "");
        customMrzLine.type = 3;
      } else  {
      }
    } else if(customMrzLine.lineOne.isNotEmpty) {
      print("Line 1 already detected, type : ${customMrzLine.type}");
    } 


      // line 2
    if (customMrzLine.lineTwo.isEmpty) {
      if (passportTD1Line2RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD1 SECOND LINE IS DETECTED");
        customMrzLine.lineTwo = text.replaceAll(" ", "");
        customMrzLine.type = 1;
      } else if (passportTD2Line2RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD2 SECOND LINE IS DETECTED");
        customMrzLine.lineTwo = text.replaceAll(" ", "");
        customMrzLine.type = 2;
      } else if (passportTD3Line2RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD3 SECOND LINE IS DETECTED");
        customMrzLine.lineTwo = text.replaceAll(" ", "");
        customMrzLine.type = 3;
      } else  {
      }
    } else {
      print("Line 2 already detected, type : ${customMrzLine.type}");
    }
    
      // line 3
    
    if (customMrzLine.lineThree.isEmpty) {
      if (passportTD1Line3RegExp.hasMatch(text.replaceAll(" ", ""))) {
        print("TD1 THIRD LINE IS DETECTED");
        customMrzLine.lineThree = text.replaceAll(" ", "");
        customMrzLine.type = 3;
      } else  {
      }
    } else {
      print("Line 3 already detected, type : ${customMrzLine.type}");
    }
     
  }

  _parseMrz(MrzLine mrzLine2) {
    PassportMrzParser passportMrzParser = PassportMrzParser(mrzLine2.text);
    return passportMrzParser.parseMrz();
  }

  _parseMrzFirstLine(MrzLine mrzLine2) {
    PassportMrzParser passportMrzParser = PassportMrzParser(mrzLine2.text);
    return passportMrzParser.parseFirstLine();
  }

  @override
  void dispose() async {
    controller.dispose();
    super.dispose();
  }
}

class MrzLine {
  String text;
  bool isDetected;
  String lineOne;
  String lineTwo;
  String lineThree;
  int type;

  MrzLine(
      this.text, this.isDetected, this.lineOne, this.lineTwo, this.lineThree, this.type);
}

class ChipAuthenticationData {
  String passportNumber;
  String birthDate;
  String ExpiryDate;

  ChipAuthenticationData(this.passportNumber, this.birthDate, this.ExpiryDate);
}

class UserPersonnalInfos {
  String firstName;
  String lastName;
  String country;
  String documentType;

  UserPersonnalInfos(
      this.firstName, this.lastName, this.country, this.documentType);
}
