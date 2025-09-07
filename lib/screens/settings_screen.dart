import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/wallpaper_background.dart';
import 'encouragement_options_screen.dart';
import 'wallpaper_gallery_screen.dart';
import 'admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late WeeklyHours _hours;
  late int _transitionStart;
  late int _transitionEnd;

  bool _hoursExpanded = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _hours = app.hours;
    _transitionStart = app.settings.transitionStartMinutes;
    _transitionEnd = app.settings.transitionEndMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade600.withOpacity(0.8),
                Colors.lightBlue.shade400.withOpacity(0.6),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                'Gamification',
                Icons.emoji_events,
                [
                  _buildSettingsTile(
                    icon: Icons.emoji_events,
                    title: 'Gamification Options',
                    subtitle: 'Enable or disable achievements and streaks',
                    onTap: () => Navigator.pushNamed(context, '/gamification_options'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.celebration,
                    title: 'Encouragement Options',
                    subtitle: 'Customize encouragement text and behavior',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EncouragementOptionsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                'Appearance',
                Icons.palette,
                [
                  _buildSettingsTile(
                    icon: Icons.wallpaper,
                    title: 'Home Screen Wallpaper',
                    subtitle: 'Choose a background for the server grid',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WallpaperGalleryScreen()),
                      );
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.shuffle,
                    title: 'Auto-rotate wallpaper daily',
                    subtitle: 'Update with random selection each day',
                    value: app.autoRotateWallpaper,
                    onChanged: (value) => app.setAutoRotateWallpaper(value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildExpandableCard(
                'Hours & Transitions',
                Icons.access_time,
                'Open/close times by day and transition settings',
                _hoursExpanded,
                () => setState(() => _hoursExpanded = !_hoursExpanded),
                Column(
                  children: [
                    for (final d in _days)
                      _buildSettingsTile(
                        icon: Icons.schedule,
                        title: d.label,
                        subtitle: 'Open ${_fmtMin(_hours.openMinutes[d.weekday]!)} • Close ${_fmtMin(_hours.closeMinutes[d.weekday]!)}',
                        trailing: const Icon(Icons.edit, color: Colors.lightBlue),
                        onTap: () async {
                          final open = await _pickTime(context, 'Set open time for ${d.label}', _hours.openMinutes[d.weekday]!);
                          if (open == null) return;
                          final close = await _pickTime(context, 'Set close time for ${d.label}', _hours.closeMinutes[d.weekday]!);
                          if (close == null) return;
                          setState(() {
                            _hours.openMinutes[d.weekday] = open;
                            _hours.closeMinutes[d.weekday] = close;
                          });
                          app.setWeeklyHours(_hours);
                        },
                      ),
                    const Divider(
                      height: 32,
                      thickness: 2,
                      indent: 16,
                      endIndent: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Transition Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue.shade700,
                        ),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.swap_horiz,
                      title: 'Lunch to Dinner Transition',
                      subtitle: 'Start ${_fmtMin(_transitionStart)} • End ${_fmtMin(_transitionEnd)}',
                      trailing: const Icon(Icons.edit, color: Colors.lightBlue),
                      onTap: () async {
                        final start = await _pickTime(context, 'Set transition start time', _transitionStart);
                        if (start == null) return;
                        final end = await _pickTime(context, 'Set transition end time', _transitionEnd);
                        if (end == null) return;
                        setState(() {
                          _transitionStart = start;
                          _transitionEnd = end;
                        });
                        final newSettings = app.settings
                          ..transitionStartMinutes = _transitionStart
                          ..transitionEndMinutes = _transitionEnd;
                        await app.saveSettings(newSettings);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                'Administration',
                Icons.admin_panel_settings,
                [
                  _buildSettingsTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    subtitle: 'Access administrative tools and controls',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _pickTime(BuildContext context, String title, int minutes) async {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final tod = TimeOfDay(hour: h % 24, minute: m);
    final picked = await showTimePicker(context: context, helpText: title, initialTime: tod);
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final mm = m % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString()}:${mm.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildSectionCard(String title, IconData iconData, List<Widget> children) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.lightBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.lightBlue.shade400.withOpacity(0.8),
                    Colors.lightBlue.shade600.withOpacity(0.6),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconData, color: Colors.lightBlue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard(
    String title,
    IconData iconData,
    String subtitle,
    bool isExpanded,
    VoidCallback onTap,
    Widget expandedContent,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.lightBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.lightBlue.shade400.withOpacity(0.8),
                      Colors.lightBlue.shade600.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, color: Colors.lightBlue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) expandedContent,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.lightBlue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.lightBlue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.lightBlue,
          activeTrackColor: Colors.lightBlue.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _DayRow { final int weekday; final String label; const _DayRow(this.weekday, this.label); }
const _days = <_DayRow>[
  _DayRow(7, 'Sunday'),
  _DayRow(1, 'Monday'),
  _DayRow(2, 'Tuesday'),
  _DayRow(3, 'Wednesday'),
  _DayRow(4, 'Thursday'),
  _DayRow(5, 'Friday'),
  _DayRow(6, 'Saturday'),
];