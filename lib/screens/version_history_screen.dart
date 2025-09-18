import 'package:flutter/material.dart';

class VersionHistoryScreen extends StatelessWidget {
  const VersionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
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
            _buildVersionCard(
              version: "3.5.0+350",
              date: "September 18, 2025",
              status: "Latest Version",
              color: Colors.green,
              changes: [
                "🎮 MAJOR: Advanced Gamification & Instant Gratification System",
                "✨ Comprehensive Milestone Detection: Real-time achievement tracking with progressive XP scaling for sustained performance",
                "🎯 Enhanced Pizookie Incentives: Increased base XP from 25 to 35 XP and every-2nd-pizookie milestones to promote difficult items",
                "🧠 Psychological XP Rounding: Smart XP values rounded to appealing numbers ending in 0, 1, or 5 for enhanced reward perception",
                "💬 500+ Unique Message Variety System: Dynamic flash messages with anti-repetition engine ensuring fresh motivational content",
                "📊 Net Promoter Score (NPS) Integration: Customer satisfaction tracking with 30% weighting in server performance calculations",
                "📝 Monthly NPS Data Entry: Comprehensive customer feedback collection system with persistent database storage",
                "📈 Server NPS Scorecards: Individual server customer satisfaction reports with month selection and detailed analytics",
                "🌅 Business Day Model: Advanced overnight operations support with accurate shift boundary management for 24/7 restaurants",
                "🔄 Dynamic Transition System: Intelligent business-hours-aware shift transitions with automated roster management",
                "⏰ Live Roster Updates: Real-time preservation of counts and synchronization of working server IDs during transitions",
                "📊 Enhanced Trend Analysis: Comprehensive server performance statements with long-term tracking and improvement indicators",
                "🛡️ Server Integrity Improvements: Refined integrity monitoring with reduced false positives and better pattern recognition",
                "🎨 UI Polish: Enhanced level bubble display width for double-digit levels and improved visual consistency across screens",
                "⚡ Performance Optimization: Faster milestone detection, improved memory usage, and smoother animation transitions",
                "🔧 Technical Infrastructure: Advanced milestone tracking, personality profiling, and message engagement analytics foundation",
              ],
            ),
            _buildVersionCard(
              version: "3.4.0+340",
              date: "September 12, 2025",
              status: "Previous Release",
              color: Colors.blue,
              changes: [
                "📊 MAJOR: Enhanced Bulk Data Entry System with comprehensive date handling and conflict resolution",
                "🎯 Advanced Date Range Processing: Fixed critical bug where user-selected dates were ignored, now respects _selectedStartDate/_selectedEndDate",
                "🔄 Comprehensive Duplicate Prevention: Cancel/Merge/Overwrite options for overlapping date ranges with proactive conflict detection",
                "⚠️ Real-Time Data Conflict Warnings: Proactive UI alerts when users attempt to enter potentially duplicate data",
                "🌟 NPS Integration: Net Promoter Score (NPS) weighted at 30% in server performance calculations for customer satisfaction metrics",
                "🕐 Timestamp-Enhanced Integrity Analysis: Individual click timestamps with detailed interval analysis and pattern recognition",
                "⚡ Enhanced Click Pattern Detection: Advanced burst analysis, mechanical pattern detection, and coefficient of variation calculations",
                "🎮 Boost System Improvements: Live countdown timers, enhanced UI feedback, and improved calculation display logic",
                "🔧 Enhanced Storage Infrastructure: Improved date range utilities, overlap detection, and comprehensive data summary functions",
                "📱 Modernized Birthday Picker: Removed year requirement and optimized layout for better user experience",
                "🎯 Enhanced Shift Click Analysis: Detailed forensic analysis screen with individual click timestamps and performance metrics",
                "🔒 Advanced Admin Security: Enhanced admin access through easter egg system with improved monitoring capabilities",
                "🎨 UI/UX Refinements: Consistent styling improvements, better visual hierarchy, and enhanced accessibility throughout",
                "📈 Release Production Ready: APK optimized for restaurant deployment with 76.1MB release build and 99% font optimization",
                "🛡️ Enterprise-Grade Data Integrity: Comprehensive validation and protection against data corruption or manipulation",
              ],
            ),
            _buildVersionCard(
              version: "3.3.0+330",
              date: "September 12, 2025",
              status: "Archive Enhancement",
              color: Colors.blue,
              changes: [
                "🛡️ MAJOR: Complete Server Integrity & Monitoring System implementation with advanced pattern recognition",
                "🔍 Advanced click analysis with 4-tier weighted risk scoring (Temporal 25%, Volume 30%, Pattern 25%, Peer 20%)",
                "📊 Real-time integrity dashboard with comprehensive server audit profiles",
                "🎯 High-speed click analysis with expandable cards showing individual timestamps and intervals",
                "🤖 AI-powered pattern detection including click clustering, mechanical patterns, and statistical outlier analysis",
                "📈 Z-score peer comparison and volume spike detection with adaptive intelligence",
                "🚨 Sophisticated alert system with pattern-specific notifications and risk factor analysis",
                "💼 Professional 'Audit Server Profile' terminology for enterprise-grade integrity management",
                "🔧 Advanced server dashboard with sorting options (name, integrity score, alerts count)",
                "⚡ Expandable click instance cards with detailed forensic analysis and time difference calculations",
                "🧠 Self-learning system that becomes more intelligent with increased data flow over time",
                "📋 Enhanced server monitoring UI with sorting, filtering, and detailed click analysis capabilities",
                "🎨 Professional audit interface design with consistent styling and accessibility improvements",
                "🔒 Enterprise-grade integrity protection system ready for restaurant deployment",
              ],
            ),
            _buildVersionCard(
              version: "3.2.0+320",
              date: "September 11, 2025",
              status: "Archive Enhancement",
              color: Colors.blue,
              changes: [
                "🗄️ Added comprehensive server archiving/restoration system with dedicated archived servers screen",
                "📁 Enhanced manage servers screen with archive functionality and visual archive indicators",
                "� Added comprehensive backup system with ZIP file creation including all photos and data",
                "�💾 Added backup export functionality enabling file sharing and external storage export",
                "💾 Enhanced backup options: Quick JSON backups and Full ZIP backups with photos",
                "🎨 Enhanced level bubble gradient system with softer, less bold colors for better visual integration",
                "🏆 Added level bubbles to MVP/Leaderboards screen with consistent styling throughout app",
                "📊 Improved leaderboard functionality with comprehensive server performance tracking",
                "🎯 Enhanced visual consistency across all level progression indicators",
                "🔧 Refined gradient color system for better contrast balance with avatars and buttons",
                "✨ Improved theme system with centralized level bubble management",
                "🎪 Enhanced feature discovery system accessibility and documentation",
                "📱 Continued UI/UX refinements for better user experience",
              ],
            ),
            _buildVersionCard(
              version: "3.1.0+310",
              date: "September 9-10, 2025",
              status: "Leaderboard Enhancement",
              color: Colors.blue,
              changes: [
                "🏆 Complete leaderboard system overhaul with enhanced visual design",
                "📊 Advanced server performance analytics with sortable statistics",
                "🎯 Improved level progression visualization throughout the app",
                "🎨 Enhanced avatar and banner integration in leaderboard displays",
                "📈 Better team performance tracking and visualization",
                "⚡ Optimized rendering performance for large server lists",
                "🔧 Fixed various UI inconsistencies and improved responsiveness",
                "✨ Added comprehensive server profile integration with leaderboards",
              ],
            ),
            _buildVersionCard(
              version: "3.0.0+300",
              date: "September 7, 2025",
              status: "Major Feature Milestone",
              color: Colors.purple,
              changes: [
                "✅ Updated comprehensive app features list with 20+ documented features",
                "🔧 Fixed history display issues (correct date format, shift-specific pizookie counts)",
                "🔧 Fixed server sorting by station type priority instead of alphabetical",
                "🔧 Improved available servers scrolling with AlwaysScrollableScrollPhysics",
                "🎯 Enhanced shift end time calculations using proper restaurant hours",
                "📱 Polished UI elements and improved user experience",
                "📊 Added comprehensive version history tracking with detailed changelog",
                "🎯 Matured to version 3.0 reflecting comprehensive feature evolution",
              ],
            ),
            _buildVersionCard(
              version: "2.5.0+250",
              date: "September 5-6, 2025",
              status: "Visual Revolution Complete",
              color: Colors.blue,
              changes: [
                "🎨 Added 174 professional profile banners (800x320px WebP format)",
                "🌄 Implemented wallpaper gallery with 73+ background options",
                "🖼️ Enhanced avatar system with preset gallery and photo upload",
                "🎪 Complete visual overhaul with modern gradients and layouts",
                "🏢 Added station types & sections management system",
                "👤 Improved server customization and profile management",
                "🎭 Dynamic banner system with availability management",
                "⚙️ Enhanced admin interface with modern design and security",
              ],
            ),
            _buildVersionCard(
              version: "2.0.0+200",
              date: "August 27, 2025",
              status: "Gamification Revolution",
              color: Colors.purple,
              changes: [
                "🎮 Complete XP/Leveling system overhaul with new progression table",
                "🍪 Pizookie runs system (25 XP each, long-press to activate)",
                "🏆 Achievement system with visual feedback and badges",
                "🎯 Level progression with visual badges and progress bars",
                "✨ XP flash overlays and achievement notifications",
                "🎪 Feature discovery system (5-tap Easter egg on RUNNER! title)",
                "📊 Enhanced leaderboards with gold/silver/bronze medals",
                "🎨 Improved UI polish with better visual hierarchy",
                "🚀 MAJOR VERSION: Transformed from basic tracker to gamified experience",
              ],
            ),
            _buildVersionCard(
              version: "1.5.0+150",
              date: "August 26, 2025",
              status: "Team Competition Maturity",
              color: Colors.orange,
              changes: [
                "🍪 Added pizookie running features (initially glitchy)",
                "📊 Enhanced popup dialogs with sortable statistics",
                "🎯 Improved roster management and team tracking",
                "🔧 Fixed various UI overflow and layout issues",
                "📱 Better mobile responsiveness and grid layouts",
                "⚡ Performance optimizations for section assignments",
              ],
            ),
            _buildVersionCard(
              version: "1.2.0+120",
              date: "August 25, 2025",
              status: "Team Competition Foundation",
              color: Colors.teal,
              changes: [
                "🏆 Team color system (Blue, Purple, Silver)",
                "📊 Pie chart visualization for team performance",
                "🔄 Roster toggle between lunch/dinner shifts",
                "📈 Team competition logic with rankings and percentages",
                "🎯 Enhanced shift transition handling",
                "🎨 UI improvements for better visual hierarchy",
                "⚙️ Configurable transition times in settings",
                "🚀 MAJOR VERSION: Evolved from individual to team-based system",
              ],
            ),
            _buildVersionCard(
              version: "1.0.0",
              date: "August 24, 2025",
              status: "Foundation Release",
              color: Colors.grey,
              changes: [
                "🏗️ Complete Flutter app structure (Android, iOS, Web, Windows, macOS, Linux)",
                "👆 Core click tracking system with increment/decrement",
                "📋 Basic roster management with server assignments",
                "🕐 Shift system supporting Lunch/Dinner tracking",
                "🔐 PIN-protected admin controls and management",
                "👤 Server profile system with statistics tracking",
                "💾 Data persistence using SharedPreferences",
                "⚙️ Settings and history screens",
                "🏠 Home screen with server grid layout",
                "📱 Professional multi-platform app foundation",
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Development Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Total Development Time', '~3+ weeks intensive development'),
                  _buildStatRow('Total Commits', '330+ commits (build number reflects commit count)'),
                  _buildStatRow('Version Milestones', '5 major versions (Foundation → Team System → Gamification → Enhanced UX → Security Intelligence)'),
                  _buildStatRow('Security Features', 'Enterprise-grade integrity monitoring with AI pattern recognition'),
                  _buildStatRow('Visual Assets', '247+ (174 banners + 73 wallpapers + avatars)'),
                  _buildStatRow('Platform Support', '6 platforms (iOS, Android, Web, Windows, macOS, Linux)'),
                  _buildStatRow('Code Evolution', 'From 685 lines to comprehensive enterprise security system'),
                  _buildStatRow('Features Added', '25+ documented features across 4 major revisions including advanced integrity monitoring'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard({
    required String version,
    required String date,
    required String status,
    required Color color,
    required List<String> changes,
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
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: color,
        collapsedIconColor: color.withOpacity(0.7),
        initiallyExpanded: version.contains("3.4.0"), // Only expand the latest version by default
        title: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      version,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        children: [
          // Changes
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s New:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...changes.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          change,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
