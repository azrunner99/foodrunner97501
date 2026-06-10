import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bold playful "cartoon" design tokens + juicy, reusable widgets for the
/// food-run tap loop. Everything here is self-contained (no AppState coupling)
/// so it can be previewed in the Juice Lab and dropped into the real screens.
class Cartoon {
  static const font = 'Luckiest Guy';

  // Bright, saturated palette.
  static const cream = Color(0xFFFFF3D6);
  static const ink = Color(0xFF1B1029);
  static const orange = Color(0xFFFF7A1A);
  static const pink = Color(0xFFFF4D8D);
  static const blue = Color(0xFF2DB7FF);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF35D07F);
  static const gold = Color(0xFFFFC53D);

  static const palette = [orange, blue, purple, green, pink];

  /// A chunky cartoon container: thick black outline + hard drop shadow.
  static BoxDecoration panel(Color color, {double radius = 28, bool raised = true}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ink, width: 4),
      boxShadow: raised
          ? const [BoxShadow(color: ink, offset: Offset(0, 6), blurRadius: 0)]
          : null,
    );
  }

  static TextStyle heading(double size, {Color color = ink}) => TextStyle(
        fontFamily: font,
        fontSize: size,
        color: color,
        letterSpacing: 0.5,
        shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 0)],
      );
}

/// A number that smoothly rolls up to its new value when [value] changes.
class RollingCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  const RollingCount(this.value,
      {required this.style, this.duration = const Duration(milliseconds: 450), super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Wraps [child] with a squash-and-stretch pop on tap (classic game juice).
class PopTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const PopTap({required this.child, required this.onTap, this.onLongPress, super.key});

  @override
  State<PopTap> createState() => _PopTapState();
}

class _PopTapState extends State<PopTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeOut)), weight: 28),
    TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 32),
    TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pop() => _c.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _pop();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// A "+10 XP" that floats up and fades, then removes itself via [onDone].
class FloatingText extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onDone;
  const FloatingText({required this.text, required this.color, required this.onDone, super.key});

  @override
  State<FloatingText> createState() => _FloatingTextState();
}

class _FloatingTextState extends State<FloatingText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward()
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });
  late final double _drift = (Random().nextDouble() - 0.5) * 60;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rise = Curves.easeOut.transform(t);
        return Transform.translate(
          offset: Offset(_drift * t, -90 * rise),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.8 + 0.6 * Curves.elasticOut.transform(min(1, t * 2)),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: Cartoon.font,
                  fontSize: 30,
                  color: widget.color,
                  shadows: const [Shadow(color: Cartoon.ink, offset: Offset(0, 3), blurRadius: 0)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Drives a streak/combo gauge. Call [hit] on each run; it decays after a pause.
class ComboController extends ChangeNotifier {
  int _combo = 0;
  Timer? _decay;
  final int maxForFull;
  final Duration window;
  ComboController({this.maxForFull = 10, this.window = const Duration(seconds: 3)});

  int get combo => _combo;
  double get heat => (_combo / maxForFull).clamp(0.0, 1.0);
  int get multiplier => 1 + (_combo ~/ 5);

  void hit() {
    _combo++;
    notifyListeners();
    _decay?.cancel();
    _decay = Timer(window, () {
      _combo = 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _decay?.cancel();
    super.dispose();
  }
}

/// A heat bar that fills and shifts orange→red as the combo climbs.
class ComboMeter extends StatelessWidget {
  final ComboController controller;
  const ComboMeter({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final heat = controller.heat;
        final color = Color.lerp(Cartoon.gold, Cartoon.pink, heat)!;
        return AnimatedOpacity(
          opacity: controller.combo > 1 ? 1 : 0.25,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              Text('x${controller.multiplier}', style: Cartoon.heading(22, color: color)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: Cartoon.panel(Colors.white, radius: 12, raised: false),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: heat),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        builder: (context, v, __) => FractionallySizedBox(
                          widthFactor: v == 0 ? 0.001 : v,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Cartoon.gold, color]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(controller.combo > 1 ? '${controller.combo} COMBO' : 'COMBO',
                  style: Cartoon.heading(14, color: Cartoon.ink)),
            ],
          ),
        );
      },
    );
  }
}

/// A chunky animated XP bar that fills toward the next level with a glow.
class XpBar extends StatelessWidget {
  final double progress; // 0..1
  final String label;
  const XpBar({required this.progress, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: Cartoon.panel(Colors.white, radius: 16, raised: false),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v == 0 ? 0.001 : v,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Cartoon.green, Cartoon.blue]),
                  ),
                ),
              ),
            ),
          ),
          Center(child: Text(label, style: Cartoon.heading(14, color: Cartoon.ink))),
        ],
      ),
    );
  }
}

/// Full-screen LEVEL UP celebration: confetti + a banner that slams in.
Future<void> showLevelUp(BuildContext context, int newLevel) async {
  final confetti = ConfettiController(duration: const Duration(seconds: 2))..play();
  HapticFeedback.heavyImpact();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Level up',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, _, __) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              maxBlastForce: 28,
              minBlastForce: 8,
              gravity: 0.25,
              colors: Cartoon.palette,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: (0.2 + v * 0.8).clamp(0.0, 1.2), child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                decoration: Cartoon.panel(Cartoon.purple),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('LEVEL UP!', style: Cartoon.heading(40, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Level $newLevel', style: Cartoon.heading(64, color: Cartoon.gold)),
                    const SizedBox(height: 6),
                    Text('Tap to continue', style: Cartoon.heading(14, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  confetti.dispose();
}
