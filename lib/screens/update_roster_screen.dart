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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Update Active Roster',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
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

  // Helper method to get Color from team color string
  Color _getTeamColorValue(String teamColor) {
    switch (teamColor.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'silver':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  void _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load station types
    stationTypes = await loadStationTypes();
    
    // Load stored station assignments
    final lunchStationTypeJson = prefs.getString('lunchStationType') ?? '{}';
    final dinnerStationTypeJson = prefs.getString('dinnerStationType') ?? '{}';
    final lunchStationSectionJson = prefs.getString('lunchStationSection') ?? '{}';
    final dinnerStationSectionJson = prefs.getString('dinnerStationSection') ?? '{}';
    
    setState(() {
      lunchStationType = Map<String, String?>.from(json.decode(lunchStationTypeJson));
      dinnerStationType = Map<String, String?>.from(json.decode(dinnerStationTypeJson));
      lunchStationSection = Map<String, String?>.from(json.decode(lunchStationSectionJson));
      dinnerStationSection = Map<String, String?>.from(json.decode(dinnerStationSectionJson));
      
      // Initialize rosters from app state
      lunchRoster = List<String>.from(widget.app.todayPlan?.lunchRoster ?? []);
      dinnerRoster = List<String>.from(widget.app.todayPlan?.dinnerRoster ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    void saveRoster() async {
      widget.app.setTodayPlan(lunchRoster, dinnerRoster);

      // Persist station assignments to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lunchStationType', json.encode(lunchStationType));
      await prefs.setString('dinnerStationType', json.encode(dinnerStationType));
      await prefs.setString('lunchStationSection', json.encode(lunchStationSection));
      await prefs.setString('dinnerStationSection', json.encode(dinnerStationSection));

      // Sync teamColor assignments to AppState servers
      for (final s in widget.app.servers) {
        s.teamColor = isLunch ? lunchTeamColors[s.id] : dinnerTeamColors[s.id];
      }

      // Update the active roster immediately
      final now = DateTime.now();
      final intended = widget.app.currentIntendedShiftType(now);
      if (intended == 'Lunch') {
        widget.app.updateActiveRoster(lunchRoster);
      } else {
        widget.app.updateActiveRoster(dinnerRoster);
      }
    }

    // Sync teamColor on server objects when switching between lunch/dinner
    void _syncServerTeamColors() {
      for (final s in widget.app.servers) {
        s.teamColor = isLunch ? lunchTeamColors[s.id] : dinnerTeamColors[s.id];
      }
    }

    // Current state variables
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Enhanced Controls Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Small centered Teams toggle at top
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => showTeams = !showTeams),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: showTeams ? Colors.purple[50] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: showTeams ? Colors.purple[300]! : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups,
                                size: 16,
                                color: showTeams ? Colors.purple[600] : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Assign Teams',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: showTeams ? Colors.purple[700] : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 30,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: showTeams ? Colors.purple[400] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: showTeams ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lunch/Dinner Toggle below, full width
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLunch = true;
                                  _syncServerTeamColors();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLunch ? Colors.orange[400] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isLunch ? [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wb_sunny,
                                      size: 20,
                                      color: isLunch ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lunch',
                                      style: TextStyle(
                                        color: isLunch ? Colors.white : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLunch = false;
                                  _syncServerTeamColors();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isLunch ? Colors.indigo[400] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !isLunch ? [
                                    BoxShadow(
                                      color: Colors.indigo.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.nights_stay,
                                      size: 20,
                                      color: !isLunch ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dinner',
                                      style: TextStyle(
                                        color: !isLunch ? Colors.white : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
              
              // Assigned Servers Section
              if (assignedServers.isNotEmpty)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 200,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Assigned Servers',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${assignedServers.length} ${assignedServers.length == 1 ? 'server' : 'servers'} ready',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!, width: 1),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isLunch) {
                                      lunchRoster.clear();
                                      for (var s in widget.app.servers) {
                                        lunchTeamColors[s.id] = null;
                                        lunchStationType.remove(s.id);
                                        lunchStationSection.remove(s.id);
                                      }
                                    } else {
                                      dinnerRoster.clear();
                                      for (var s in widget.app.servers) {
                                        dinnerTeamColors[s.id] = null;
                                        dinnerStationType.remove(s.id);
                                        dinnerStationSection.remove(s.id);
                                      }
                                    }
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.clear_all, color: Colors.red[600], size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Clear All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Assigned servers list
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: assignedServers.length,
                            itemBuilder: (context, index) {
                              final s = assignedServers[index];
                              final teamColor = teamColors[s.id];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: teamColor != null 
                                    ? Border.all(color: _getTeamColorValue(teamColor), width: 2)
                                    : Border.all(color: Colors.grey[200]!, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    setState(() {
                                      roster.remove(s.id);
                                      teamColors.remove(s.id);
                                      serverStationType.remove(s.id);
                                      serverStationSection.remove(s.id);
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                s.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (serverStationSection[s.id] != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    serverStationSection[s.id]!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              roster.remove(s.id);
                                              teamColors.remove(s.id);
                                              serverStationType.remove(s.id);
                                              serverStationSection.remove(s.id);
                                            });
                                          },
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.red[400],
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

              // Available Servers Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Servers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Tap to assign to ${isLunch ? 'lunch' : 'dinner'} shift',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Available servers list
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: ListView.builder(
                            itemCount: unassignedServers.length,
                            itemBuilder: (context, index) {
                              final s = unassignedServers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[300]!, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    children: [
                                      // Banner background
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Image.asset(
                                          widget.app.profiles[s.id]?.bannerPath ?? 'assets/banners/image001.webp',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.green[400]!,
                                                    Colors.blue[400]!,
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Gradient overlay for better text readability
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withOpacity(0.5),
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Content overlay
                                      InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () async {
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
                                                        const Text('Select Team Color', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 24),
                                                        Wrap(
                                                          spacing: 16,
                                                          runSpacing: 16,
                                                          alignment: WrapAlignment.center,
                                                          children: teamColorOptions.map((color) {
                                                            final isSelected = color == teamColors[s.id];
                                                            return GestureDetector(
                                                              onTap: () => Navigator.pop(colorContext, color),
                                                              child: Container(
                                                                width: 80,
                                                                height: 80,
                                                                decoration: BoxDecoration(
                                                                  color: color == null ? Colors.grey.shade200 : null,
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(
                                                                    color: isSelected ? Colors.blue : Colors.transparent,
                                                                    width: 2,
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    color == null ? 'None' : color,
                                                                    style: TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: isSelected ? Colors.blue : Colors.black87,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                        const SizedBox(height: 12),
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
                                            if (selectedColor != null) {
                                              setState(() {
                                                teamColors[s.id] = selectedColor;
                                              });
                                            }
                                          });
                                        }
                                      }
                                    }
                                  },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              // Server name on the left
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      s.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black54,
                                                            blurRadius: 4,
                                                            offset: Offset(1, 1),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Available for assignment',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white.withOpacity(0.9),
                                                        shadows: const [
                                                          Shadow(
                                                            color: Colors.black54,
                                                            blurRadius: 2,
                                                            offset: Offset(0.5, 0.5),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Avatar on the right
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    widget.app.profiles[s.id]?.avatarPath ?? 'assets/avatars/image001.png',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: Icon(
                                                          Icons.person_add,
                                                          color: Colors.blue[600],
                                                          size: 30,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Add indicator (top right corner)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ], // closes children of main Column
          ), // closes Column
        ), // closes Padding
      ), // closes Container with gradient
    ); // closes WillPopScope
  }

  Future<String?> _showStationTypeDialog(BuildContext context) async {
    if (stationTypes.isEmpty) {
      return null;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Select Station Type', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: stationTypes.map((stationType) {
                    return SizedBox(
                      width: 120,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          elevation: 1,
                        ),
                        onPressed: () => Navigator.pop(context, stationType.name),
                        child: Text(stationType.name),
                      ),
                    );
                  }).toList(),
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
}
