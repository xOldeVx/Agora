import 'package:shared_preferences/shared_preferences.dart';

class Sp {
  static SharedPreferences sharedPref;
  static Future init() async {
    sharedPref = await SharedPreferences.getInstance();
  }
}
