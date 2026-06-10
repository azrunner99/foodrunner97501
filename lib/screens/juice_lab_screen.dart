import 'package:flutter/material.dart';
import '../widgets/juice.dart';

/// Interactive preview of the "bold playful cartoon" tap-loop juice.
/// Self-contained (local state only) so it can be tuned on a device before the
/// real home screen is rewired. Tap the card = run, hold = Pizookie.
class JuiceLabScreen extends StatefulWidget {
  const JuiceLabScreen({super.key});

  @override
  State<JuiceLabScreen> createState() => _JuiceLabScreenState();
}

class _JuiceLabScreenState extends State<JuiceLabScreen> {
  final _combo = ComboController();
  int _runs = 0;
  int _xp = 0;
  int _level = 1;
  int _floaterId = 0;
  final List<Widget> _floaters = [];

  static const _xpPerLevel = 100; // demo curve

  double get _progress => (_xp % _xpPerLevel) / _xpPerLevel;

  @override
  void dispose() {
    _combo.dispose();
    super.dispose();
  }

  void _spawnFloater(String text, Color color) {
    final id = _floaterId++;
    late final Widget w;
    w = FloatingText(
      key: ValueKey('floater$id'),
      text: text,
      color: color,
      onDone: () => setState(() => _floaters.remove(w)),
    );
    setState(() => _floaters.add(w));
  }

  void _addXp(int amount, String label, Color color) {
    final before = _level;
    setState(() {
      _xp += amount;
      _level = (_xp ~/ _xpPerLevel) + 1;
    });
    _spawnFloater(label, color);
    if (_level > before) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLevelUp(context, _level);
      });
    }
  }

  void _run() {
    setState(() => _runs++);
    _combo.hit();
    _addXp(10, '+10', Cartoon.gold);
  }

  void _pizookie() {
    _combo.hit();
    _addXp(25, '+25', Cartoon.pink);
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
              ComboMeter(controller: _combo),
              const SizedBox(height: 20),
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
                      // Floating +XP, anchored just above the big number.
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
