import 'package:flutter/material.dart';
import 'version_history_screen.dart';
import 'about_screen.dart';

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
                    Image.asset(
                      'assets/runner.png',
                      height: 120,
                      fit: BoxFit.contain,
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
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Feature Categories
            _buildFeatureCategory(
              title: 'Core Shift Management',
              icon: Icons.track_changes,
              color: Colors.blue,
              features: [
                'Real-Time Shift Tracking: Track server runs for Lunch and Dinner shifts with live count updates and automatic timing.',
                'Smart Transition System: Intelligent lunch-to-dinner transitions that preserve counts for cross-shift servers while resetting lunch-only servers.',
                'Click & Long-Press Actions: Standard runs (10 XP) via tap, Pizookie runs (25 XP) via long-press with distinct tracking.',
                'Automatic Shift Activation: Time-based shift activation with configurable transition periods and manual override capabilities.',
                'Working Server Management: Dynamic roster management ensuring only assigned servers can receive clicks during their shifts.',
                'Shift History & Records: Complete historical tracking of all shifts with detailed server performance and timing data.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Advanced Roster &\nStation Management',
              icon: Icons.assignment_ind,
              color: Colors.teal,
              features: [
                'Dual Roster System: Separate lunch and dinner rosters with cross-shift server support for maximum flexibility.',
                'Station Type Assignments: Configure custom station types (Cocktail, Dining Room, Patio, Test Kitchen) with abbreviations.',
                'Section Number Organization: Assign servers to numbered sections within station types for organized floor management.',
                'Persistent Station Data: All station assignments saved across sessions with SharedPreferences integration.',
                'Team Color Assignments: Assign servers to Blue, Purple, or Silver teams with separate lunch/dinner team configurations.',
                'Smart Roster Switching: Auto/manual toggle between lunch and dinner views with intelligent transition period handling.',
                'Visual Roster Indicators: Clear visual feedback showing current roster status, assigned servers, and team affiliations.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Team Competition\n& Analytics',
              icon: Icons.groups,
              color: Colors.purple,
              features: [
                'Color-Coded Team System: Three-team competition (Blue, Purple, Silver) with visual color coding throughout the interface.',
                'Dynamic Pie Chart Analytics: Real-time team performance visualization with tap-to-cycle display modes and percentage breakdowns.',
                'Team Performance Tracking: Comprehensive team statistics with run counts, percentages, and comparative performance metrics.',
                'Cross-Shift Team Management: Teams can be configured differently for lunch and dinner shifts with automatic synchronization.',
                'Team Competition Details: Dedicated screen showing detailed team breakdowns with member lists and individual contributions.',
                'Team Goal System: Configurable team goals with achievement tracking when targets are met collectively.',
                'Team Toggle Functionality: Easy enable/disable of team features without losing assignment data.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Advanced Gamification\nSystem',
              icon: Icons.emoji_events,
              color: Colors.orange,
              features: [
                'Multi-Level XP System: 150-level progression system with exponentially increasing requirements and visual level badges.',
                'Enhanced Level Visualization: Refined gradient level bubbles with softer colors for better visual integration across all screens.',
                'Comprehensive Achievement System: 12+ unique achievements including streaks, milestones, MVP awards, and team goals.',
                'Repeatable Achievements: Some achievements (MVP, Team Goal) can be earned multiple times for ongoing engagement.',
                'Smart Achievement Detection: Automatic achievement detection with visual feedback and XP bonus rewards.',
                'Configurable Gamification: Complete enable/disable toggle for all gamification features while preserving core functionality.',
                'Streak Tracking: Multi-run streak detection with bonus XP rewards for consecutive successful runs.',
                'Performance Bonuses: Peak hour bonuses, closer bonuses, and special circumstance multipliers.',
                'Progress Visualization: Real-time XP progress bars, level indicators, and achievement status displays with consistent theming.',
                'Level Bubble Integration: Seamless level display integration across profiles, leaderboards, and all server displays.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Rich Customization &\nPersonalization',
              icon: Icons.palette,
              color: Colors.green,
              features: [
                'Extensive Avatar Gallery: 38+ professionally designed preset avatars with circular cropping and automatic resizing.',
                'Custom Avatar Upload: Photo upload capability with automatic processing, circular cropping, and quality optimization.',
                'Avatar History Tracking: Complete history of avatar changes with timestamps for server profile continuity.',
                'Professional Banner System: 174+ high-quality profile banners (800x320px) with availability management.',
                'Dynamic Banner Display: Intelligent banner rotation with availability status and visual consistency.',
                'Wallpaper Gallery: 73+ background wallpapers for complete app interface customization and personalization.',
                'Color Theme Integration: Consistent color schemes throughout the interface with theme-aware component design.',
                'Profile Customization: Complete server profile customization with visual elements and personal branding.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Data Management &\nAdmin Controls',
              icon: Icons.admin_panel_settings,
              color: Colors.red,
              features: [
                'PIN-Protected Admin Access: Secure 4-digit PIN system protecting all administrative functions and sensitive data.',
                'Comprehensive Server Management: Add, edit, delete servers with profile data, statistics, and configuration management.',
                'Server Archiving System: Archive/restore servers with dedicated archived servers screen and visual archive indicators.',
                'Archive Management: Safely archive inactive servers while preserving all historical data and statistics.',
                'Data Import/Export: Complete data backup and restore capabilities with JSON-based data structures and comprehensive ZIP file export functionality including photos.',
                'Settings Management: Granular control over all app features, timings, and behavioral configurations.',
                'Shift Control Panel: Manual shift start/stop, pause/resume functionality with administrative override capabilities.',
                'Server Integrity Monitoring: Built-in data validation and integrity checking with automated repair suggestions.',
                'Bulk Operations: Mass server management, roster updates, and configuration changes for efficiency.',
                'Administrative Logging: Detailed logging of administrative actions for audit trails and troubleshooting.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Analytics & Performance\nTracking',
              icon: Icons.analytics,
              color: Colors.indigo,
              features: [
                'Individual Server Profiles: Comprehensive statistics including all-time runs, best shift performance, and streak records.',
                'Advanced Leaderboard System: Multi-screen leaderboard displays with enhanced server performance tracking and visual design.',
                'Detailed Shift Analytics: Complete shift breakdowns with sortable statistics, MVP identification, and performance rankings.',
                'Historical Trend Analysis: Long-term performance tracking with shift-over-shift comparisons and trend identification.',
                'Performance Metrics: Advanced statistics including average runs per shift, consistency ratings, and improvement tracking.',
                'Enhanced Level Visualization: Consistent level bubble display across all screens with refined gradient colors for better integration.',
                'Sortable Leaderboards: Multiple sorting options (runs, pizookies, XP, level) with medal awards for top performers.',
                'Real-Time Statistics: Live updating statistics during shifts with immediate feedback and performance indicators.',
                'Export Capabilities: Data export functionality for external analysis and reporting requirements.',
                'Visual Performance Indicators: Charts, graphs, and visual elements showing performance trends and achievements.',
              ],
            ),

            _buildFeatureCategory(
              title: 'User Experience\n& Interface',
              icon: Icons.phone_android,
              color: Colors.cyan,
              features: [
                'Responsive Adaptive Design: Optimized layouts for phones, tablets, and desktop with automatic scaling and adjustment.',
                'Intuitive Touch Interface: Large touch targets, gesture support, and accessibility-compliant interaction design.',
                'Real-Time Visual Feedback: Instant snackbar notifications, achievement flashes, and progress animations.',
                'Smart Navigation: Context-aware navigation with breadcrumbs, back button handling, and deep linking support.',
                'Accessibility Features: Screen reader support, high contrast options, and keyboard navigation compatibility.',
                'Performance Optimization: Smooth 60fps animations, efficient memory usage, and fast startup times.',
                'Cross-Platform Compatibility: Full support for Android, iOS, Web, Windows, macOS, and Linux platforms.',
                'Offline Functionality: Local data storage ensuring full functionality without internet connectivity.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Advanced Features &\nIntegrations',
              icon: Icons.extension,
              color: Colors.deepOrange,
              features: [
                'Intelligent Encouragement System: Contextual motivational messages with customizable frequency and content.',
                'Easter Egg Features: Hidden features accessible through special interactions (5-tap feature discovery).',
                'Version History Tracking: Complete changelog with feature additions, bug fixes, and version progression.',
                'Data Persistence Engine: Robust SharedPreferences integration ensuring no data loss across app sessions.',
                'Background Processing: Efficient background tasks for data synchronization and automatic backups with export capabilities.',
                'Performance Monitoring: Built-in performance tracking with optimization suggestions and health metrics.',
                'Feature Toggle System: Granular control over feature availability without requiring app updates.',
                'Integration APIs: Extensible architecture supporting future integrations and third-party connectivity.',
              ],
            ),

            _buildFeatureCategory(
              title: 'Server Integrity &\nMonitoring System',
              icon: Icons.security,
              color: Colors.red,
              features: [
                'Advanced Pattern Recognition: AI-powered detection of suspicious clicking patterns with machine learning adaptation over time.',
                'Multi-Dimensional Risk Assessment: 4-tier weighted scoring system analyzing temporal patterns (25%), volume metrics (30%), behavioral patterns (25%), and peer comparisons (20%).',
                'Real-Time Integrity Dashboard: Live monitoring of all servers with risk scores, alerts, and detailed audit trails.',
                'High-Speed Click Analysis: Detailed forensic analysis of rapid clicking instances with individual timestamp tracking and pattern visualization.',
                'Statistical Outlier Detection: Z-score analysis for peer comparison and sophisticated anomaly detection with contextual intelligence.',
                'Click Clustering Detection: Advanced burst analysis identifying mechanical patterns and coefficient of variation calculations.',
                'Session Duration Analysis: Extended activity monitoring with trend analysis and predictive integrity analytics.',
                'Volume Spike Detection: Sudden activity increase identification with historical context and baseline comparisons.',
                'Comprehensive Alert System: Pattern-specific alerts with customizable thresholds and automated notification management.',
                'Audit Server Profiles: Professional integrity assessment reports with detailed analysis and risk factor breakdown.',
                'Expandable Click Details: Forensic-level click analysis showing individual timestamps, intervals, and behavioral patterns.',
                'Server Sorting & Filtering: Advanced dashboard with sorting by name, integrity score, or alert count for efficient monitoring.',
                'Adaptive Intelligence: System becomes more accurate over time, learning individual server patterns and reducing false positives.',
                'Data-Driven Baselines: Personalized integrity profiles that adapt to each server\'s unique operating style and efficiency patterns.',
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
                          'Version: 3.2.0+320',
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.left,
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
