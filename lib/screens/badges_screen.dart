import 'package:flutter/material.dart';
import '../app_state.dart';
import '../gamification.dart';

class BadgesScreen extends StatelessWidget {
  static String _descFor(String id) {
    switch (id) {
      case 'first_run':
        return 'Your first food run ever.';
      case 'first_run_today':
        return 'First food run of the day.';
      case 'three_streak':
        return '3 runs in a row without a decrement.';
      case 'five_streak':
        return '5 runs in a row without a decrement.';
      case 'ten_in_shift':
        return '10 runs in a single shift.';
      case 'twenty_in_shift':
        return '20 runs in a single shift.';
      case 'night_owl':
        return 'Run food after 11:00 PM.';
      case 'fifty_all_time':
        return '50 total runs across all time.';
      case 'hundred_all_time':
        return '100 total runs across all time.';
      case 'mvp':
        return 'Most runs on a completed shift.';
      case 'team_goal':
        return 'Team hit the shift goal.';
      case 'lunch_peak_10':
        return '10 runs during lunch peak (12:30–2:00).';
      case 'dinner_peak_10':
        return '10 runs during dinner peak (6:30–8:00).';
      case 'lunch_closer_8':
        return '8 runs in lunch close (2:30–3:30).';
      case 'dinner_closer_8':
        return '8 runs in dinner close (9:00–close).';
      default:
        return 'Earn this badge by hitting its target during service.';
    }
  }
  final ServerProfile profile;
  final Map<String, int> repeatCounts;
  const BadgesScreen({super.key, required this.profile, required this.repeatCounts});

  AchievementDef? _findDef(String id) {
    for (final d in achievementsCatalog) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Widget> _earnedBadgesList() {
    final tiles = <Widget>[];
    for (final id in profile.achievements) {
      final def = _findDef(id);
      tiles.add(ListTile(
        leading: const Icon(Icons.verified, color: Colors.amber),
        title: Text(def?.title ?? 'Unknown'),
        subtitle: Text('${def?.points ?? 0} pts • ${BadgesScreen._descFor(def?.id ?? id)}'),
      ));
    }
    repeatCounts.forEach((id, times) {
      final def = _findDef(id);
      tiles.add(ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.lightBlue),
        title: Text(def?.title ?? 'Unknown'),
        subtitle: Text('${def?.points ?? 0} pts • x$times • ${BadgesScreen._descFor(def?.id ?? id)}'),
      ));
    });
    if (tiles.isEmpty) {
      tiles.add(const ListTile(title: Text('No badges yet.')));
    }
    return tiles;
  }

  List<Widget> _availableList(List<(AchievementDef, bool, int)> items) {
    return items.map((t) {
      final def = t.$1;
      final earned = t.$2;
      final times = t.$3;
      final trailing = earned
          ? Text(times > 0 ? 'x$times' : 'Earned', style: const TextStyle(color: Colors.green))
          : Text('${def.points} pts', style: const TextStyle(color: Colors.blueGrey));
      return ListTile(
        leading: Icon(earned ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: earned ? Colors.green : null),
        title: Text(def.title),
        subtitle: Text(BadgesScreen._descFor(def.id)),
        trailing: trailing,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    String mode = 'earned';
    final earnedSet = profile.achievements.toSet();
    final List<(AchievementDef, bool, int)> available = achievementsCatalog
        .map<(AchievementDef, bool, int)>((def) {
          final times = repeatCounts[def.id] ?? 0;
          final earnedOnce = earnedSet.contains(def.id) || times > 0;
          return (def, earnedOnce, times);
        })
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'earned', label: Text('Earned')),
                  ButtonSegment(value: 'available', label: Text('Available')),
                ],
                selected: <String>{mode},
                onSelectionChanged: (s) => setState(() => mode = s.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: mode == 'earned'
                      ? _earnedBadgesList()
                      : _availableList(available),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Removed duplicate build method
}
