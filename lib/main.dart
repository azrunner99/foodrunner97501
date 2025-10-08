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
import 'services/server_id_resolver.dart';
import 'services/database_sync_service.dart';
import 'services/server_data_service.dart';
import 'storage/nps_database_adapter.dart';
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
  await Storage.migrateRawKeys(); // Migrate any existing raw SharedPreferences keys
  
  // Initialize database factory for cross-platform database support
  await DatabaseFactory.initialize();
  
  final appState = AppState();
  await appState.load();

  // Initialize NPS services
  final npsProvider = NPSProvider();

  // Initialize NPSProvider with AppState to sync servers
  await npsProvider.initialize(appState: appState);

  // ⭐ Phase 1.1: Initialize ServerIdResolver globally
  // This ensures consistent server ID resolution across all widgets
  final npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
  try {
    await ServerIdResolver.instance.initialize(appState, npsAdapter);
    final serverCount = ServerIdResolver.instance.getAllCanonicalIds().length;
    print('✅ [Phase 1.1] ServerIdResolver initialized with $serverCount servers');
    
    // Print detailed mapping info for debugging
    if (serverCount > 0) {
      print('   Server mappings established for: ${ServerIdResolver.instance.getAllCanonicalIds().take(5).join(", ")}${serverCount > 5 ? "..." : ""}');
    }
  } catch (e, stackTrace) {
    print('❌ [Phase 1.1] ServerIdResolver initialization failed: $e');
    print('   Stack trace: $stackTrace');
    // Continue anyway - app should still work without it, just less reliably
  }

  // ⭐ Phase 1.2: Initialize DatabaseSyncService
  // This service handles automatic server synchronization between storage systems
  try {
    await DatabaseSyncService.instance.initialize();
    print('✅ [Phase 1.2] DatabaseSyncService initialized');
    
    // Verify sync status on startup
    final syncStatus = await DatabaseSyncService.instance.verifySyncStatus(appState);
    print('   Sync status: ${syncStatus['serversInSync']}/${syncStatus['appServerCount']} servers in sync (${(syncStatus['syncPercentage'] as double).toStringAsFixed(1)}%)');
    
    // Auto-fix any sync issues on startup
    if (!syncStatus['isSynced']) {
      print('   ⚠️ Servers out of sync, auto-fixing...');
      final fixResult = await DatabaseSyncService.instance.autoFixSyncIssues(appState);
      print('   ✅ Applied ${fixResult['fixCount']} fixes');
    }
  } catch (e, stackTrace) {
    print('❌ [Phase 1.2] DatabaseSyncService initialization failed: $e');
    print('   Stack trace: $stackTrace');
    // Continue anyway - manual sync will still be available
  }

  // ⭐ Phase 1.3: Initialize ServerDataService
  // This provides a unified API for accessing server data from any source
  try {
    ServerDataService.instance.initialize(appState);
    final serverCounts = await ServerDataService.instance.getServerCountBySource();
    print('✅ [Phase 1.3] ServerDataService initialized');
    print('   Servers available: ${serverCounts['total']} (AppState: ${serverCounts['appState']}, NPS: ${serverCounts['npsDatabase']})');
  } catch (e, stackTrace) {
    print('❌ [Phase 1.3] ServerDataService initialization failed: $e');
    print('   Stack trace: $stackTrace');
    // Continue anyway - widgets can still access data directly
  }

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
        '/performance': (_) => const ServerPerformanceScreen(),
        '/business_data_entry': (_) => const BusinessDataEntryScreen(),
        '/server_nps': (_) => const ServerNPSScreen(),
      },
    );
  }
}
