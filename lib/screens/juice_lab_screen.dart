import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/juice.dart';

/// Interactive preview of the "bold playful cartoon" tap-loop juice.
///
/// Important: there is NO speed/combo mechanic — a tap is a real food run, so
/// tapping fast earns nothing extra. The only quick-tap moment is "Full Hands"
/// (2+ taps within 3s = carrying multiple plates in one trip), which fires once
/// per trip and never ramps. Big moments come from milestones and level-ups.
class JuiceLabScreen extends StatefulWidget {
  const JuiceLabScreen({super.key});

  @override
  State<JuiceLabScreen> createState() => _JuiceLabScreenState();
}

class _JuiceLabScreenState extends State<JuiceLabScreen> {
  int _runs = 0;
  int _xp = 0;
  int _level = 1;
  int _id = 0;
  final List<Widget> _floaters = []; // "+10" near the card
  final List<Widget> _moments = []; // "FULL HANDS!" / "10 RUNS!" up top

  // Full Hands detection (mirrors the real app: 2+ taps within 3 seconds).
  final List<DateTime> _recentTaps = [];
  bool _fullHandsArmed = false;

  static const _xpPerLevel = 100; // demo curve
  static const _milestones = {5, 10, 20, 30, 50, 75, 100};

  double get _progress => (_xp % _xpPerLevel) / _xpPerLevel;

  void _spawnFloater(String text, Color color) {
    final id = _id++;
    late final Widget w;
    w = FloatingText(
      key: ValueKey('f$id'),
      text: text,
      color: color,
      onDone: () => setState(() => _floaters.remove(w)),
    );
    setState(() => _floaters.add(w));
  }

  void _spawnMoment(String text, Color color) {
    final id = _id++;
    late final Widget w;
    w = MomentBurst(
      key: ValueKey('m$id'),
      text: text,
      color: color,
      onDone: () => setState(() => _moments.remove(w)),
    );
    setState(() => _moments.add(w));
  }

  void _grantXp(int amount) {
    final before = _level;
    setState(() {
      _xp += amount;
      _level = (_xp ~/ _xpPerLevel) + 1;
    });
    if (_level > before) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLevelUp(context, _level);
      });
    }
  }

  void _run() {
    final now = DateTime.now();
    _recentTaps.add(now);
    _recentTaps.removeWhere((t) => now.difference(t) > const Duration(seconds: 3));
    if (_recentTaps.length == 1) _fullHandsArmed = false; // isolated tap = new trip

    HapticFeedback.lightImpact();
    setState(() => _runs++);
    _spawnFloater('+10', Cartoon.gold);

    // Full Hands: multiple plates in one trip — fires once per trip, no ramp.
    if (_recentTaps.length >= 2 && !_fullHandsArmed) {
      _fullHandsArmed = true;
      _spawnMoment('FULL HANDS!  +15', Cartoon.gold);
      _grantXp(25); // 10 base + 15 multi-plate bonus
    } else {
      _grantXp(10);
    }

    if (_milestones.contains(_runs)) {
      _spawnMoment('$_runs RUNS!', Cartoon.orange);
    }
  }

  void _pizookie() {
    HapticFeedback.mediumImpact();
    _spawnFloater('+25', Cartoon.pink);
    _grantXp(25);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cartoon.cream,
      appBar: AppBar(
        backgroundColor: Cartoon.orange,
        foregroundColor: Colors.white,
        title: Text('Juice Lab', style: Cartoon.heading(24, color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Celebration moments (Full Hands / milestones) appear here.
              SizedBox(
                height: 64,
                child: Stack(alignment: Alignment.center, children: _moments),
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      PopTap(
                        onTap: _run,
                        onLongPress: _pizookie,
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(22),
                          decoration: Cartoon.panel(Cartoon.blue),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('TAYLOR', style: Cartoon.heading(26, color: Colors.white)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: Cartoon.panel(Cartoon.gold, radius: 14, raised: false),
                                    child: Text('Lv $_level', style: Cartoon.heading(18)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RollingCount(_runs, style: Cartoon.heading(96, color: Colors.white)),
                              Text('RUNS', style: Cartoon.heading(18, color: Colors.white70)),
                              const SizedBox(height: 16),
                              XpBar(progress: _progress, label: '${_xp % _xpPerLevel} / $_xpPerLevel XP'),
                              const SizedBox(height: 12),
                              Text('Tap = run    •    Hold = Pizookie',
                                  style: Cartoon.heading(12, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(top: 80, child: Stack(children: _floaters)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _bigButton('FORCE LEVEL UP', Cartoon.purple, () {
                      setState(() => _level++);
                      showLevelUp(context, _level);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bigButton('RESET', Cartoon.pink, () {
                      setState(() {
                        _runs = 0;
                        _xp = 0;
                        _level = 1;
                        _recentTaps.clear();
                        _fullHandsArmed = false;
                      });
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigButton(String label, Color color, VoidCallback onTap) {
    return PopTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: Cartoon.panel(color),
        alignment: Alignment.center,
        child: Text(label, style: Cartoon.heading(16, color: Colors.white)),
      ),
    );
  }
}
