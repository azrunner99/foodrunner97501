import 'package:flutter/material.dart';
import 'version_history_screen.dart';

class AppFeaturesScreen extends StatelessWidget {
  const AppFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Features'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade400,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'RUNNER!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive Restaurant Management System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Feature Categories
            _buildFeatureCategory(
              title: 'Core Tracking',
              icon: Icons.track_changes,
              color: Colors.blue,
              features: [
                'Shift Tracking: Track server runs for each shift (Lunch/Dinner) with real-time updates and automatic transition handling.',
                'Click Tracking: Counts runs and pizookie runs for each server, with streaks, peak bonuses, and closer bonuses.',
                'Pizookie Runs: Special long-press action to log Pizookie runs (25 XP each), tracked separately from regular runs.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Team & Competition',
              icon: Icons.groups,
              color: Colors.purple,
              features: [
                'Team Competition: Color-coded team assignments (Blue, Purple, Silver) with detailed pie chart analytics and performance tracking.',
                'Visual Leaderboards: Enhanced shift detail screens with sortable stats, MVP badges, and top 3 medal rankings.',
                'Roster Management: Assign servers to lunch and dinner rosters, with station types and sections (Cocktail, Dining Room, Patio, Test).',
              ],
            ),

            _buildFeatureCategory(
              title: 'Gamification',
              icon: Icons.emoji_events,
              color: Colors.orange,
              features: [
                'Leveling System: Each server has a visible level badge, XP points, and progress bar to next level with achievement unlocks.',
                'Achievement System: Unlock badges for milestones, streaks, and special accomplishments with visual feedback.',
                'XP & Rewards: Dynamic point system with bonus multipliers, achievement flashes, and progress tracking.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Customization',
              icon: Icons.palette,
              color: Colors.green,
              features: [
                'Avatar Gallery: Choose from 38+ preset avatars or upload custom photos with automatic resizing and circular cropping.',
                'Banner System: 174+ professional profile banners (800x320px) with availability management and dynamic display.',
                'Wallpaper Gallery: 73+ background wallpapers for complete visual customization of the app interface.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Management & Settings',
              icon: Icons.settings,
              color: Colors.teal,
              features: [
                'Station Types & Sections: Configure custom station types with abbreviations and section numbers for organized server assignments.',
                'Shift Transition: Intelligent lunch/dinner transitions preserving counts for cross-shift servers and resetting lunch-only servers.',
                'Admin Controls: PIN-protected admin access for roster management, server settings, and data management.',
                'Smart Roster Switching: Auto/manual toggle between lunch and dinner views with transition period handling.',
              ],
            ),

            _buildFeatureCategory(
              title: 'User Experience',
              icon: Icons.phone_android,
              color: Colors.indigo,
              features: [
                'Visual Feedback: Real-time snackbars, achievement flashes, encouragement messages, and interactive UI elements.',
                'Responsive Design: Adaptive grid layouts, scrollable dialogs, and optimized UI for different screen sizes.',
                'Data Persistence: All stats, settings, avatars, and configurations automatically saved and restored across sessions.',
                'Profile Management: Individual server profiles with detailed statistics, avatar history, and performance analytics.',
                'History & Profiles: Access to shift history, server profiles, and comprehensive performance analytics.',
                'Feature Discovery: Multiple ways to explore app features including this dedicated screen.',
              ],
            ),

            // Version and Navigation
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VersionHistoryScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Version: 3.0.0+300',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap version number for detailed update history',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Features List
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
