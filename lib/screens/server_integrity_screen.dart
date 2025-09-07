import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/wallpaper_background.dart';

class ServerIntegrityScreen extends StatefulWidget {
  const ServerIntegrityScreen({super.key});

  @override
  State<ServerIntegrityScreen> createState() => _ServerIntegrityScreenState();
}

class _ServerIntegrityScreenState extends State<ServerIntegrityScreen> {
  bool _todayRosterOnly = true;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    
    final servers = _todayRosterOnly
        ? app.workingServerIds.map((id) => app.serverById(id)).whereType<Server>().toList()
        : app.servers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Integrity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade600.withOpacity(0.8),
                Colors.lightBlue.shade400.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ),
      body: WallpaperBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              // Description Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.lightBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.security, color: Colors.lightBlue.shade700),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Click Rate Monitoring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen shows how many times each server clicked within a minute. Multiple rapid clicks can indicate potential issues or system behavior.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Filter Switch
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.9),
                  border: Border.all(
                    color: Colors.lightBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    "Today's roster only",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _todayRosterOnly 
                        ? 'Showing only servers working today'
                        : 'Showing all servers',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  value: _todayRosterOnly,
                  onChanged: (v) => setState(() => _todayRosterOnly = v),
                  activeColor: Colors.lightBlue,
                  activeTrackColor: Colors.lightBlue.withOpacity(0.3),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Data Table
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(
                      color: Colors.lightBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.lightBlue.shade400.withOpacity(0.8),
                              Colors.lightBlue.shade600.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: const _HeaderRow(),
                      ),
                      
                      // Data Rows
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: servers.length,
                          itemBuilder: (context, index) {
                            final server = servers[index];
                            final bins = app.integrityBinsFor(server.id, todayOnly: _todayRosterOnly);
                            final runCount = app.currentCounts[server.id] ?? 0;
                            return _DataRow(
                              name: server.name,
                              bins: bins,
                              runCount: runCount,
                              isEven: index % 2 == 0,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 3, child: Text(
          'Server',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        )),
        Expanded(flex: 2, child: Text(
          'Runs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        )),
        Expanded(flex: 2, child: Text(
          'Singles/min',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        )),
        Expanded(flex: 2, child: Text(
          'Doubles/min',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        )),
        Expanded(flex: 2, child: Text(
          'Triples/min',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        )),
        Expanded(flex: 2, child: Text(
          '4+/min',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        )),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String name;
  final Map<String, int> bins;
  final int runCount;
  final bool isEven;

  const _DataRow({
    required this.name,
    required this.bins,
    required this.runCount,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isEven 
            ? Colors.lightBlue.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$runCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${bins['1'] ?? 0}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${bins['2'] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: (bins['2'] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                color: (bins['2'] ?? 0) > 0 ? Colors.orange.shade700 : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${bins['3'] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: (bins['3'] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                color: (bins['3'] ?? 0) > 0 ? Colors.red.shade600 : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${bins['4+'] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: (bins['4+'] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                color: (bins['4+'] ?? 0) > 0 ? Colors.red.shade800 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
