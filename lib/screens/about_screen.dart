import 'package:flutter/material.dart';
import 'version_history_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
            // App Info Card
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
                    const SizedBox(height: 16),
                    Text(
                      'AI-Powered Restaurant Performance Intelligence',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Transform your restaurant operations with advanced analytics, intelligent server performance tracking, and predictive insights that drive measurable results.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
                        'Version 3.6.0+360',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Description Card
            _buildInfoCard(
              title: 'Why RUNNER! Transforms Restaurant Performance',
              icon: Icons.trending_up,
              color: Colors.blue,
              content:
                  'RUNNER! is the only restaurant management system that combines real-time operations tracking with AI-powered performance intelligence. Our advanced analytics don\'t just track what happened—they predict what will happen, identify improvement opportunities, and provide actionable insights that directly impact your bottom line.\n\n• **Increase Revenue**: Optimize server performance with predictive analytics that identify top performers and improvement opportunities\n• **Reduce Labor Costs**: Eliminate guesswork in scheduling with data-driven insights on server efficiency and performance trends\n• **Improve Customer Satisfaction**: Track and analyze Net Promoter Scores (NPS) with 30% weighting in performance calculations\n• **Boost Team Morale**: Gamified performance tracking with 150-level progression system and achievement recognition\n• **Make Data-Driven Decisions**: Access comprehensive analytics, trend analysis, and performance projections that guide strategic decisions\n• **Scale Operations**: Advanced reporting and monitoring tools that grow with your business from single location to multi-unit operations',
            ),

            // Developer Card
            _buildInfoCard(
              title: 'Built by Restaurant Industry Experts',
              icon: Icons.restaurant,
              color: Colors.green,
              content:
                  'RUNNER! was developed by a team with deep restaurant industry experience, combining years of hands-on hospitality management with cutting-edge software development. We understand the unique challenges of restaurant operations—from peak hour rushes to staff scheduling complexities—and have built every feature to solve real-world problems that restaurant managers face daily.',
            ),

            // Features Card
            _buildInfoCard(
              title: 'Advanced Performance Intelligence Features',
              icon: Icons.analytics,
              color: Colors.orange,
              content:
                  '**🧠 AI-Powered Analytics:**\n• Intelligent server performance classification (Elite, Strong, Developing, Concerning, Critical)\n• Advanced trend analysis with velocity tracking and predictive insights\n• Multi-dimensional scoring with contextual intelligence\n• 3-month and 6-month performance projections with confidence levels\n\n**📊 Historical Performance Intelligence:**\n• Comprehensive NPS analytics with trend detection and pattern recognition\n• Data quality classification and confidence level assessment\n• Benchmark comparisons against industry standards\n• Volatility assessment and trend persistence tracking\n\n**⚡ Real-Time Operations Management:**\n• Live shift tracking with automatic transition handling\n• Team competition system with color-coded performance visualization\n• Advanced gamification with 150-level progression system\n• Real-time performance monitoring with alerts and notifications\n\n**🔧 Enterprise-Grade Management:**\n• Comprehensive admin controls and data management\n• Cross-platform compatibility (iOS, Android, Web, Windows, macOS, Linux)\n• Advanced backup and restore capabilities\n• Server integrity monitoring with AI pattern recognition\n• Custom avatars, banners, and personalization options',
            ),

            // Contact Card
            _buildInfoCard(
              title: 'Your Success is Our Priority',
              icon: Icons.support_agent,
              color: Colors.purple,
              content:
                  'RUNNER! is continuously evolving based on real-world restaurant operations and manager feedback. Every feature is designed to solve actual problems you face daily—from optimizing server performance to improving customer satisfaction scores.\n\nYour insights drive our development priorities, ensuring RUNNER! remains the most effective restaurant management tool available. Join thousands of restaurant managers who trust RUNNER! to transform their operations and boost their bottom line.',
            ),

            // Copyright
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Text(
                '© 2025 RUNNER! All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
