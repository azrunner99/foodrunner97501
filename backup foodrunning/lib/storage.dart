import 'package:hive_flutter/hive_flutter.dart';

class Boxes {
  static const servers  = 'servers_box';   // List<Map>
  static const shifts   = 'shifts_box';    // List<Map>
  static const totals   = 'totals_box';    // Map<String,int>
  static const profiles = 'profiles_box';  // Map<serverId, Map>
  static const settings = 'settings_box';  // Map<String,dynamic>
}

class Storage {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(Boxes.servers);
    await Hive.openBox(Boxes.shifts);
    await Hive.openBox(Boxes.totals);
    await Hive.openBox(Boxes.profiles);
    await Hive.openBox(Boxes.settings);
  }

  static Box get serversBox  => Hive.box(Boxes.servers);
  static Box get shiftsBox   => Hive.box(Boxes.shifts);
  static Box get totalsBox   => Hive.box(Boxes.totals);
  static Box get profilesBox => Hive.box(Boxes.profiles);
  static Box get settingsBox => Hive.box(Boxes.settings);
}
