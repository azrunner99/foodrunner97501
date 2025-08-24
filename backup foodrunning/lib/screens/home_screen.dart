import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../app_state.dart';
import '../models.dart';
import '../gamification.dart';
import 'mvp_screen.dart'; // NEW

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Food Runs'),
            actions: [
              // MVP screen button
              IconButton(
                icon: const Icon(Icons.emoji_events),
                tooltip: 'MVP Rankings',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MvpScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profiles',
                onPressed: () => Navigator.pushNamed(context, '/profiles'),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.pushNamed(context, '/history'),
                tooltip: 'History',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                tooltip: 'Settings',
              ),
              if (!app.shiftActive && app.canResumeLastShift)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await context.read<AppState>().resumeLastShift();
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift resumed')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore, color: Colors.white),
                  label: const Text('Resume', style: TextStyle(color: Colors.white)),
                ),
              if (app.shiftActive)
                TextButton.icon(
                  onPressed: () async {
                    await app.endShift();
                    if (app.settings.enableGamification &&
                        app.settings.showMvpConfetti) {
                      _confetti.play();
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift saved')),
                    );
                  },
                  icon: const Icon(Icons.stop_circle, color: Colors.white),
                  label: const Text('End', style: TextStyle(color: Colors.white)),
                )
              else
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/start_shift'),
                  icon: const Icon(Icons.play_circle, color: Colors.white),
                  label: const Text('Start', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          // No FAB to avoid accidental taps
          body: Column(
            children: [
              if (app.shiftActive &&
                  app.settings.enableGamification &&
                  app.settings.showGoalProgress)
                _GoalBar(goal: app.teamGoal, current: app.teamTotalThisShift),
              Expanded(
                child: app.shiftActive
                    ? const _ActiveShiftGridNoScroll()
                    : const _NoShiftView(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

class _GoalBar extends StatelessWidget {
  final int goal;
  final int current;
  const _GoalBar({required this.goal, required this.current});

  @override
  Widget build(BuildContext context) {
    final ratio = goal == 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team Total: $current / Goal: $goal'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: ratio, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class _NoShiftView extends StatelessWidget {
  const _NoShiftView();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final totalServers = app.servers.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, size: 64),
            const SizedBox(height: 16),
            Text(
              'No active shift.\nTap Start in the top right to begin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Servers in master list: $totalServers'),
          ],
        ),
      ),
    );
  }
}

/// A grid that auto-sizes so ALL server buttons fit on screen with NO SCROLL.
class _ActiveShiftGridNoScroll extends StatelessWidget {
  const _ActiveShiftGridNoScroll();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final working = app.workingServerIds
        .map((id) => app.serverById(id))
        .whereType<Server>()
        .toList();

    return LayoutBuilder(
      builder: (context, box) {
        final n = working.length.clamp(0, 100);
        if (n == 0) {
          return const Center(child: Text('No servers selected for this shift.'));
        }

        final w = box.maxWidth;
        final h = box.maxHeight;

        // Try from 4 columns down to 2; pick first layout that fits decently.
        int chosenCols = 2;
        double chosenAspect = 1.4;

        for (int cols = 4; cols >= 2; cols--) {
          final rows = (n / cols).ceil();
          final cellW = w / cols;
          final cellH = h / rows;
          final aspect = cellW / cellH;
          if (aspect >= 1.1 && aspect <= 2.2) {
            chosenCols = cols;
            chosenAspect = aspect;
            break;
          } else {
            chosenCols = cols;
            chosenAspect = aspect;
          }
        }

        int maxShift = 0;
        for (final s in working) {
          final c = app.currentCounts[s.id] ?? 0;
          if (c > maxShift) maxShift = c;
        }
        if (maxShift == 0) maxShift = 1;

        final teamTotal = app.teamTotalThisShift;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: working.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: chosenCols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: chosenAspect,
          ),
          itemBuilder: (context, i) {
            final s = working[i];
            final shiftCount = app.currentCounts[s.id] ?? 0;
            final allTime = app.allTimeFor(s.id);
            final ratio = shiftCount / maxShift;
            final color = _bandColor(ratio);
            final textColor = color.computeLuminance() < 0.5 ? Colors.white : Colors.black87;
            final shiftPct = teamTotal > 0 ? (shiftCount * 100.0 / teamTotal) : 0.0;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                SystemSound.play(SystemSoundType.click);
                app.increment(s.id);

                final showWords = app.settings.enableGamification && app.settings.showEncouragement;
                if (showWords) {
                  final msg = encouragements[Random().nextInt(encouragements.length)];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 3), // 3 seconds as requested
                      content: Text(msg),
                    ),
                  );
                }
              },
              onLongPress: () {
                HapticFeedback.selectionClick();
                app.decrement(s.id);
              },
              child: Card(
                elevation: 2,
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700, color: textColor, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text('This shift: $shiftCount',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                        const SizedBox(height: 2),
                        Text('Shift %: ${shiftPct.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColor)),
                        const SizedBox(height: 2),
                        Text('All-time: $allTime',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColor)),
                        const SizedBox(height: 6),
                        Text('Tap = +1   •   Long-press = −1',
                            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.85))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ≥80% deep green, 60–79% green, 30–59% yellow, 10–29% light red, <10% deep red
  static Color _bandColor(double r) {
    if (r >= 0.80) return const Color(0xFF1B5E20); // deep green
    if (r >= 0.60) return const Color(0xFF43A047); // green
    if (r >= 0.30) return const Color(0xFFFBC02D); // yellow
    if (r >= 0.10) return const Color(0xFFEF5350); // light red
    return const Color(0xFFB71C1C);                // deep red
  }
}
