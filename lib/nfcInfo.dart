import 'dart:async';

import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:scan/class/mrz_infos.dart';
import 'package:scan/colored_button.dart';
import 'package:scan/date_converter.dart';
import 'package:scan/dmrtd_lib/src/com/nfc_provider.dart';
import 'package:scan/dmrtd_lib/src/crypto/aa_pubkey.dart';
import 'package:scan/dmrtd_lib/src/extension/logging_apis.dart';
import 'package:scan/dmrtd_lib/src/extension/uint8list_apis.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/dg.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efcom.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg1.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg10.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg11.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg12.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg13.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg14.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg15.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg16.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg2.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg3.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg4.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg5.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg6.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg7.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg8.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efdg9.dart';
import 'package:scan/dmrtd_lib/src/lds/df1/efsod.dart';
import 'package:scan/dmrtd_lib/src/lds/efcard_access.dart';
import 'package:scan/dmrtd_lib/src/lds/efcard_security.dart';
import 'package:scan/dmrtd_lib/src/lds/mrz.dart';
import 'package:scan/dmrtd_lib/src/lds/tlv.dart';
import 'package:scan/dmrtd_lib/src/passport.dart';
import 'package:scan/dmrtd_lib/src/proto/dba_keys.dart';
import 'package:scan/jpeg2000_converter.dart';
// import 'package:google_fonts/google_fonts.dart';

class MrtdData {
  EfCardAccess? cardAccess;
  EfCardSecurity? cardSecurity;
  EfCOM? com;
  EfSOD? sod;
  EfDG1? dg1;
  EfDG2? dg2;
  EfDG3? dg3;
  EfDG4? dg4;
  EfDG5? dg5;
  EfDG6? dg6;
  EfDG7? dg7;
  EfDG8? dg8;
  EfDG9? dg9;
  EfDG10? dg10;
  EfDG11? dg11;
  EfDG12? dg12;
  EfDG13? dg13;
  EfDG14? dg14;
  EfDG15? dg15;
  EfDG16? dg16;
  Uint8List? aaSig;
}

final Map<DgTag, String> dgTagToString = {
  EfDG1.TAG: 'EF.DG1',
  EfDG2.TAG: 'EF.DG2',
  EfDG3.TAG: 'EF.DG3',
  EfDG4.TAG: 'EF.DG4',
  EfDG5.TAG: 'EF.DG5',
  EfDG6.TAG: 'EF.DG6',
  EfDG7.TAG: 'EF.DG7',
  EfDG8.TAG: 'EF.DG8',
  EfDG9.TAG: 'EF.DG9',
  EfDG10.TAG: 'EF.DG10',
  EfDG11.TAG: 'EF.DG11',
  EfDG12.TAG: 'EF.DG12',
  EfDG13.TAG: 'EF.DG13',
  EfDG14.TAG: 'EF.DG14',
  EfDG15.TAG: 'EF.DG15',
  EfDG16.TAG: 'EF.DG16'
};

String formatEfCom(final EfCOM efCom) {
  var str = "version: ${efCom.version}\n"
      "unicode version: ${efCom.unicodeVersion}\n"
      "DG tags:";

  for (final t in efCom.dgTags) {
    try {
      str += " ${dgTagToString[t]!}";
    } catch (e) {
      str += " 0x${t.value.toRadixString(16)}";
    }
  }
  return str;
}

String formatMRZ(final MRZ mrz) {
  return "MRZ\nVersion: ${mrz.version}\nDocument Type: ${mrz.documentCode}\nDocument Number: ${mrz.documentNumber}\nCountry: ${mrz.country}\nNationality: ${mrz.nationality}\nName: ${mrz.firstName}\nSurname: ${mrz.lastName}\nGender: ${mrz.gender}\nDate of Birth: ${DateFormat.yMd().format(mrz.dateOfBirth)}\nDate of Expiry: ${DateFormat.yMd().format(mrz.dateOfExpiry)}\nAdditional data 1: ${mrz.optionalData}\nAdditional data 2: ${mrz.optionalData2 ?? 'None'}";
}

String formatDG2(final EfDG2 dg2) {
  return "DG2\nfaceImageType ${dg2.faceImageType}\nfacialRecordDataLength ${dg2.facialRecordDataLength}\nimageHeight ${dg2.imageHeight}\nimageType: ${dg2.imageType}\nlengthOfRecord ${dg2.lengthOfRecord}\nnumberOfFacialImages ${dg2.numberOfFacialImages}\nposeAngle ${dg2.poseAngle}";
}

