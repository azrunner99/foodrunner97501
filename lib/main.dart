import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/assign_servers_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profiles_screen.dart';
import 'screens/history_screen.dart';
import 'screens/mvp_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/manage_servers_screen.dart';
import 'screens/station_types_screen.dart';
import 'screens/gamification_options_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final appState = AppState();
  await appState.load();
  runApp(ChangeNotifierProvider(
    create: (_) => appState,
    child: const FoodRunsApp(),
  ));
}

class FoodRunsApp extends StatelessWidget {
  const FoodRunsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF7A0019); // BJ's maroon-ish vibe
    return MaterialApp(
      title: "BJ's Food Runs",
      theme: ThemeData(
        colorSchemeSeed: color,
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/assign': (_) => AssignServersScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profiles': (_) => const ProfilesScreen(),
        '/history': (_) => const HistoryScreen(),
        '/mvp': (_) => const MvpScreen(),
        '/admin': (_) => const AdminScreen(),
        '/manage': (_) => const ManageServersScreen(),
        '/stations': (_) => const StationTypesScreen(),
        '/gamification_options': (_) => const GamificationOptionsScreen(),
      },
    );
  }
}
