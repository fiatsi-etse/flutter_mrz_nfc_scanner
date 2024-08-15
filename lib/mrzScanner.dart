// ignore_for_file: non_constant_identifier_names

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:scan/PassportMrzParser.dart';
import 'package:scan/class/mrz_infos.dart';
import 'package:scan/nfcInfo.dart';
import 'class/mrz_line.dart';
import 'main.dart';

class MrzScan extends StatefulWidget {
  const MrzScan({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MrzScanState createState() => _MrzScanState();
}

class _MrzScanState extends State<MrzScan> {
  MrzLine mrzLine2 = MrzLine("Mrz line 2", false);
  MrzLine mrzLine1 = MrzLine("Mrz line 1", false);
  MrzInfos mrzInfos = MrzInfos("", "", "", "", "", "", "");

  double linearValue = 0;

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
                          color: (mrzLine1.isDetected && mrzLine2.isDetected)
                              ? Colors.green
                              : Colors.white
                                  .withOpacity(0.8), // Couleur de l'icône
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: (mrzLine1.isDetected && mrzLine2.isDetected)
                                ? Text(
                                    '${mrzLine1.text} ${mrzLine2.text}',
                                    style: const TextStyle(
                                        color: Colors.green, fontSize: 18),
                                  )
                                : const Text(
                                    ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: LinearProgressIndicator(
                              value: linearValue,
                              color: Colors.green,
                              minHeight: 6,
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
    if (mounted) {
      for (var element in recognizedText.blocks) {
        for (var line in element.lines) {
          if (kDebugMode) {
            print(line.text);
          }
          if (!mrzLine1.isDetected) {
            await _detectMrzFirstLine(line.text);
            if (mrzLine1.isDetected) {
              setState(() {
                mrzInfos = _parseMrzFirstLine(mrzLine1);
                linearValue += 0.5;
              });
            }
          }

          if (!mrzLine2.isDetected) {
            await _detectMrz(line.text);
            if (mrzLine2.isDetected) {
              setState(() {
                mrzInfos = _parseMrz(mrzLine2);

                linearValue += 0.5;
              });
            }
          }

          if (mrzLine1.isDetected && mrzLine2.isDetected) {
            Future.delayed(Duration(seconds: 1), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => NfcInfo(
                          mrzInfos,
                        )));
            });
            return;
          }
        }
      }
    }
    _isBusy = false;
  }

  //TODO improve mrz detecting
  _detectMrz(String text) async {
    RegExp passportTD3Line2RegExp = RegExp(
        r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{14})([0-9]{1})([0-9]{1})");
    RegExp passportTD3Line2CustomRegExp = RegExp(
        r"([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{15})([0-9]{1})"); // some international passports uses this format
    if (passportTD3Line2RegExp.hasMatch(text.replaceAll(" ", "")) ||
        passportTD3Line2CustomRegExp.hasMatch(text.replaceAll(" ", ""))) {
      print(
          "------------------------DETECTED 2222222222222222-----------------------");
      mrzLine2.text = text.replaceAll(" ", "");
      mrzLine2.isDetected = true;
    }
  }

  _detectMrzFirstLine(String text) async {
    RegExp passportTD3Line2RegExp = RegExp(r'^P<[A-Z]{3}[A-Z< ]{1,39}$');
    if (passportTD3Line2RegExp.hasMatch(text.replaceAll(" ", ""))) {
      print(
          "------------------------DETECTED 11111111111-----------------------");
      mrzLine1.text = text.replaceAll(" ", "");
      mrzLine1.isDetected = true;
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
