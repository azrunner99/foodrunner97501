import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../widgets/enhanced_nps_analytics_widget.dart';
import '../widgets/monthly_nps_data_entry_widget.dart';
import '../widgets/impact_analytics_widget.dart';
import '../widgets/server_nps_status_widget.dart';
import '../app_state.dart';

class ServerNPSScreen extends StatefulWidget {
  const ServerNPSScreen({super.key});

  @override
  State<ServerNPSScreen> createState() => _ServerNPSScreenState();
}

class _ServerNPSScreenState extends State<ServerNPSScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the NPS Provider when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      context.read<NPSProvider>().initialize(appState: appState);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Updated to 4 tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Server NPS Tracking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.orange.shade50,
          foregroundColor: Colors.orange.shade800,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Analytics'),
              Tab(icon: Icon(Icons.trending_up), text: 'IMPACT'),
              Tab(icon: Icon(Icons.person), text: 'Server NPS Status'),
              Tab(
                  icon: Icon(Icons.calendar_month),
                  text: 'Monthly NPS Data Entry'),
            ],
            labelColor: Colors.orange.shade800,
            unselectedLabelColor: Colors.orange.shade400,
            indicatorColor: Colors.orange.shade600,
          ),
        ),
        body: TabBarView(
          children: [
            const EnhancedNPSAnalyticsWidget(),
            const ImpactAnalyticsWidget(),
            const ServerNPSStatusWidget(),
            MonthlyNPSDataEntryWidget(),
          ],
        ),
      ),
    );
  }
}