String convertToReadableFormat(String input) {
  if (input.isEmpty) {
    return input;
  }

  String readableText = input.replaceAll('_', ' ');

  return readableText;
}

String formatDG15(final EfDG15 dg15) {
  var str = "EF.DG15:\n"
      "AAPublicKey\n"
      "type: ";

  final rawSubPubKey = dg15.aaPublicKey.rawSubjectPublicKey();
  if (dg15.aaPublicKey.type == AAPublicKeyType.RSA) {
    final tvSubPubKey = TLV.fromBytes(rawSubPubKey);
    var rawSeq = tvSubPubKey.value;
    if (rawSeq[0] == 0x00) {
      rawSeq = rawSeq.sublist(1);
    }

    final tvKeySeq = TLV.fromBytes(rawSeq);
    final tvModule = TLV.decode(tvKeySeq.value);
    final tvExp = TLV.decode(tvKeySeq.value.sublist(tvModule.encodedLen));

    str += "RSA\n"
        "exponent: ${tvExp.value.hex()}\n"
        "modulus: ${tvModule.value.hex()}";
  } else {
    str += "EC\n    SubjectPublicKey: ${rawSubPubKey.hex()}";
  }
  return str;
}

String formatProgressMsg(String message, int percentProgress) {
  final p = (percentProgress / 20).round();
  final full = "🟢 " * p;
  final empty = "⚪️ " * (5 - p);
  return message + "\n\n" + full + empty;
}

// ignore: must_be_immutable
class NfcInfo extends StatefulWidget {
  MrzInfos mrzInfos;

  NfcInfo(this.mrzInfos, {Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _NfcInfoState createState() => _NfcInfoState();
}

class _NfcInfoState extends State<NfcInfo> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();

  List<String> authData = [];

  var _alertMessage = "";
  final _log = Logger("mrtdeg.app");
  var _isNfcAvailable = false;
  var _isReading = false;
  // final _mrzData = GlobalKey<FormState>();

  // mrz data
  String? docNumber;
  String? dob; // date of birth
  String? doe; // date of doc expiry

  final NfcProvider _nfc = NfcProvider();
  // ignore: unused_field
  late Timer _timerStateUpdater;
  MrtdData? _mrtdData;

  Uint8List? rawImageData;
  Uint8List? rawHandSignatureData;

  Uint8List? jpegImage;
  Uint8List? jp2000Image;

  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(vsync: this);
    docNumber = widget.mrzInfos.secondLineInfo.passportNumber;
    print(widget.mrzInfos.secondLineInfo.birthDate);
    print(widget.mrzInfos.secondLineInfo.expiryDate);

    print(
        'widget.mrzInfos.ExpiryDate = ${widget.mrzInfos.secondLineInfo.expiryDate}');
    print(
        'widget.mrzInfos.birthDate = ${widget.mrzInfos.secondLineInfo.birthDate}');
    dob = convertDateTimeToDateString(
        DateTime.parse(widget.mrzInfos.secondLineInfo.birthDate));

    doe = convertDateTimeToDateString(
        DateTime.parse(widget.mrzInfos.secondLineInfo.expiryDate));

    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _initPlatformState();

    // Update platform state every 3 sec
    // _timerStateUpdater = Timer.periodic(const Duration(seconds: 3), (Timer t) {
    //   _initPlatformState();
    // });
  }

