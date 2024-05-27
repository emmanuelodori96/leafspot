import 'package:diagno/pages/home_page.dart';
import 'package:diagno/pages/onboarding_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/data_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate();
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key});
  final DataController dataController = Get.put(DataController());

  @override
  Widget build(BuildContext context) {
    return Obx(() =>  GetMaterialApp(
      title: 'Diagnostic',
      debugShowCheckedModeBanner: false,
      theme: dataController.isDarkMode.value ? ThemeData.dark() : ThemeData.light(),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              // User is logged in, navigate to home page
              return const HomePage(title: 'Diagno vision');
            } else {
              // User is not logged in, navigate to welcome screen
              return const OnBoardingScreen();
            }
          }
        },
      ),
    ));
  }
}


