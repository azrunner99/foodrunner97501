import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class TeamCompetitionDetailsScreen extends StatelessWidget {
  final Map<String, Color> teamColors;
  const TeamCompetitionDetailsScreen({required this.teamColors, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Group servers by team
    final Map<String, List<Server>> teams = {};
    for (final s in app.servers) {
      if (s.teamColor == null) continue;
      teams.putIfAbsent(s.teamColor!, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Competition Details')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: teamColors.keys.map((team) {
            final members = teams[team] ?? [];
            return Container(
              width: 160,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: teamColors[team]!, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: teamColors[team]!.withOpacity(0.07),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      team,
                      style: TextStyle(
                        color: teamColors[team],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Divider(),
                  ...members.map((s) {
                    final count = app.currentCounts[s.id] ?? 0;
                    return ListTile(
                      dense: true,
                      title: Text(s.name),
                      trailing: Text('$count'),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}