  Future<void> _initPlatformState() async {
    // setState(() {
    //   _isReading = true;
    // });
    print('--------------');
    bool isNfcAvailable;
    try {
      NfcStatus status = await NfcProvider.nfcStatus;
      isNfcAvailable = status == NfcStatus.enabled;
    } on PlatformException {
      print('erroorrr');
      isNfcAvailable = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _isNfcAvailable = isNfcAvailable;
    setState(() {});
    if (_isNfcAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't access device NFC, please try again")));
    }
  }

  void _readMRTD() async {
    print('readddddd');
    try {
      setState(() {
        _mrtdData = null;
        _alertMessage = "Waiting for Document tag ...";
      });
      print('11111111');

      await _nfc.connect(
          iosAlertMessage: "Hold your phone near Biometric Document");
      print('22222222222');

      final passport = Passport(_nfc);

      setState(() {
        _alertMessage = "Reading Document ...";
      });
      print('3333333333');

      _nfc.setIosAlertMessage("Trying to read EF.CardAccess ...");
      final mrtdData = MrtdData();

      try {
        mrtdData.cardAccess = await passport.readEfCardAccess();
      } on PassportError {
        //if (e.code != StatusWord.fileNotFound) rethrow;
      }

      _nfc.setIosAlertMessage("Trying to read EF.CardSecurity ...");

      try {
        mrtdData.cardSecurity = await passport.readEfCardSecurity();
      } on PassportError {
        //if (e.code != StatusWord.fileNotFound) rethrow;
      }

      _nfc.setIosAlertMessage("Initiating session ...");
      final bacKeySeed = DBAKeys(docNumber!, _getDOBDate()!, _getDOEDate()!);
      await passport.startSession(bacKeySeed);

      _nfc.setIosAlertMessage(formatProgressMsg("Reading EF.COM ...", 0));
      mrtdData.com = await passport.readEfCOM();

      _nfc.setIosAlertMessage(formatProgressMsg("Reading Data Groups ...", 20));

      if (mrtdData.com!.dgTags.contains(EfDG1.TAG)) {
        mrtdData.dg1 = await passport.readEfDG1();
      }

      if (mrtdData.com!.dgTags.contains(EfDG2.TAG)) {
        mrtdData.dg2 = await passport.readEfDG2();
      }

      // To read DG3 and DG4 session has to be established with CVCA certificate (not supported).
      // if(mrtdData.com!.dgTags.contains(EfDG3.TAG)) {
      // mrtdData.dg3 = await passport.readEfDG3();
      // }

      // if(mrtdData.com!.dgTags.contains(EfDG4.TAG)) {
      // mrtdData.dg4 = await passport.readEfDG4();
      // }

      if (mrtdData.com!.dgTags.contains(EfDG5.TAG)) {
        mrtdData.dg5 = await passport.readEfDG5();
      }

      if (mrtdData.com!.dgTags.contains(EfDG6.TAG)) {
        mrtdData.dg6 = await passport.readEfDG6();
      }

      if (mrtdData.com!.dgTags.contains(EfDG7.TAG)) {
        mrtdData.dg7 = await passport.readEfDG7();

        String? imageHex = extractImageData(mrtdData.dg7!.toBytes().hex());

        Uint8List? decodeImageHex =
            Uint8List.fromList(List<int>.from(hex.decode(imageHex)));
        rawHandSignatureData = decodeImageHex;
      }

      // String? imageHex = extractImageData(handSign);

      // Uint8List? decodeImageHex =
      //     Uint8List.fromList(List<int>.from(hex.decode(imageHex)));
      // rawHandSignatureData = decodeImageHex;

      if (mrtdData.com!.dgTags.contains(EfDG8.TAG)) {
        mrtdData.dg8 = await passport.readEfDG8();
      }

      if (mrtdData.com!.dgTags.contains(EfDG9.TAG)) {
        mrtdData.dg9 = await passport.readEfDG9();
      }

      if (mrtdData.com!.dgTags.contains(EfDG10.TAG)) {
        mrtdData.dg10 = await passport.readEfDG10();
      }

      if (mrtdData.com!.dgTags.contains(EfDG11.TAG)) {
        mrtdData.dg11 = await passport.readEfDG11();
      }

      if (mrtdData.com!.dgTags.contains(EfDG12.TAG)) {
        mrtdData.dg12 = await passport.readEfDG12();
      }

      if (mrtdData.com!.dgTags.contains(EfDG13.TAG)) {
        mrtdData.dg13 = await passport.readEfDG13();
      }

      if (mrtdData.com!.dgTags.contains(EfDG14.TAG)) {
        mrtdData.dg14 = await passport.readEfDG14();
      }

      if (mrtdData.com!.dgTags.contains(EfDG15.TAG)) {
        mrtdData.dg15 = await passport.readEfDG15();
        _nfc.setIosAlertMessage(formatProgressMsg("Doing AA ...", 60));
        mrtdData.aaSig = await passport.activeAuthenticate(Uint8List(8));
      }

      if (mrtdData.com!.dgTags.contains(EfDG16.TAG)) {
        mrtdData.dg16 = await passport.readEfDG16();
      }

      _nfc.setIosAlertMessage(formatProgressMsg("Reading EF.SOD ...", 80));
      mrtdData.sod = await passport.readEfSOD();

      _mrtdData = mrtdData;

      _alertMessage = "";

      if (mrtdData.dg2?.imageData != null) {
        print('nooooott nullllllllllllllllllllllll');
        setState(() {
          rawImageData = mrtdData.dg2?.imageData;
        });
        tryDisplayingJpg();
        //await tryDisplayingJp2();
      }
      // _scrollController.animateTo(300.0,
      //     duration: const Duration(milliseconds: 500), curve: Curves.ease);

      setState(() {});
    } on Exception catch (e) {
      final se = e.toString().toLowerCase();
      String alertMsg = "An error has occurred while reading Document!";
      if (e is PassportError) {
        if (se.contains("security status not satisfied")) {
          alertMsg =
              "Failed to initiate session with passport.\nCheck input data!";
        }
        _log.error("PassportError: ${e.message}");
      } else {
        _log.error(
            "An exception was encountered while trying to read Document: $e");
      }

      if (se.contains('timeout')) {
        alertMsg = "Timeout while waiting for Document tag";
      } else if (se.contains("tag was lost")) {
        alertMsg = "Tag was lost. Please try again!";
      } else if (se.contains("invalidated by user")) {
        alertMsg = "";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(se)));

      setState(() {
        _alertMessage = alertMsg;
      });
    } finally {
      if (_alertMessage.isNotEmpty) {
        await _nfc.disconnect(iosErrorMessage: _alertMessage);
      } else {
        await _nfc.disconnect(
            iosAlertMessage: formatProgressMsg("Finished", 100));
      }

      setState(() {
        _isReading = false;
      });
    }
  }

