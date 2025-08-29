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
  List<String> lunchRoster = [];
  List<String> dinnerRoster = [];
  Map<String, String?> lunchTeamColors = {};
  Map<String, String?> dinnerTeamColors = {};

  // Station assignment state (separate for lunch/dinner)
  Map<String, String?> lunchStationType = {};
  Map<String, String?> dinnerStationType = {};
  Map<String, String?> lunchStationSection = {};
  Map<String, String?> dinnerStationSection = {};
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

    // Restore team colors from AppState servers if available
    lunchTeamColors = { for (var s in widget.app.servers) s.id: s.teamColor };
    dinnerTeamColors = { for (var s in widget.app.servers) s.id: s.teamColor };

    // Restore station assignments from SharedPreferences
    _restoreStationAssignments();

    // Set showTeams toggle if any team color is assigned for current shift
    final anyLunchTeam = lunchTeamColors.values.any((c) => c != null);
    final anyDinnerTeam = dinnerTeamColors.values.any((c) => c != null);
    showTeams = isLunch ? anyLunchTeam : anyDinnerTeam;
  }

  Future<void> _restoreStationAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final lunchTypeJson = prefs.getString('lunchStationType');
    final dinnerTypeJson = prefs.getString('dinnerStationType');
    final lunchSectionJson = prefs.getString('lunchStationSection');
    final dinnerSectionJson = prefs.getString('dinnerStationSection');
    setState(() {
      lunchStationType = lunchTypeJson != null ? Map<String, String?>.from(json.decode(lunchTypeJson)) : {};
      dinnerStationType = dinnerTypeJson != null ? Map<String, String?>.from(json.decode(dinnerTypeJson)) : {};
      lunchStationSection = lunchSectionJson != null ? Map<String, String?>.from(json.decode(lunchSectionJson)) : {};
      dinnerStationSection = dinnerSectionJson != null ? Map<String, String?>.from(json.decode(dinnerSectionJson)) : {};
    });
  }

  @override
  Widget build(BuildContext context) {
  // final servers = widget.app.servers; // No longer needed
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

    void saveRoster() async {
      // Optionally persist team colors and station assignments if needed
      widget.app.setTodayPlan(lunchRoster, dinnerRoster);

      // Persist station assignments to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lunchStationType', json.encode(lunchStationType));
      await prefs.setString('dinnerStationType', json.encode(dinnerStationType));
      await prefs.setString('lunchStationSection', json.encode(lunchStationSection));
      await prefs.setString('dinnerStationSection', json.encode(dinnerStationSection));

      // --- Sync teamColor assignments to AppState servers for correct outlines and pie chart ---
      // Always sync both lunch and dinner team colors to the server objects
      for (final s in widget.app.servers) {
        s.teamColor = isLunch ? lunchTeamColors[s.id] : dinnerTeamColors[s.id];
      }

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

  // Also sync teamColor on server objects when switching between lunch/dinner
  void _syncServerTeamColors() {
    for (final s in widget.app.servers) {
      s.teamColor = isLunch ? lunchTeamColors[s.id] : dinnerTeamColors[s.id];
    }
  }

    // --- Assigned servers pane ---
    final roster = isLunch ? lunchRoster : dinnerRoster;
    final teamColors = isLunch ? lunchTeamColors : dinnerTeamColors;
    final serverStationType = isLunch ? lunchStationType : dinnerStationType;
    final serverStationSection = isLunch ? lunchStationSection : dinnerStationSection;

  final assignedServers = widget.app.servers.where((s) => roster.contains(s.id)).toList();
  final unassignedServers = widget.app.servers.where((s) => !roster.contains(s.id)).toList();

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
                  onPressed: () {
                    setState(() {
                      isLunch = true;
                      _syncServerTeamColors();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLunch ? Colors.blue : Colors.grey[300],
                    foregroundColor: isLunch ? Colors.white : Colors.black,
                  ),
                  child: const Text('Lunch'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLunch = false;
                      _syncServerTeamColors();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isLunch ? Colors.blue : Colors.grey[300],
                    foregroundColor: !isLunch ? Colors.white : Colors.black,
                  ),
                  child: const Text('Dinner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // --- Assigned Servers Pane with Clear All Button inside top right ---
            if (assignedServers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Assigned Servers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        if (isLunch)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              setState(() {
                                lunchRoster.clear();
                                for (var s in widget.app.servers) {
                                  lunchTeamColors[s.id] = null;
                                  lunchStationType.remove(s.id);
                                  lunchStationSection.remove(s.id);
                                }
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: Colors.blue, size: 18),
                                const SizedBox(width: 4),
                                Text('Clear All', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue, fontSize: 14)),
                              ],
                            ),
                          ),
                        if (!isLunch)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              setState(() {
                                dinnerRoster.clear();
                                for (var s in widget.app.servers) {
                                  dinnerTeamColors[s.id] = null;
                                  dinnerStationType.remove(s.id);
                                  dinnerStationSection.remove(s.id);
                                }
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: Colors.blue, size: 18),
                                const SizedBox(width: 4),
                                Text('Clear All', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue, fontSize: 14)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...assignedServers.map((s) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (serverStationSection[s.id] != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: Text(
                                    serverStationSection[s.id] ?? '',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                                  ),
                                ),
                              ),
                            // Color bubble for team color (no text)
                            if (showTeams)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: teamColors[s.id] == null
                                        ? Colors.grey.shade200
                                        : (
                                            teamColors[s.id] == 'Blue'
                                                ? Colors.blue.withOpacity(0.7)
                                                : teamColors[s.id] == 'Purple'
                                                    ? Colors.purple.withOpacity(0.7)
                                                    : Colors.grey.withOpacity(0.7)
                                          ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: teamColors[s.id] == null
                                          ? Colors.grey.shade400
                                          : (
                                              teamColors[s.id] == 'Blue'
                                                  ? Colors.blue
                                                  : teamColors[s.id] == 'Purple'
                                                      ? Colors.purple
                                                      : Colors.grey
                                            ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              roster.remove(s.id);
                              serverStationType.remove(s.id);
                              serverStationSection.remove(s.id);
                              teamColors[s.id] = null;
                            });
                          },
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            // --- Main List: Only unassigned servers ---
            Expanded(
              child: ListView.builder(
                itemCount: unassignedServers.length,
                itemBuilder: (ctx, i) {
                  final s = unassignedServers[i];
                  final teamColors = isLunch ? lunchTeamColors : dinnerTeamColors;
                  final serverStationType = isLunch ? lunchStationType : dinnerStationType;
                  final serverStationSection = isLunch ? lunchStationSection : dinnerStationSection;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Checkbox on the left
                          Checkbox(
                            value: false,
                            onChanged: (v) async {
                              if (v == true) {
                                final selectedTypeName = await _showStationTypeDialog(
                                  context,
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
                                    if (showTeams) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                                        final selectedColor = await showDialog<String?>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (colorContext) {
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
                                                    const SizedBox(height: 24),
                                                    Wrap(
                                                      spacing: 16,
                                                      runSpacing: 16,
                                                      alignment: WrapAlignment.center,
                                                      children: teamColorOptions.where((c) => c != null).map((color) {
                                                        Color bubbleColor;
                                                        switch (color) {
                                                          case 'Blue':
                                                            bubbleColor = Colors.blue;
                                                            break;
                                                          case 'Purple':
                                                            bubbleColor = Colors.purple;
                                                            break;
                                                          case 'Silver':
                                                            bubbleColor = Colors.grey;
                                                            break;
                                                          default:
                                                            bubbleColor = Colors.grey;
                                                        }
                                                        return GestureDetector(
                                                          onTap: () => Navigator.pop(colorContext, color),
                                                          child: Container(
                                                            width: 60,
                                                            height: 36,
                                                            decoration: BoxDecoration(
                                                              color: bubbleColor.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(18),
                                                              border: Border.all(
                                                                color: bubbleColor,
                                                                width: 2,
                                                              ),
                                                            ),
                                                            alignment: Alignment.center,
                                                            child: Text(
                                                              color!,
                                                              style: TextStyle(
                                                                color: color == 'Blue'
                                                                    ? Colors.blue[800]
                                                                    : color == 'Purple'
                                                                        ? Colors.purple[800]
                                                                        : color == 'Silver'
                                                                            ? Colors.grey[800]
                                                                            : Colors.black87,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    GestureDetector(
                                                      onTap: () => Navigator.pop(colorContext, null),
                                                      child: Container(
                                                        width: 80,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade300,
                                                          borderRadius: BorderRadius.circular(18),
                                                          border: Border.all(
                                                            color: Colors.grey.shade500,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: const Text(
                                                          'None',
                                                          style: TextStyle(
                                                            color: Colors.black54,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(colorContext),
                                                      child: const Text('Cancel'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                        if (selectedColor != null || selectedColor == null) {
                                          setState(() {
                                            teamColors[s.id] = selectedColor;
                                          });
                                        }
                                      });
                                    }
                                  }
                                }
                              }
                            },
                          ),
                          // Name/section and team color bubble in a Row
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: serverStationSection[s.id] != null ? 28 : 18,
                                    fontWeight: serverStationSection[s.id] != null ? FontWeight.bold : FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                if (serverStationSection[s.id] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: Colors.grey.shade400),
                                      ),
                                      child: Text(
                                        serverStationSection[s.id]!,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                                      ),
                                    ),
                                  ),
                                // Color bubble for team color (no text)
                                if (showTeams)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: teamColors[s.id] == null
                                            ? Colors.grey.shade200
                                            : (
                                                teamColors[s.id] == 'Blue'
                                                    ? Colors.blue.withOpacity(0.7)
                                                    : teamColors[s.id] == 'Purple'
                                                        ? Colors.purple.withOpacity(0.7)
                                                        : Colors.grey.withOpacity(0.7)
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: teamColors[s.id] == null
                                              ? Colors.grey.shade400
                                              : (
                                                  teamColors[s.id] == 'Blue'
                                                      ? Colors.blue
                                                      : teamColors[s.id] == 'Purple'
                                                          ? Colors.purple
                                                          : Colors.grey
                                                ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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