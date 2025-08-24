import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class _Box {
  final String prefix;
  _Box(this.prefix);

  Future<dynamic> get(String key) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$prefix::$key');
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> put(String key, dynamic value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$prefix::$key', jsonEncode(value));
  }

  Future<void> delete(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$prefix::$key');
  }
}

class Storage {
  static late _Box serversBox;
  static late _Box totalsBox;
  static late _Box shiftsBox;
  static late _Box profilesBox;
  static late _Box settingsBox;
  static late _Box dayPlanBox;
  static late _Box tapBox; // per-minute tap buckets

  static Future<void> init() async {
    serversBox = _Box('servers');
    totalsBox = _Box('totals');
    shiftsBox = _Box('shifts');
    profilesBox = _Box('profiles');
    settingsBox = _Box('settings');
    dayPlanBox = _Box('dayplan');
    tapBox = _Box('taplog');
  }
}