  DateTime? _getDOBDate() {
    if (dob!.isEmpty) {
      return null;
    }

    return DateFormat.yMd().parse(dob!);
  }

  DateTime? _getDOEDate() {
    if (doe!.isEmpty) {
      return null;
    }
    return DateFormat.yMd().parse(doe!);
  }

  String extractImageData(String inputHex) {
    // Find the index of the first occurrence of 'FFD8'
    int startIndex = inputHex.indexOf('ffd8');
    // Find the index of the first occurrence of 'FFD9'
    int endIndex = inputHex.indexOf('ffd9');

    // If both 'FFD8' and 'FFD9' are found, extract the substring between them
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      String extractedImageData = inputHex.substring(
          startIndex, endIndex + 4); // Include 'FFD9' in the substring

      // Return the extracted image data
      return extractedImageData;
    } else {
      // 'FFD8' or 'FFD9' not found, handle accordingly (e.g., return an error or the original input)
      print("FFD8 and/or FFD9 markers not found in the input hex string.");
      return inputHex;
    }
  }

  Widget _makeMrtdDataWidget(
      {required String? header,
      required String collapsedText,
      required String? dataText}) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      title: Text(header ?? ""),
      onLongPress: () =>
          Clipboard.setData(ClipboardData(text: dataText ?? "Null")),
      subtitle: SelectableText(dataText ?? "Null", textAlign: TextAlign.left),
      trailing: IconButton(
        icon: const Icon(
          Icons.copy,
        ),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: dataText ?? "Null"));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Copied")));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 25,
                    color: Colors.black,
                  )),
              const Text(
                "NFC",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              const SizedBox(),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/passportscan.png",
                height: 150,
                fit: BoxFit.fitHeight,
              )
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          const Row(
            children: [
              Flexible(
                  child: Text(
                "Read passport with NFC",
                style: TextStyle(color: Colors.black, fontSize: 18),
              )),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          const Row(
            children: [
              Flexible(
                  child: Text(
                "Read your passport data by placing the passport at the back side of your phone , keep it placed until the authentication process with the passport's chip is finished and make sure the NFC option is enabled on your phone",
                style: TextStyle(color: Colors.black, fontSize: 13),
              )),
            ],
          ),
          const SizedBox(
            height: 40,
          ),
          Container(
              color: Colors.transparent,
              // borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  // _sendAuthData(authData); // changed
                  _initPlatformState();

                  _readMRTD();
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  height: 42,
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isReading
                          ? const Text("Reading...")
                          : const Text(
                              "Start NFC session",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                    ],
                  ),
                ),
              )),
          // // _buildPage(context),
          if (jpegImage != null || jp2000Image != null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Image",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),

          if (jpegImage != null)
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    jpegImage!,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
              ],
            ),

          if (jp2000Image != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      jp2000Image!,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    )),
              ],
            ),

          if (rawHandSignatureData != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text("Signature",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(
                  height: 10,
                ),
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      rawHandSignatureData!,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    )),
              ],
            ),

          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_mrtdData != null ? "NFC Scan Data:" : "",
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _mrtdDataWidgets())
                ]),
          ),
        ],
      ),
    );
  }

  List<Widget> _mrtdDataWidgets() {
    List<Widget> list = [];
    if (_mrtdData == null) return list;

    if (_mrtdData?.dg1 != null) {
      list.add(_makeMrtdDataWidget(
          header: null,
          collapsedText: '',
          dataText: formatMRZ(_mrtdData!.dg1!.mrz)));
    }
    return list;
  }

  Scaffold _buildPage(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('NFC Scan')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SingleChildScrollView(
              // controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Device NFC available:',
                            style: TextStyle(
                              fontSize: 18.0,
                            )),
                        const SizedBox(width: 4),
                        Text(_isNfcAvailable ? "Yes" : "No",
                            style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: _isNfcAvailable
                                    ? Colors.green
                                    : Colors.red))
                      ]),
                  const SizedBox(height: 40),
                  if (_isNfcAvailable && _isReading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CupertinoActivityIndicator(
                        color: Colors.black,
                        radius: 18,
                      ),
                    ),
                  if (_isNfcAvailable && !_isReading)
                    Center(
                        child: ColoredButton(
                      iconData: Icons.nfc_outlined,
                      // btn Read MRTD
                      onPressed: () {
                        _initPlatformState();

                        // Future.delayed(Duration(seconds: 2)).then((value) {
                        //   _readMRTD();
                        // });
                        _readMRTD();
                      },
                      child: const Text('Start Scan'),
                    )),
                  if (!_isNfcAvailable && !_isReading)
                    Center(
                        child: ColoredButton(
                      iconData: Icons.nfc_outlined,
                      // btn Read MRTD
                      onPressed: () {
                        _initPlatformState();
                      },
                      child: const Text('NFC Scan'),
                    )),
                  const SizedBox(height: 10),
                  Text(_alertMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),

                  // TextButton(
                  //   child: Text("Export as jp2"),
                  //   onPressed: () {
                  //     saveJp2();
                  //   },
                  // ),
                  // TextButton(
                  //   child: Text("Export as jpg"),
                  //   onPressed: () {
                  //     saveJpeg();
                  //   },
                  // ),
                  // TextButton(
                  //   child: Text("Try Jpg"),
                  //   onPressed: () {
                  //     tryDisplayingJpg();
                  //   },
                  // ),

                  if (rawImageData != null)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Image",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),

                  if (jpegImage != null)
                    Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            jpegImage!,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(),
                          ),
                        ),
                      ],
                    ),

                  if (jp2000Image != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              jp2000Image!,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(),
                            )),
                      ],
                    ),

                  if (rawHandSignatureData != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        const Text("Signature",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(
                          height: 10,
                        ),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              rawHandSignatureData!,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(),
                            )),
                      ],
                    ),

                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_mrtdData != null ? "NFC Scan Data:" : "",
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontSize: 15.0, fontWeight: FontWeight.bold)),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _mrtdDataWidgets())
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void tryDisplayingJpg() {
    print('rawImageDatarawImageDatarawImageData $rawImageData');
    try {
      setState(() {
        jpegImage = rawImageData;
      });
    } catch (e) {
      print('error in trying displayyyyyy $e');
      jpegImage = null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Image is not in jpg format, trying jpeg2000")));
    }
  }

  void tryDisplayingJp2() async {
    try {
      jp2000Image = await decodeImage(rawImageData!, context);
      setState(() {});
    } catch (e) {
      jpegImage = null;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image is not in jpeg2000")));
    }
  }

  Future<void> _sendAuthData(List<String> authData) async {
    const platform = MethodChannel('com.securepass.auth');
    authData.clear();
    authData.add(widget.mrzInfos.secondLineInfo.passportNumber);
    authData.add(widget.mrzInfos.secondLineInfo.birthDate);
    authData.add(widget.mrzInfos.secondLineInfo.expiryDate);
    try {
      await platform.invokeMethod('getAuthData', {"authData": authData});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e.message);
      }
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance
  //       .addPostFrameCallback((_) => key.currentState?.showBottomSheet(
  //             (context) => const Text('Okkk'),
  //           ));
  // }
}

// showSnackBar(SnackBar(
//               content: Text(
//                 'MRZ has been successfully scanned',
//                 style: TextStyle(color: Colors.white, fontSize: 14),
//               ),
//               backgroundColor: Colors.green,
//             )))

// ignore: must_be_immutable
