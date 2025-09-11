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
              version: "3.2.0+320",
              date: "September 11, 2025",
              status: "Current Version",
              color: Colors.green,
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
                  _buildStatRow('Total Development Time', '~3 weeks intensive development'),
                  _buildStatRow('Total Commits', '320+ commits (build number reflects commit count)'),
                  _buildStatRow('Version Milestones', '4 major versions (Foundation → Team System → Gamification → Enhanced UX)'),
                  _buildStatRow('Visual Assets', '247+ (174 banners + 73 wallpapers + avatars)'),
                  _buildStatRow('Platform Support', '6 platforms (iOS, Android, Web, Windows, macOS, Linux)'),
                  _buildStatRow('Code Evolution', 'From 685 lines to comprehensive enterprise system'),
                  _buildStatRow('Features Added', '20+ documented features across 3 major revisions'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      version,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
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
