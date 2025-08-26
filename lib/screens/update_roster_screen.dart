
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

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
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Checkbox(
                            value: roster.contains(s.id),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  roster.add(s.id);
                                } else {
                                  roster.remove(s.id);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 12),
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