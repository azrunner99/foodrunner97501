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
                      'Comprehensive Restaurant Management System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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
                        'Version 3.5.0+350',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w400,
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
              title: 'About RUNNER!',
              icon: Icons.info_outline,
              color: Colors.blue,
              content: 'RUNNER! is a comprehensive restaurant management system designed to streamline food running operations, track server performance, and enhance team collaboration. Built with modern technology, it offers real-time tracking, gamification features, and detailed analytics to help restaurants optimize their service efficiency.',
            ),

            // Developer Card
            _buildInfoCard(
              title: 'Developer',
              icon: Icons.code,
              color: Colors.green,
              content: 'Developed with passion for the restaurant industry. This app combines years of hospitality experience with modern software development to create a tool that truly understands the fast-paced restaurant environment.',
            ),

            // Features Card
            _buildInfoCard(
              title: 'Key Features',
              icon: Icons.star,
              color: Colors.orange,
              content: '• Real-time shift tracking\n• Team competition system\n• Advanced gamification with 150 levels\n• Comprehensive analytics\n• Custom avatars and personalization\n• Admin controls and data management\n• Cross-platform compatibility',
            ),

            // Contact Card
            _buildInfoCard(
              title: 'Feedback & Support',
              icon: Icons.support_agent,
              color: Colors.purple,
              content: 'We value your feedback! This app is continuously improved based on real-world restaurant usage. Your suggestions help make RUNNER! even better for the entire hospitality community.',
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
