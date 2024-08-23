import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scan/Home.dart';
import 'package:scan/exceptionView.dart';
import 'package:scan/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;
late SharedPreferences sharedPreference;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  cameras = await availableCameras();
  sharedPreference = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Securepass',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          '/': (context) => const Home(),
          '/result': (context) => const Result(),
          '/exceptionView': (context) => const ExceptionView(),
        }
        );
  }
}