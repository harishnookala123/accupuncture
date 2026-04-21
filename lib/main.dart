import 'package:acupuncture/service.dart';
import 'package:acupuncture/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyCR2OTCpiZWRblPW1F4Io07uQ_zX-REPXQ",
        appId: "1:590657511533:android:ef388cbac2dc93805a9f64",
        messagingSenderId: "590657511533",
        projectId: "tracking-d20f9"),
  );
  await NotificationService().initialize();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your  application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: SplashScreen()
    );
  }
}


