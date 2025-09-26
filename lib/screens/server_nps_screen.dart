import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../widgets/enhanced_nps_analytics_widget.dart';
import '../widgets/monthly_nps_data_entry_widget.dart';
import '../widgets/impact_analytics_widget.dart';
import '../widgets/server_nps_status_widget.dart';
import '../widgets/individual_server_nps_trend_widget.dart';
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
      length: 4, // Updated to 4 tabs (removed Monthly NPS Data Entry)
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100.0), // Increased height for two-line text
            child: TabBar(
              tabs: [
              const Tab(icon: Icon(Icons.dashboard), text: 'Analytics'),
              const Tab(icon: Icon(Icons.trending_up), text: 'IMPACT'),
              const Tab(icon: Icon(Icons.person), text: 'Server NPS Status'),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 18),
                    const SizedBox(height: 1),
                    Text(
                      'Individual Server\nNPS Trend',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
              labelColor: Colors.orange.shade800,
              unselectedLabelColor: Colors.orange.shade400,
              indicatorColor: Colors.orange.shade600,
            ),
          ),
        ),
        body: Column(
          children: [
            // Monthly NPS Data Entry - Prominent Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly NPS Data Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter monthly NPS reports for all servers',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Monthly NPS Data Entry
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonthlyNPSDataEntryWidget(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      label: const Text(
                        'Enter Monthly Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Content Area
            Expanded(
              child: TabBarView(
                children: [
                  const EnhancedNPSAnalyticsWidget(),
                  const ImpactAnalyticsWidget(),
                  const ServerNPSStatusWidget(),
                  const IndividualServerNPSTrendWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
