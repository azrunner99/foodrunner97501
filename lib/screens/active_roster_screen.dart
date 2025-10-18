import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/wallpaper_background.dart';

class ActiveRosterScreen extends StatefulWidget {
  const ActiveRosterScreen({super.key});

  @override
  State<ActiveRosterScreen> createState() => _ActiveRosterScreenState();
}

class _ActiveRosterScreenState extends State<ActiveRosterScreen> {
  bool _unlocked = false;
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Update Active Roster'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade600.withOpacity(0.8),
                  Colors.red.shade400.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        body: WallpaperBackground(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                elevation: 12,
                shadowColor: Colors.red.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              spreadRadius: 4,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Admin Access Required',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter PIN to modify server roster',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 20,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter PIN',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.red.shade400, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildKeypad(),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _tryUnlock(app),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Unlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Active Roster'),
      ),
      body: _RosterBody(app: app),
    );
  }

  void _tryUnlock(AppState app) async {
    final isValid = await app.isValidAdminPin(_pinCtrl.text);
    if (isValid) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('Clear', isSpecial: true),
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isSpecial: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {bool isSpecial = false}) {
    return SizedBox(
      width: 70,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _onKeypadPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpecial ? Colors.grey.shade200 : Colors.white,
          foregroundColor: isSpecial ? Colors.grey.shade700 : Colors.black87,
          elevation: 2,
          shadowColor: Colors.red.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSpecial ? 16 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _onKeypadPressed(String value) {
    setState(() {
      if (value == 'Clear') {
        _pinCtrl.clear();
      } else if (value == '⌫') {
        if (_pinCtrl.text.isNotEmpty) {
          _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);
        }
      } else if (_pinCtrl.text.length < 6) {
        // Limit PIN length
        _pinCtrl.text += value;
      }
    });

    // Auto-unlock if PIN is complete
    if (_pinCtrl.text.length >= 4) {
      _tryUnlock(context.read<AppState>());
    }
  }
}

class _RosterBody extends StatefulWidget {
  final AppState app;
  const _RosterBody({required this.app});

  @override
  State<_RosterBody> createState() => _RosterBodyState();
}

class _RosterBodyState extends State<_RosterBody> {
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
      for (var s in widget.app.activeServers) s.id: s.teamColor,
    };
  }

  static const teamColorOptions = [
    'Blue',
    'Purple',
    'Silver',
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final servers = widget.app.activeServers; // Only show active servers in roster

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (ctx, i) {
                final s = servers[i];
                final roster = isLunch ? lunchRoster : dinnerRoster;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
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
                        Text(isLunch ? 'Lunch' : 'Dinner'),
                        const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Roster'),
            onPressed: () {
              for (var s in widget.app.servers) {
                s.teamColor = teamColors[s.id];
              }
              widget.app.setTodayPlan(lunchRoster, dinnerRoster);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
