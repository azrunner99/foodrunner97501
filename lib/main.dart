import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'app_state.dart';
import 'providers/nps_provider.dart';
import 'services/nps_filter_service.dart';
import 'services/nps_notification_service.dart';
import 'services/nps_benchmarking_service.dart';
import 'services/nps_security_service.dart';
import 'services/nps_encryption_service.dart';
import 'services/nps_audit_service.dart';
import 'services/nps_gdpr_compliance_service.dart';
import 'screens/home_screen.dart';
import 'screens/assign_servers_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profiles_screen.dart';
import 'screens/history_screen.dart';
import 'screens/mvp_screen.dart';
import 'screens/clean_admin_screen.dart';
import 'screens/manage_servers_screen.dart';
import 'screens/station_types_screen.dart';
import 'screens/gamification_options_screen.dart';
import 'screens/server_performance_screen.dart';
import 'screens/business_data_entry_screen.dart';
import 'screens/server_nps_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final appState = AppState();
  await appState.load();
  
  // Initialize NPS services
  final npsProvider = NPSProvider();
  
  // Initialize NPSProvider with AppState to sync servers
  await npsProvider.initialize(appState: appState);
  
  final npsFilterService = NPSFilterService();
  final npsBenchmarkingService = NPSBenchmarkingService();
  
  // Initialize security services
  final npsSecurityService = NPSSecurityService();
  final npsEncryptionService = NPSEncryptionService();
  final npsAuditService = NPSAuditService();
  final npsGDPRService = NPSGDPRComplianceService();
  
  // Initialize all services
  await npsBenchmarkingService.initialize();
  npsSecurityService.initialize();
  npsEncryptionService.initialize();
  npsAuditService.initialize();
  npsGDPRService.initialize();
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => appState),
      ChangeNotifierProvider(create: (_) => npsProvider),
      ChangeNotifierProvider(create: (_) => npsFilterService),
      ChangeNotifierProvider(create: (_) => npsBenchmarkingService),
      ChangeNotifierProvider(create: (_) => npsSecurityService),
      ChangeNotifierProvider(create: (_) => npsEncryptionService),
      ChangeNotifierProvider(create: (_) => npsAuditService),
      ChangeNotifierProvider(create: (_) => npsGDPRService),
      Provider<NPSNotificationService>(create: (_) => NPSNotificationService()),
    ],
    child: const FoodRunsApp(),
  ));
}

class FoodRunsApp extends StatelessWidget {
  const FoodRunsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF00B4D8); // Vibrant light blue
    return MaterialApp(
      title: "BJ's Food Runs",
      theme: ThemeData(
        colorSchemeSeed: color,
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      routes: {
        '/': (_) => const HomeScreen(), // Restored: Normal home screen as default
        '/home': (_) => const HomeScreen(), // Actual home screen for back navigation
        '/admin': (_) => const CleanAdminScreen(),
        '/assign': (_) => AssignServersScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profiles': (_) => const ProfilesScreen(),
        '/history': (_) => const HistoryScreen(),
        '/mvp': (_) => const MvpScreen(),
        '/manage': (_) => const ManageServersScreen(),
        '/stations': (_) => const StationTypesScreen(),
        '/gamification_options': (_) => const GamificationOptionsScreen(),
        '/performance': (_) => const ServerPerformanceScreen(),
        '/business_data_entry': (_) => const BusinessDataEntryScreen(),
        '/server_nps': (_) => const ServerNPSScreen(),
      },
    );
  }
}
