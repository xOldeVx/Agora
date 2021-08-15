import 'dart:convert';

import 'package:Goomtok/utils/sp.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';
import 'screen/home.dart';
import 'screen/loginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Sp.init();
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   statusBarColor: Color(0xFFb7891),
  //   systemNavigationBarColor: const Color(0xFFb7891),
  // ));
  // final prefs = await SharedPreferences.getInstance();
  // final bool loggedIn = prefs.getBool('login') ?? false;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {

  final MaterialColor blackColor = const MaterialColor(
    0xFF000000,
    const <int, Color>{
      50: const Color(0xFF000000),
      100: const Color(0xFF000000),
      200: const Color(0xFF000000),
      300: const Color(0xFF000000),
      400: const Color(0xFF000000),
      500: const Color(0xFF000000),
      600: const Color(0xFF000000),
      700: const Color(0xFF000000),
      800: const Color(0xFF000000),
      900: const Color(0xFF000000),
    },
  );

  @override
  Widget build(BuildContext context) {
    final User user = Sp.sharedPref.getString('user') != null ? User.fromJson(jsonDecode(Sp.sharedPref.getString('user'))) : null;
    return MaterialApp(
      title: 'Goomtok',
      // color: blackColor,
      theme: ThemeData(
        primaryColorDark: const Color(0xFFb7891),
        primaryColor: const Color(0xFFbaa2c2),
        accentColor: const Color(0xFF937fb6),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        iconTheme: IconThemeData(color: Colors.black),
        primaryIconTheme: IconThemeData(color: Colors.black),
        fontFamily: 'Gotham',
        textTheme: TextTheme(
          bodyText2: TextStyle(fontSize: 14.0, color: Colors.black), // Text()
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: Colors.black),
          headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic, color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColorDark: const Color(0xFF0F1D24),
        primaryColor: const Color(0xFF222D36),
        // accentColor: const Color(0xFF937fb6),
        scaffoldBackgroundColor: const Color(0xFF101D2),
        iconTheme: IconThemeData(color: Colors.white),
        primaryIconTheme: IconThemeData(color: Colors.white),
        fontFamily: 'Gotham',
        textTheme: TextTheme(
          bodyText2: TextStyle(fontSize: 14.0, color: Colors.white), // Text()
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: Colors.white),
          headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic, color: Colors.white),
        ),
      ),
      home: user != null ? HomePage(user) : LoginScreen(),
      showSemanticsDebugger: false,
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      routes: <String, WidgetBuilder>{'/HomeScreen': (BuildContext context) => MyApp()},
    );
  }
}
