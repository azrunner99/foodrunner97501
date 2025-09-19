import 'package:flutter/material.dart';
import '../app_state.dart';

class BirthdayAnniversaryBanner extends StatefulWidget {
  final AppState appState;

  const BirthdayAnniversaryBanner({
    super.key,
    required this.appState,
  });

  @override
  State<BirthdayAnniversaryBanner> createState() =>
      _BirthdayAnniversaryBannerState();
}

class _BirthdayAnniversaryBannerState extends State<BirthdayAnniversaryBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> _celebrationMessages = [];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(
          seconds: 23), // 23 seconds per message (70% of current speed)
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0, // Start from right side
      end: -1.0, // End at left side
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _loadCelebrationMessages();

    if (_celebrationMessages.isNotEmpty) {
      _startAnimation();
    }
  }

  void _loadCelebrationMessages() {
    final today = DateTime.now();
    final todayMonth = today.month.toString().padLeft(2, '0');
    final todayDay = today.day.toString().padLeft(2, '0');
    final todayYear = today.year;

    final messages = <String>[];

    // Check all servers for birthdays and anniversaries
    for (final server in widget.appState.servers) {
      final profile = widget.appState.profiles[server.id];
      if (profile == null) continue;

      // Check birthday (format: MM/DD)
      if (profile.birthday.isNotEmpty) {
        try {
          final birthdayParts = profile.birthday.split('/');
          if (birthdayParts.length >= 2) {
            final birthdayMonth = birthdayParts[0];
            final birthdayDay = birthdayParts[1];

            if (birthdayMonth == todayMonth && birthdayDay == todayDay) {
              messages.add('Happy Birthday ${server.name}!');
            }
          }
        } catch (e) {
          // Invalid birthday format, skip
        }
      }

      // Check hire date anniversary (format: MM/DD/YYYY)
      if (profile.hireDate.isNotEmpty) {
        try {
          final hireDateParts = profile.hireDate.split('/');
          if (hireDateParts.length >= 3) {
            final hireMonth = hireDateParts[0];
            final hireDay = hireDateParts[1];
            final hireYear = int.parse(hireDateParts[2]);

            if (hireMonth == todayMonth &&
                hireDay == todayDay &&
                hireYear < todayYear) {
              final yearsOfService = todayYear - hireYear;
              String yearText = yearsOfService == 1 ? 'year' : 'years';
              messages.add(
                  'Happy $yearsOfService $yearText Anniversary ${server.name}!');
            }
          }
        } catch (e) {
          // Invalid hire date format, skip
        }
      }
    }

    setState(() {
      _celebrationMessages = messages;
    });
  }

  void _startAnimation() {
    _animationController.reset();
    _animationController.forward().then((_) {
      if (mounted && _celebrationMessages.isNotEmpty) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _celebrationMessages.length;
        });
        _startAnimation(); // Continue with next message
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner if no celebrations today
    if (_celebrationMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50, // Same height as the shift leaderboard notification
      margin:
          const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 24.0, right: 24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // Light blue
            Color(0xFFBBDEFB), // Slightly darker light blue
            Color(0xFFE3F2FD), // Light blue
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black54,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Animated scrolling text
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: _animation.value * MediaQuery.of(context).size.width,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _celebrationMessages[_currentMessageIndex],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
