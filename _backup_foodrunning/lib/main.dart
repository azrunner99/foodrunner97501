import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/start_shift_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profiles_screen.dart';

// BJ’s primary red
const _bjsRed = Color(0xFFBD3326);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final appState = AppState();
  await appState.load();
  runApp(FoodRunsApp(appState: appState));
}

class FoodRunsApp extends StatelessWidget {
  final AppState appState;
  const FoodRunsApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: "Food Runs",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _bjsRed,
            primary: _bjsRed,
            onPrimary: Colors.white,
            secondary: const Color(0xFF333333),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: _bjsRed,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: _bjsRed,
            foregroundColor: Colors.white,
          ),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const HomeScreen(),
          '/start_shift': (_) => const StartShiftScreen(),
          '/history': (_) => const HistoryScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/profiles': (_) => const ProfilesScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
