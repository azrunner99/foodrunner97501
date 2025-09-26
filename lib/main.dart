import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'app_state.dart';
import 'providers/nps_provider.dart';
import 'storage/database_factory.dart';
import 'services/nps_filter_service.dart';
import 'services/nps_notification_service.dart';
import 'services/nps_benchmarking_service.dart';
import 'services/nps_security_service.dart';
import 'services/nps_encryption_service.dart';
import 'services/nps_audit_service.dart';
import 'services/nps_gdpr_compliance_service.dart';
import 'services/performance_flags.dart';
import 'services/performance_monitoring_service.dart';
import 'services/performance_rollout_service.dart';
import 'services/historical_nps_aggregation_service.dart';
import 'services/performance_timeline_service.dart';
import 'services/historical_data_validation_service.dart';
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
import 'screens/server_performance_screen_working.dart';
import 'screens/business_data_entry_screen.dart';
import 'screens/server_nps_screen.dart';
import 'screens/historical_nps_analytics_screen.dart';
import 'package:food_runs_counter/services/enhanced_error_handling_service.dart';
import 'package:food_runs_counter/services/data_consistency_service.dart';
import 'package:food_runs_counter/services/fallback_mechanisms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Storage.migrateRawKeys(); // Migrate any existing raw SharedPreferences keys
  
  // Initialize database factory for cross-platform database support
  await DatabaseFactory.initialize();
  
  // Initialize Performance Flags for Phase 1 rollout
  await PerformanceFlags.initialize();
  
  // Enable Phase 1: Data Hygiene & Safeguards for testing
  await PerformanceFlags.enablePhase(1);
  
  // Enable Phase 2: Baseline & Fallback Reform
  await PerformanceFlags.enablePhase(2);
  
  // Enable Phase 3: Differentiation Mechanics
  await PerformanceFlags.enablePhase(3);
  
  // Enable Phase 4: Temporal Derivation Layer
  await PerformanceFlags.enablePhase(4);
  
  // Enable Phase 5: Adaptive Weighting & Confidence
  await PerformanceFlags.enablePhase(5);
  
  // Enable Phase 6: Monitoring & Telemetry
  await PerformanceFlags.enablePhase(6);
  
  // Enable Phase 7: Rollout & Reconciliation
  await PerformanceFlags.enablePhase(7);
  
  // Initialize Performance Monitoring Service
  await PerformanceMonitoringService.instance.initialize();
  
  // Initialize Performance Rollout Service
  await PerformanceRolloutService().initialize();
  
  // Initialize Phase 1: Historical Data Services
  await HistoricalNPSAggregationService.instance.initialize();
  await PerformanceTimelineService.instance.initialize();
  await HistoricalDataValidationService.instance.initialize();
  
  // Initialize Enhanced Error Handling Service
  await EnhancedErrorHandlingService.instance.handleError(
    'app_startup',
    'Application starting up',
    context: 'Main',
    severity: ErrorSeverity.low,
    showToUser: false,
  );
  
  // Initialize Data Consistency Service
  await DataConsistencyService.instance.initialize();
  
  // Initialize Fallback Mechanisms Service
  await FallbackMechanismsService.instance.initialize();
  
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
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      routes: {
        '/': (_) =>
            const HomeScreen(), // Restored: Normal home screen as default
        '/home': (_) =>
            const HomeScreen(), // Actual home screen for back navigation
        '/admin': (_) => const CleanAdminScreen(),
        '/assign': (_) => AssignServersScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profiles': (_) => const ProfilesScreen(),
        '/history': (_) => const HistoryScreen(),
        '/mvp': (_) => const MvpScreen(),
        '/manage': (_) => const ManageServersScreen(),
        '/stations': (_) => const StationTypesScreen(),
        '/gamification_options': (_) => const GamificationOptionsScreen(),
        '/performance': (_) => ServerPerformanceScreenWorking(),
        '/business_data_entry': (_) => const BusinessDataEntryScreen(),
        '/server_nps': (_) => const ServerNPSScreen(),
        '/historical_analytics': (_) => HistoricalNPSAnalyticsScreen(),
      },
    );
  }
}
