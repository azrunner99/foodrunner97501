import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../app_state.dart';
import 'station_types_screen.dart';

class UpdateRosterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Active Roster'),
      ),
      body: _RosterBody(app: app),
    );
  }
}

class _RosterBody extends StatefulWidget {
  final AppState app;
  const _RosterBody({required this.app});

  @override
  State<_RosterBody> createState() => _RosterBodyState();
}

class _RosterBodyState extends State<_RosterBody> {
  bool showTeams = false;
  final List<String?> teamColorOptions = const [
    'Blue',
    'Purple',
    'Silver',
    null,
  ];
  bool isLunch = true; // true = Lunch, false = Dinner
  late List<String> lunchRoster;
  late List<String> dinnerRoster;
  late Map<String, String?> teamColors;

  // Station assignment state
  Map<String, String?> serverStationType = {};
  Map<String, String?> serverStationSection = {};
  List<StationType> stationTypes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load station types from StationTypesScreen's storage
    _loadStationTypes();
  }

  Future<void> _loadStationTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('station_types');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      setState(() {
        stationTypes = decoded.map((e) => StationType.fromJson(e)).cast<StationType>().toList();
      });
    }
  }

  Future<String?> _showStationTypeDialog(BuildContext context) async {
    // Always reload station types before showing dialog
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('station_types');
    List<StationType> types = [];
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      types = decoded.map((e) => StationType.fromJson(e)).cast<StationType>().toList();
    }
    if (types.isEmpty) {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('No station types configured'),
          content: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Please add station types in Manage Stations.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    // Get the server name from ModalRoute arguments if available
    String serverName = 'Assign Station Type';
    if (ModalRoute.of(context)?.settings.arguments is String) {
      serverName = ModalRoute.of(context)!.settings.arguments as String;
    }
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(serverName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: types.map((type) => SizedBox(
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.pop(context, type.name),
                      child: Text(type.name),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    final todayPlan = widget.app.todayPlan;
    lunchRoster = todayPlan?.lunchRoster.toList() ?? [];
    dinnerRoster = todayPlan?.dinnerRoster.toList() ?? [];
    teamColors = {
      for (var s in widget.app.servers) s.id: s.teamColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final servers = widget.app.servers;
    final teamToggle = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
          value: showTeams,
          onChanged: (v) => setState(() => showTeams = v),
        ),
        const SizedBox(width: 8),
        const Text('Assign Teams', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );

    void saveRoster() {
      for (var s in widget.app.servers) {
        s.teamColor = teamColors[s.id];
      }
      widget.app.setTodayPlan(lunchRoster, dinnerRoster);
      // --- Ensure the active roster is updated immediately ---
      final now = DateTime.now();
      final intended = widget.app.currentIntendedShiftType(now);
      if (intended == 'Lunch') {
        widget.app.updateActiveRoster(lunchRoster);
      } else {
        widget.app.updateActiveRoster(dinnerRoster);
      }
      // -------------------------------------------------------
    }

    return WillPopScope(
      onWillPop: () async {
        saveRoster();
        return true;
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            teamToggle,
            // Toggle Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => isLunch = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLunch ? Colors.blue : Colors.grey[300],
                    foregroundColor: isLunch ? Colors.white : Colors.black,
                  ),
                  child: const Text('Lunch'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => isLunch = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isLunch ? Colors.blue : Colors.grey[300],
                    foregroundColor: !isLunch ? Colors.white : Colors.black,
                  ),
                  child: const Text('Dinner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isLunch)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear All Lunch'),
                    onPressed: () {
                      setState(() {
                        lunchRoster.clear();
                      });
                    },
                  ),
                if (!isLunch)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear All Dinner'),
                    onPressed: () {
                      setState(() {
                        dinnerRoster.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: servers.length,
                itemBuilder: (ctx, i) {
                  final s = servers[i];
                  final roster = isLunch ? lunchRoster : dinnerRoster;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Name and section display with clickable bubble
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                // Only allow reassignment if already assigned
                                final selectedTypeName = await _showStationTypeDialog(context);
                                if (selectedTypeName != null) {
                                  final selectedType = stationTypes.firstWhere((t) => t.name == selectedTypeName);
                                  final selectedSection = await showDialog<String>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (sectionContext) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                s.name,
                                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(selectedType.name, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                                              const SizedBox(height: 24),
                                              Wrap(
                                                spacing: 16,
                                                runSpacing: 16,
                                                alignment: WrapAlignment.center,
                                                children: List.generate(selectedType.sections, (i) {
                                                  final sectionLabel = '${selectedType.abbreviation} ${i + 1}';
                                                  return SizedBox(
                                                    width: 120,
                                                    height: 44,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                                        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                        elevation: 1,
                                                      ),
                                                      onPressed: () => Navigator.pop(sectionContext, sectionLabel),
                                                      child: Text(sectionLabel),
                                                    ),
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 12),
                                              TextButton(
                                                onPressed: () => Navigator.pop(sectionContext),
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  if (selectedSection != null) {
                                    setState(() {
                                      serverStationType[s.id] = selectedTypeName;
                                      serverStationSection[s.id] = selectedSection;
                                    });
                                  }
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: roster.contains(s.id) ? 22 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (serverStationSection[s.id] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade400),
                                        ),
                                        child: Text(
                                          serverStationSection[s.id]!,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Checkbox(
                            value: roster.contains(s.id),
                            onChanged: (v) async {
                              if (v == true) {
                                final selectedTypeName = await _showStationTypeDialog(
                                  context,
                                  // Pass the server name as a route argument
                                );
                                if (selectedTypeName != null) {
                                  final selectedType = stationTypes.firstWhere((t) => t.name == selectedTypeName);
                                  final selectedSection = await showDialog<String>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (sectionContext) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                s.name,
                                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(selectedType.name, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                                              const SizedBox(height: 24),
                                              Wrap(
                                                spacing: 16,
                                                runSpacing: 16,
                                                alignment: WrapAlignment.center,
                                                children: List.generate(selectedType.sections, (i) {
                                                  final sectionLabel = '${selectedType.abbreviation} ${i + 1}';
                                                  return SizedBox(
                                                    width: 120,
                                                    height: 44,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                                        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                        elevation: 1,
                                                      ),
                                                      onPressed: () => Navigator.pop(sectionContext, sectionLabel),
                                                      child: Text(sectionLabel),
                                                    ),
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 12),
                                              TextButton(
                                                onPressed: () => Navigator.pop(sectionContext),
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  if (selectedSection != null) {
                                    setState(() {
                                      serverStationType[s.id] = selectedTypeName;
                                      serverStationSection[s.id] = selectedSection;
                                      final currentRoster = isLunch ? lunchRoster : dinnerRoster;
                                      if (!currentRoster.contains(s.id)) {
                                        currentRoster.add(s.id);
                                      }
                                    });
                                  }
                                }
                              } else {
                                setState(() {
                                  roster.remove(s.id);
                                  serverStationType.remove(s.id);
                                  serverStationSection.remove(s.id);
                                });
                              }
                            },
                          ),
                          if (showTeams)
                            DropdownButton<String?>(
                              value: teamColors[s.id],
                              hint: const Text('Team'),
                              items: teamColorOptions
                                  .map(
                                    (color) => DropdownMenuItem<String?>(
                                      value: color,
                                      child: Text(color ?? 'None'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  teamColors[s.id] = val;
                                  s.teamColor = val;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}