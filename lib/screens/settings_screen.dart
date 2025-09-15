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
  bool _gamificationExpanded = false;
  bool _appearanceExpanded = false;

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
              _buildExpandableCard(
                'Gamification',
                Icons.emoji_events,
                'Enable or disable achievements and streaks',
                _gamificationExpanded,
                () => setState(() => _gamificationExpanded = !_gamificationExpanded),
                Column(
                  children: [
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
              ),
              const SizedBox(height: 16),
              _buildExpandableCard(
                'Appearance',
                Icons.palette,
                'Choose wallpapers and appearance settings',
                _appearanceExpanded,
                () => setState(() => _appearanceExpanded = !_appearanceExpanded),
                Column(
                  children: [
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
                          
                          // Temporarily update hours to check transition conflicts
                          final oldOpen = _hours.openMinutes[d.weekday]!;
                          final oldClose = _hours.closeMinutes[d.weekday]!;
                          _hours.openMinutes[d.weekday] = open;
                          _hours.closeMinutes[d.weekday] = close;
                          
                          // Check if current transition times are still valid with new hours
                          final conflicts = _validateTransitionTimes(_transitionStart, _transitionEnd);
                          if (conflicts.isNotEmpty) {
                            // Restore old values
                            _hours.openMinutes[d.weekday] = oldOpen;
                            _hours.closeMinutes[d.weekday] = oldClose;
                            
                            await _showTransitionConflictDialog([
                              'Changing ${d.label} hours would create conflicts with current transition times:',
                              ...conflicts,
                            ]);
                            return;
                          }
                          
                          setState(() {
                            // Hours already updated above for validation
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
                      subtitle: 'Start ${_fmtMin(_transitionStart)} • End ${_fmtMin(_transitionEnd)}${_getTransitionValidationStatus()}',
                      trailing: const Icon(Icons.edit, color: Colors.lightBlue),
                      onTap: () async {
                        final start = await _pickTime(context, 'Set transition start time', _transitionStart);
                        if (start == null) return;
                        final end = await _pickTime(context, 'Set transition end time', _transitionEnd);
                        if (end == null) return;
                        
                        // Validate that transition times are within business hours
                        final conflicts = _validateTransitionTimes(start, end);
                        if (conflicts.isNotEmpty) {
                          await _showTransitionConflictDialog(conflicts);
                          return; // Don't save the invalid times
                        }
                        
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
              _buildClickableCard(
                'Administration',
                Icons.admin_panel_settings,
                'Access administrative tools and controls',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
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
    
    if (title.toLowerCase().contains('close')) {
      return await _pickClosingTimeSimple(context, title, minutes);
    } else {
      // For opening times, use standard time picker
      final picked = await showTimePicker(context: context, helpText: title, initialTime: tod);
      if (picked == null) return null;
      return picked.hour * 60 + picked.minute;
    }
  }

  Future<int?> _pickClosingTimeSimple(BuildContext context, String title, int currentMinutes) async {
    // Convert current minutes to display format
    final h = currentMinutes ~/ 60;
    final m = currentMinutes % 60;
    final displayHour = h % 24;
    final initialTime = TimeOfDay(hour: displayHour, minute: m);
    
    final picked = await showTimePicker(
      context: context, 
      helpText: title,
      initialTime: initialTime,
    );
    
    if (picked == null) return null;
    
    final pickedMinutes = picked.hour * 60 + picked.minute;
    
    // Smart overnight detection: if closing time is earlier in the day than typical opening time,
    // assume it's overnight (next day). Typical restaurant opens around 11 AM (660 minutes).
    final isLikelyOvernight = pickedMinutes < 660; // Before 11 AM = likely overnight
    
    return isLikelyOvernight ? pickedMinutes + 1440 : pickedMinutes;
  }

  String _fmtMin(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    final h24 = h % 24;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final timeStr = '${h12.toString()}:${mm.toString().padLeft(2, '0')} $ampm';
    return timeStr; // No (+1) indicator - users understand overnight setup during configuration
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
                padding: const EdgeInsets.all(8),
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
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(iconData, color: Colors.lightBlue.shade700, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildClickableCard(
    String title,
    IconData iconData,
    String subtitle,
    VoidCallback onTap,
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(8),
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(iconData, color: Colors.lightBlue.shade700, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
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

  /// Validates that transition times fall within business hours for all days
  List<String> _validateTransitionTimes(int transitionStart, int transitionEnd) {
    final conflicts = <String>[];
    
    for (final day in _days) {
      final openMinutes = _hours.openMinutes[day.weekday] ?? 11 * 60;
      final closeRaw = _hours.closeMinutes[day.weekday] ?? 23 * 60;
      
      // Handle overnight closing times
      bool isValidTransition;
      if (closeRaw >= 1440) {
        // Overnight shift - transition must be after open and before end of calendar day
        // (The overnight portion is typically just cleanup, not service)
        final effectiveClose = 1439; // End of calendar day
        isValidTransition = transitionStart >= openMinutes && 
                           transitionEnd >= openMinutes && 
                           transitionStart <= effectiveClose && 
                           transitionEnd <= effectiveClose &&
                           transitionStart < transitionEnd;
      } else {
        // Same-day closing - transition must be within open and close
        isValidTransition = transitionStart >= openMinutes && 
                           transitionEnd >= openMinutes && 
                           transitionStart < closeRaw && 
                           transitionEnd < closeRaw &&
                           transitionStart < transitionEnd;
      }
      
      if (!isValidTransition) {
        final openStr = _fmtMin(openMinutes);
        final closeStr = _fmtMin(closeRaw);
        conflicts.add('${day.label}: Open $openStr - Close $closeStr');
      }
    }
    
    return conflicts;
  }

  /// Returns a status indicator for current transition validation state
  String _getTransitionValidationStatus() {
    final conflicts = _validateTransitionTimes(_transitionStart, _transitionEnd);
    if (conflicts.isEmpty) {
      return ' ✅'; // Valid
    } else {
      return ' ⚠️ (${conflicts.length} conflicts)'; // Invalid with count
    }
  }

  /// Shows a dialog with transition validation conflicts
  Future<void> _showTransitionConflictDialog(List<String> conflicts) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transition Time Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The transition period must fall within business hours for all days.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Conflicts found on:'),
            const SizedBox(height: 8),
            ...conflicts.map((conflict) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• $conflict', style: const TextStyle(fontSize: 14)),
            )),
            const SizedBox(height: 16),
            const Text(
              'Please either:\n• Adjust the transition times, or\n• Update the business hours for the conflicting days',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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